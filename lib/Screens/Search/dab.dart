import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/Services/dab/dab_utils.dart';

class DabTrack {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String albumTitle;
  final String albumId;
  final String albumCover;
  final String genre;

  DabTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.albumTitle,
    required this.albumId,
    required this.albumCover,
    required this.genre,
  });

  factory DabTrack.fromJson(Map<String, dynamic> json) => DabTrack(
        id: json['id'].toString(),
        title: json['title'].toString(),
        artist: json['artist'].toString(),
        artistId: json['artistId'].toString(),
        albumTitle: json['albumTitle'].toString(),
        albumId: json['albumId'].toString(),
        albumCover: json['albumCover'].toString(),
        genre: json['genre'].toString(),
      );
}

class DabAlbum {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String albumCover;
  final String genre;

  DabAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.albumCover,
    required this.genre,
  });

  factory DabAlbum.fromJson(Map<String, dynamic> json) => DabAlbum(
        id: json['id'].toString(),
        title: json['title'].toString(),
        artist: json['artist'].toString(),
        artistId: json['artistId'].toString(),
        albumCover: json['cover'].toString(),
        genre: json['genre'].toString(),
      );
}

// ignore: avoid_classes_with_only_static_members
class DabService {
  static final _logger = Logger('DabService');

  static Future<List<DabAlbum>> fetchArtistAlbums(String artistId) async {
    try {
      _logger.info('Fetching albums for artist: $artistId');
      final response = await http.get(
          Uri.parse('https://dab.yeet.su/api/discography?artistId=$artistId'));

      if (response.statusCode != 200) {
        _logger.severe(
            'Failed to fetch artist albums. Status: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final albums = data['albums'] as List;
      final result = albums
          .map((album) => DabAlbum.fromJson(album as Map<String, dynamic>))
          .toList();
      _logger.info('Successfully fetched ${result.length} albums');
      return result;
    } catch (e) {
      _logger.severe('Error fetching artist albums: $e');
      return [];
    }
  }

  static Future<List<DabTrack>> fetchAlbumTracks(String albumId) async {
    try {
      _logger.info('Fetching tracks for album: $albumId');
      final response = await http
          .get(Uri.parse('https://dab.yeet.su/api/album?albumId=$albumId'));

      if (response.statusCode != 200) {
        _logger.severe(
            'Failed to fetch album tracks. Status: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final tracks = data['album']['tracks'] as List;
      final result = tracks
          .map((track) => DabTrack.fromJson(track as Map<String, dynamic>))
          .toList();
      _logger.info('Successfully fetched ${result.length} tracks');
      return result;
    } catch (e) {
      _logger.severe('Error fetching album tracks: $e');
      return [];
    }
  }
}

class TrackTile extends StatelessWidget {
  final DabTrack track;
  final bool showMenu;

  const TrackTile({super.key, required this.track, this.showMenu = true});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildCover(),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${track.artist} • ${track.albumTitle}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _download(context),
          ),
          if (showMenu) _buildMenu(context),
        ],
      ),
    );
  }

  Widget _buildCover() => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.albumCover,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.music_note, size: 50, color: Colors.grey),
        ),
      );

  Widget _buildMenu(BuildContext context) => PopupMenuButton<String>(
        onSelected: (value) => _navigate(context, value),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'artist', child: Text('Go to Artist')),
          PopupMenuItem(value: 'album', child: Text('Go to Album')),
        ],
      );

  void _navigate(BuildContext context, String type) {
    final page = type == 'artist'
        ? DABArtistPage(artistId: track.artistId, artistName: track.artist)
        : DABAlbumPage(
            albumId: track.albumId,
            albumTitle: track.albumTitle,
            artist: track.artist,
            albumCover: track.albumCover,
          );
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _download(BuildContext context) async {
    try {
      Logger.root.info('Starting download for track: ${track.title}');
      await dabDL(track);
      if (context.mounted) {
        ShowSnackBar().showSnackBar(context, 'Download complete.');
        Logger.root.info('Download completed successfully for: ${track.title}');
      }
    } catch (e) {
      Logger.root.severe('Download failed for ${track.title}: $e');
      if (context.mounted) {
        ShowSnackBar().showSnackBar(context, 'Download failed.');
      }
    }
  }
}

class AlbumTile extends StatelessWidget {
  final DabAlbum album;
  final VoidCallback? onTap;

  const AlbumTile({super.key, required this.album, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          album.albumCover,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.album, size: 50, color: Colors.grey),
        ),
      ),
      title: Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(album.artist),
      onTap: onTap,
    );
  }
}

class DABSearchPage extends StatelessWidget {
  final List<dynamic> trackList;

  const DABSearchPage({super.key, required this.trackList});

  @override
  Widget build(BuildContext context) {
    final tracks = trackList
        .map((item) => DabTrack.fromJson(item as Map<String, dynamic>))
        .toList();
    Logger.root.info('DABSearchPage loaded with ${tracks.length} tracks');

    return Scaffold(
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) => TrackTile(track: tracks[index]),
      ),
    );
  }
}

class DABArtistPage extends StatefulWidget {
  final String artistId;
  final String artistName;

  const DABArtistPage(
      {super.key, required this.artistId, required this.artistName});

  @override
  State<DABArtistPage> createState() => _DABArtistPageState();
}

class _DABArtistPageState extends State<DABArtistPage> {
  List<DabAlbum> albums = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    Logger.root.info('Loading albums for artist: ${widget.artistName}');
    final data = await DabService.fetchArtistAlbums(widget.artistId);
    setState(() {
      albums = data;
      isLoading = false;
    });
    Logger.root.info('Artist page loaded with ${albums.length} albums');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artistName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return AlbumTile(
                  album: album,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DABAlbumPage(
                        albumId: album.id,
                        albumTitle: album.title,
                        artist: album.artist,
                        albumCover: album.albumCover,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class DABAlbumPage extends StatefulWidget {
  final String albumId;
  final String albumTitle;
  final String artist;
  final String albumCover;

  const DABAlbumPage({
    super.key,
    required this.albumId,
    required this.albumTitle,
    required this.artist,
    required this.albumCover,
  });

  @override
  State<DABAlbumPage> createState() => _DABAlbumPageState();
}

class _DABAlbumPageState extends State<DABAlbumPage> {
  List<DabTrack> tracks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    Logger.root.info('Loading tracks for album: ${widget.albumTitle}');
    final data = await DabService.fetchAlbumTracks(widget.albumId);
    setState(() {
      tracks = data;
      isLoading = false;
    });
    Logger.root.info('Album page loaded with ${tracks.length} tracks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.albumTitle, style: const TextStyle(fontSize: 16)),
            Text(widget.artist,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) =>
                  TrackTile(track: tracks[index], showMenu: false),
            ),
    );
  }
}
