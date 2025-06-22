import 'dart:convert';
import 'package:http/http.dart' as http;

String toLrcTimestamp(int milliseconds) {
  final minutes = (milliseconds / 60000).floor();
  final seconds = ((milliseconds % 60000) / 1000).floor();
  final ms = ((milliseconds % 1000) / 10).floor();
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
}

String formatSyllableLyrics(List<dynamic> lines, bool multiPersonWordByWord) {
  final syncedLyrics = StringBuffer();

  for (final line in lines) {
    final timestamp = line['timestamp'] as int;
    syncedLyrics.write('[${toLrcTimestamp(timestamp)}]');

    if (multiPersonWordByWord) {
      syncedLyrics.write(line['oppositeTurn'] == true ? 'v2:' : 'v1:');
    }
    for (final syllable in line['text'] as List<dynamic>) {
      final beginTs = '<${toLrcTimestamp(syllable['timestamp'] as int)}>';
      final endTs = '<${toLrcTimestamp(syllable['endtime'] as int)}>';

      if (!syncedLyrics.toString().endsWith(beginTs)) {
        syncedLyrics.write(beginTs);
      }
      syncedLyrics.write(syllable['text']);
      if (syllable['part'] != true) {
        syncedLyrics.write(' ');
      }
      syncedLyrics.write(endTs);
    }

    if (line['background'] == true && multiPersonWordByWord) {
      syncedLyrics.write('\n[bg:');
      for (final syllable in line['backgroundText'] as List<dynamic>) {
        final beginTs = '<${toLrcTimestamp(syllable['timestamp'] as int)}>';
        final endTs = '<${toLrcTimestamp(syllable['endtime'] as int)}>';

        if (!syncedLyrics.toString().endsWith(beginTs)) {
          syncedLyrics.write(beginTs);
        }
        syncedLyrics.write(syllable['text']);
        if (syllable['part'] != true) {
          syncedLyrics.write(' ');
        }
        syncedLyrics.write(endTs);
      }
      syncedLyrics.write(']');
    }
    syncedLyrics.write('\n');
  }

  return syncedLyrics.toString().trimRight();
}

String formatLineLyrics(List<dynamic> lines) {
  final syncedLyrics = StringBuffer();

  for (final line in lines) {
    final timestamp = line['timestamp'] as int;
    final text = (line['text'] as List<dynamic>)[0]['text'];
    syncedLyrics.write('[${toLrcTimestamp(timestamp)}]$text\n');
  }

  return syncedLyrics.toString().trimRight();
}

String formatLyrics(String apiResponse) {
  try {
    final data = json.decode(apiResponse) as Map<String, dynamic>;
    final lines = data['content'] as List<dynamic>;
    final type = data['type'] as String;

    if (type == 'Syllable') {
      return formatSyllableLyrics(lines, false);
    } else if (type == 'Line') {
      return formatLineLyrics(lines);
    }

    return apiResponse;
  } catch (e) {
    try {
      final data = json.decode(apiResponse) as List<dynamic>;
      return formatSyllableLyrics(data, false);
    } catch (e) {
      return apiResponse;
    }
  }
}

Future<String?> getAppleLyrics(String query) async {
  if (query.isEmpty) return null;

  const baseURL = 'https://paxsenix.alwaysdata.net/';
  final client = http.Client();

  try {
    final search = Uri.encodeComponent(query);
    final searchResponse = await client.get(
      Uri.parse('${baseURL}searchAppleMusic.php?q=$search'),
    );

    if (searchResponse.statusCode < 200 || searchResponse.statusCode >= 300) {
      return null;
    }

    final decoded =
        json.decode(utf8.decode(searchResponse.bodyBytes)) as List<dynamic>;
    if (decoded.isEmpty) return null;

    final appleID = decoded[0]['id'] as String;

    final lyricsResponse = await client.get(
      Uri.parse('${baseURL}getAppleMusicLyrics.php?id=$appleID'),
    );

    if (lyricsResponse.statusCode < 200 ||
        lyricsResponse.statusCode >= 300 ||
        lyricsResponse.body.isEmpty) {
      return null;
    }

    final rawLyrics = utf8.decode(lyricsResponse.bodyBytes);
    return formatLyrics(rawLyrics);
  } catch (e) {
    return null;
  } finally {
    client.close();
  }
}
