import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:singularity/Helpers/lyrics.dart';

Future<String> getYtThumbnailUrl(Map data) async {
  Logger.root.info('Getting yt thumbnail url');
  final videoId = data['id'].toString();
  // final maxResUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  final highResUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  // try {
  //   final client = HttpClient();
  //   final req = await client.getUrl(Uri.parse(maxResUrl));
  //   final res = await req.close();
  //   client.close();
  //   return res.statusCode == 200 ? maxResUrl : highResUrl;
  // } catch (_) {
  //   return highResUrl;
  // }
  return highResUrl;
}

bool isYouTubeMedia(Map data) {
  String s(String? key) => data[key]?.toString().toLowerCase() ?? '';
  return [
    () => s('url').contains('google'),
    () => s('perma_url').contains('youtube'),
    () => s('genre') == 'youtube',
    () => s('language') == 'youtube',
    () => s('image').contains('google'),
  ].any((check) => check());
}

Future<Uint8List> getCover(Map data, String filepath) async {
  Logger.root.info('Downloading cover');
  if (isYouTubeMedia(data)) {
    data['image'] = await getYtThumbnailUrl(data);
  }

  final client = HttpClient();
  final HttpClientRequest req =
      await client.getUrl(Uri.parse(data['image'].toString()));
  final HttpClientResponse res = await req.close();

  final coverBytes = await consolidateHttpClientResponseBytes(res);

  final File file = File(filepath);
  file.writeAsBytesSync(coverBytes);

  client.close();
  return coverBytes;
}

Future<void> writeTags(String filepath, Map data, Uint8List bytes) async {
  Logger.root.info('Writing audio tags');
  try {
    final Tag tag = Tag(
      title: data['title'].toString(),
      trackArtist: data['artist'].toString(),
      albumArtist: data['album_artist']?.toString() ??
          data['artist']?.toString().split(', ')[0] ??
          '',
      album: data['album'].toString(),
      year: int.tryParse(data['year'].toString()),
      lyrics: data['lyrics'].toString(),
      trackNumber: int.tryParse(data['trackNumber'].toString()),
      trackTotal: int.tryParse(data['trackTotal'].toString()),
      discNumber: int.tryParse(data['discNumber'].toString()),
      discTotal: int.tryParse(data['discTotal'].toString()),
      duration: int.tryParse(data['duration'].toString()),
      // genre: ,
      pictures: [
        Picture(
          bytes: bytes,
          mimeType: MimeType.jpeg,
          pictureType: PictureType.other,
        ),
      ],
    );

    await AudioTags.write(filepath, tag);
  } catch (e) {
    Logger.root.severe('Error writing tags: $e');
  }
}

Future<String> getLyrics(Map data) async {
  Logger.root.info('Downloading lyrics');
  try {
    final Map res = await Lyrics.getLyrics(
      id: data['id'].toString(),
      title: data['title'].toString(),
      artist: data['artist']?.toString() ?? '',
      album: data['album']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '180',
      saavnHas: data['has_lyrics'] == 'true',
    );
    return res['lyrics'].toString();
  } catch (e) {
    Logger.root.severe('Error fetching lyrics: $e');
    return '';
  }
}

void saveSongDataInDB(Map data, String filepath, String coverPath) {
  Logger.root.info('Putting data to downloads database');
  final songData = {
    'id': data['id'].toString(),
    'title': data['title'].toString(),
    'subtitle': data['subtitle'].toString(),
    'artist': data['artist'].toString(),
    'albumArtist': data['album_artist']?.toString() ??
        data['artist']?.toString().split(', ')[0],
    'album': data['album'].toString(),
    'genre': data['genre'].toString(),
    'year': data['year'].toString(),
    'lyrics': data['lyrics'].toString(),
    'duration': data['duration'],
    'release_date': data['release_date'].toString(),
    'album_id': data['album_id'].toString(),
    'perma_url': data['perma_url'].toString(),
    'quality': '320 kbps',
    'path': filepath,
    'image': coverPath,
    'image_url': data['image'].toString(),
    'from_yt': data['language'].toString() == 'YouTube',
    'dateAdded': DateTime.now().toString(),
  };
  Hive.box('downloads').put(songData['id'].toString(), songData);
}

String cleanTitle(String title) {
  // This regex matches (Remastered), (Remastered 2011), (Remastered - 2011), etc.
  final regex = RegExp(
    r'\s*\(remaster(ed)?(?:\s*[-–]?\s*\d{4})?\)',
    caseSensitive: false,
  );
  return title.replaceAll(regex, '').trim();
}
