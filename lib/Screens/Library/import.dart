import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:singularity/CustomWidgets/gradient_containers.dart';
import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/CustomWidgets/textinput_dialog.dart';
import 'package:singularity/Helpers/import_export_playlist.dart';
import 'package:singularity/Helpers/playlist.dart';
import 'package:singularity/Helpers/search_add_playlist.dart';
import 'package:singularity/localization/app_localizations.dart';

class ImportPlaylist extends StatelessWidget {
  ImportPlaylist({super.key});

  final Box settingsBox = Hive.box('settings');
  final List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() as List? ??
          ['Favorite Songs'];

  void _triggerImport({required String type, required BuildContext context}) {
    switch (type) {
      case 'file':
        importFile(
          context,
          playlistNames,
          settingsBox,
        );
      case 'youtube':
        importYt(
          context,
          playlistNames,
          settingsBox,
        );
      case 'jiosaavn':
        importJioSaavn(
          context,
          playlistNames,
          settingsBox,
        );
      case 'resso':
        importResso(
          context,
          playlistNames,
          settingsBox,
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.importPlaylist,
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.transparent
              : Theme.of(context).colorScheme.secondary,
          elevation: 0,
        ),
        body: ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: 5,
          itemBuilder: (cntxt, index) {
            return ListTile(
              title: Text(
                [
                  AppLocalizations.of(context)!.importFile,
                  AppLocalizations.of(context)!.importYt,
                  AppLocalizations.of(context)!.importJioSaavn,
                  AppLocalizations.of(context)!.importResso,
                ][index],
              ),
              leading: SizedBox.square(
                dimension: 50,
                child: Center(
                  child: Icon(
                    [
                      MdiIcons.import,
                      MdiIcons.youtube,
                      Icons.music_note_rounded,
                      Icons.music_note_rounded,
                    ][index],
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
              onTap: () {
                _triggerImport(
                  type: [
                    'file',
                    'youtube',
                    'jiosaavn',
                    'resso',
                  ][index],
                  context: context,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

Future<void> importFile(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  await importFilePlaylist(context, playlistNames);
}

Future<void> importYt(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  showTextInputDialog(
    context: context,
    title: AppLocalizations.of(context)!.enterPlaylistLink,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      final String link = value.trim();
      Navigator.pop(context);
      final Map data = await SearchAddPlaylist.addYtPlaylist(link);
      if (data.isNotEmpty) {
        if (data['songs'] == null || data['songs'].length == 0) {
          Logger.root.severe(
            'Failed to import YT playlist. Data not empty but title or the count is empty.',
          );
          ShowSnackBar().showSnackBar(
            context,
            '${AppLocalizations.of(context)!.failedImport}\n${AppLocalizations.of(context)!.confirmViewable}',
            duration: const Duration(seconds: 3),
          );
        } else {
          await addPlaylist(data['name'].toString(), data['songs'] as List);

          // await SearchAddPlaylist.showProgress(
          //   (data['songs'] as List).length,
          //   context,
          //   SearchAddPlaylist.ytSongsAdder(
          //     data['name'].toString(),
          //     data['songs'] as List,
          //   ),
          // );
        }
      } else {
        Logger.root.severe(
          'Failed to import YT playlist. Data is empty.',
        );
        ShowSnackBar().showSnackBar(
          context,
          AppLocalizations.of(context)!.failedImport,
        );
      }
    },
  );
}

Future<void> importResso(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  showTextInputDialog(
    context: context,
    title: AppLocalizations.of(context)!.enterPlaylistLink,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      final String link = value.trim();
      Navigator.pop(context);
      final Map data = await SearchAddPlaylist.addRessoPlaylist(link);
      if (data.isNotEmpty) {
        String playName = data['title'].toString();
        while (playlistNames.contains(playName) ||
            await Hive.boxExists(playName)) {
          // ignore: use_string_buffers
          playName = '$playName (1)';
        }
        playlistNames.add(playName);
        settingsBox.put(
          'playlistNames',
          playlistNames,
        );

        await SearchAddPlaylist.showProgress(
          data['count'] as int,
          context,
          SearchAddPlaylist.ressoSongsAdder(
            playName,
            data['tracks'] as List,
          ),
        );
      } else {
        Logger.root.severe(
          'Failed to import Resso playlist. Data is empty.',
        );
        ShowSnackBar().showSnackBar(
          context,
          AppLocalizations.of(context)!.failedImport,
        );
      }
    },
  );
}

Future<void> importJioSaavn(
  BuildContext context,
  List playlistNames,
  Box settingsBox,
) async {
  showTextInputDialog(
    context: context,
    title: AppLocalizations.of(context)!.enterPlaylistLink,
    initialText: '',
    keyboardType: TextInputType.url,
    onSubmitted: (String value, BuildContext context) async {
      final String link = value.trim();
      Navigator.pop(context);
      final Map data = await SearchAddPlaylist.addJioSaavnPlaylist(
        link,
      );

      if (data.isNotEmpty) {
        final String playName = data['title'].toString();
        await addPlaylist(playName, data['tracks'] as List);
        playlistNames.add(playName);
      } else {
        Logger.root.severe('Failed to import JioSaavn playlist. data is empty');
        ShowSnackBar().showSnackBar(
          context,
          AppLocalizations.of(context)!.failedImport,
        );
      }
    },
  );
}
