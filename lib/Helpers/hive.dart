import 'dart:io';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

const hiveBoxes = [
  {'name': 'settings', 'limit': false},
  {'name': 'downloads', 'limit': false},
  {'name': 'stats', 'limit': false},
  {'name': 'Favorite Songs', 'limit': false},
  {'name': 'cache', 'limit': true},
  {'name': 'ytlinkcache', 'limit': true},
];


Future<String> getHiveDirectory() async {
  return '${(await getApplicationSupportDirectory()).path}/Database';
}


Future<void> hiveInit() async {
  final String hiveDir = await getHiveDirectory();

  Hive.init(hiveDir);

  for (final box in hiveBoxes) {
    final boxName = box['name'].toString();
    final limit = box['limit'] as bool? ?? false;

    await Hive.openBox(boxName).onError((error, stackTrace) async {
      Logger.root.severe('Failed to open $boxName Box', error, stackTrace);

      await File('$hiveDir/$boxName.hive').delete();
      await File('$hiveDir/$boxName.lock').delete();

      await Hive.openBox(boxName);
      throw 'Failed to open $boxName Box\nError: $error';
    });

    // clear box if it grows large
    if (limit && box.length > 500) {
      box.clear();
    }
  }
}