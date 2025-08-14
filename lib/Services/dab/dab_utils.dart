import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:singularity/Screens/Search/dab.dart';
import 'package:singularity/Services/dl/dl_utils.dart';

Future<Map<String, dynamic>> dabSearch(
  String query, {
  int offset = 0,
  String type = 'track',
}) async {
  final uri = Uri.https('dab.yeet.su', '/api/search', {
    'q': query,
    'offset': '$offset',
    'type': type,
  });
  final res = await http.get(uri);
  if (res.statusCode != 200) throw Exception('Status ${res.statusCode}');
  return json.decode(res.body) as Map<String, dynamic>;
}

Future<List<int>> dabDownload(String trackId) async {
  try {
    final res = await http
        .get(Uri.parse('https://dab.yeet.su/api/stream?trackId=$trackId'));
    if (res.statusCode != 200) throw Exception('Failed to get stream URL');

    final url = json.decode(res.body)['url'];
    final songRes = await http.get(Uri.parse(url.toString()));
    if (songRes.statusCode != 200) throw Exception('Failed to download song');

    return songRes.bodyBytes;
  } catch (e) {
    rethrow;
  }
}

Future<void> dabDL(DabTrack track) async {
  String dlPath =
      Hive.box('settings').get('downloadPath', defaultValue: '') as String;
  Logger.root.info('Cached Download path: $dlPath');

  if (dlPath == '') {
    Logger.root.info(
      'Cached Download path is empty, using /storage/emulated/0/Music',
    );
    dlPath = '/storage/emulated/0/Music';
    if (Platform.isLinux) {
      Logger.root.info('Setting Linux DL PATH.');
      final xdgMusicDir = Platform.environment['XDG_MUSIC_DIR']!;
      dlPath = '$xdgMusicDir/singularity';
    }
  }

  final bytes = await dabDownload(track.id);

  Logger.root.info('Download complete, modifying file');
  final filepath = '$dlPath/${track.artist} - ${track.title}.flac';
  final file = File(filepath);
  await file.writeAsBytes(bytes);

  final data = dataFromDabTrack(track);

  final coverBytes = (await http.get(Uri.parse(track.albumCover))).bodyBytes;
  data['lyrics'] = await getLyrics(data);
  writeTags(filepath, data, coverBytes);

  Logger.root.info('Everything Done!');
}

Map<String, dynamic> dataFromDabTrack(DabTrack track) {
  return {
    'title': track.title,
    'artist': track.artist,
    'album_artist': track.artist, // You can customize this if needed
    'album': track.albumTitle,
    // 'year': track.releaseDate.year.toString(),
    // 'lyrics': '', // Placeholder, add actual lyrics if available
    // 'trackNumber': '1', // Placeholder, adjust if you have this info
    // 'trackTotal': '1',  // Placeholder
    // 'discNumber': '1',  // Placeholder
    // 'discTotal': '1',   // Placeholder
    // 'duration': track.durationSeconds.toString(),
    // 'genre': track.genre, // Uncomment and use if needed
  };
}
