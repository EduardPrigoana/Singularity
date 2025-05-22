import 'package:flutter/material.dart';
import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/Services/dab/dab_utils.dart';

class DabTrack {
  final String id;
  final String title;
  final String artist;
  final String albumTitle;
  final String albumCover;
  final DateTime releaseDate;
  final String genre;
  final int durationSeconds;

  DabTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumTitle,
    required this.albumCover,
    required this.releaseDate,
    required this.genre,
    required this.durationSeconds,
  });

  factory DabTrack.fromJson(Map<String, dynamic> json) {
    return DabTrack(
      id: json['id'].toString(),
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumTitle: json['albumTitle'] as String,
      albumCover: json['albumCover'] as String,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      genre: json['genre'] as String,
      durationSeconds: json['duration'] as int,
    );
  }
}

class DABSearchPage extends StatelessWidget {
  final List<dynamic> trackList;

  const DABSearchPage({
    super.key,
    required this.trackList,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = trackList
        .map((item) => DabTrack.fromJson(item as Map<String, dynamic>))
        .toList();

    return Scaffold(
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];

          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                track.albumCover,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.music_note,
                  size: 50,
                  color: Colors.grey[400],
                ),
              ),
            ),
            title: Text(track.title),
            subtitle: Text('${track.artist} • ${track.albumTitle}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download_sharp),
                  onPressed: () async {
                    await dabDL(track);

                    ShowSnackBar().showSnackBar(
                      context,
                      'Download complete.',
                    );
                  },
                ),
              ],
            ),
            onTap: () {
            },
          );
        },
      ),
    );
  }
}
