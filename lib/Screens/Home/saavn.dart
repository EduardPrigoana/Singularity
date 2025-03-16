import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:singularity/CustomWidgets/collage.dart';
import 'package:singularity/CustomWidgets/horizontal_albumlist.dart';
import 'package:singularity/CustomWidgets/horizontal_albumlist_separated.dart';
import 'package:singularity/CustomWidgets/on_hover.dart';
import 'package:singularity/Helpers/extensions.dart';
import 'package:singularity/Screens/Library/liked.dart';
import 'package:singularity/Screens/Search/artists.dart';
import 'package:singularity/Services/player_service.dart';

bool fetched = false;
List lists = ['recent', 'playlist'];

class SaavnHomePage extends StatefulWidget {
  @override
  _SaavnHomePageState createState() => _SaavnHomePageState();
}

class _SaavnHomePageState extends State<SaavnHomePage>
    with AutomaticKeepAliveClientMixin<SaavnHomePage> {
  List recentList =
      Hive.box('cache').get('recentSongs', defaultValue: []) as List;
  Map likedArtists =
      Hive.box('settings').get('likedArtists', defaultValue: {}) as Map;
  List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() as List? ??
          ['Favorite Songs'];
  Map playlistDetails =
      Hive.box('settings').get('playlistDetails', defaultValue: {}) as Map;
  int recentIndex = 0;
  int playlistIndex = 1;

  String getSubTitle(Map item) {
    final type = item['type'];
    switch (type) {
      case 'charts':
        return '';
      case 'radio_station':
        return 'Radio • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle']?.toString().unescape()}';
      case 'playlist':
        return 'Playlist • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'song':
        return 'Single • ${item['artist']?.toString().unescape()}';
      case 'mix':
        return 'Mix • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'show':
        return 'Podcast • ${(item['subtitle']?.toString() ?? '').isEmpty ? 'JioSaavn' : item['subtitle'].toString().unescape()}';
      case 'album':
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        if (artists != null) {
          return 'Album • ${artists?.join(', ')?.toString().unescape()}';
        } else if (item['subtitle'] != null && item['subtitle'] != '') {
          return 'Album • ${item['subtitle']?.toString().unescape()}';
        }
        return 'Album';
      default:
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        return artists?.join(', ')?.toString().unescape() ?? '';
    }
  }

  int likedCount() {
    return Hive.box('Favorite Songs').length;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double boxSize =
        MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width
            ? MediaQuery.sizeOf(context).width / 2
            : MediaQuery.sizeOf(context).height / 2.5;
    if (boxSize > 250) boxSize = 250;
    if (playlistNames.length >= 3) {
      recentIndex = 0;
      playlistIndex = 1;
    } else {
      recentIndex = 1;
      playlistIndex = 0;
    }
    return (recentList.isEmpty)
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            itemCount: 2,
            itemBuilder: (context, idx) {
              if (idx == recentIndex) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box('settings').listenable(),
                  child: Column(
                    children: [
                      GestureDetector(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                              child: Text(
                                AppLocalizations.of(context)!.lastSession,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/recent');
                        },
                      ),
                      HorizontalAlbumsListSeparated(
                        songsList: recentList,
                        onTap: (int idx) {
                          PlayerInvoke.init(
                            songsList: [recentList[idx]],
                            index: 0,
                            isOffline: false,
                          );
                        },
                      ),
                    ],
                  ),
                  builder: (BuildContext context, Box box, Widget? child) {
                    return (recentList.isEmpty ||
                            !(box.get('showRecent', defaultValue: true)
                                as bool))
                        ? const SizedBox()
                        : child!;
                  },
                );
              }
              if (idx == playlistIndex &&
                  playlistNames.isNotEmpty &&
                  playlistDetails.isNotEmpty) {
                return ValueListenableBuilder(
                  valueListenable: Hive.box('settings').listenable(),
                  child: Column(
                    children: [
                      GestureDetector(
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                              child: Text(
                                AppLocalizations.of(context)!.yourPlaylists,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/playlists');
                        },
                      ),
                      SizedBox(
                        height: boxSize + 15,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: playlistNames.length,
                          itemBuilder: (context, index) {
                            final String name = playlistNames[index].toString();
                            final String showName = playlistDetails
                                    .containsKey(name)
                                ? playlistDetails[name]['name']?.toString() ??
                                    name
                                : name;
                            final String? subtitle = playlistDetails[name] ==
                                        null ||
                                    playlistDetails[name]['count'] == null ||
                                    playlistDetails[name]['count'] == 0
                                ? null
                                : '${playlistDetails[name]['count']} ${AppLocalizations.of(context)!.songs}';
                            if (playlistDetails[name] == null ||
                                playlistDetails[name]['count'] == null ||
                                playlistDetails[name]['count'] == 0) {
                              return const SizedBox();
                            }
                            return GestureDetector(
                              child: SizedBox(
                                width: boxSize - 20,
                                child: HoverBox(
                                  child: Collage(
                                    borderRadius: 10.0,
                                    imageList: playlistDetails[name]
                                        ['imagesList'] as List,
                                    showGrid: true,
                                    placeholderImage: 'assets/cover.jpg',
                                  ),
                                  builder: ({
                                    required BuildContext context,
                                    required bool isHover,
                                    Widget? child,
                                  }) {
                                    return Card(
                                      color:
                                          isHover ? null : Colors.transparent,
                                      elevation: 0,
                                      margin: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        children: [
                                          SizedBox.square(
                                            dimension: isHover
                                                ? boxSize - 25
                                                : boxSize - 30,
                                            child: child,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  showName,
                                                  textAlign: TextAlign.center,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (subtitle != null &&
                                                    subtitle.isNotEmpty)
                                                  Text(
                                                    subtitle,
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .color,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              onTap: () async {
                                await Hive.openBox(name);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LikedSongs(
                                      playlistName: name,
                                      showName:
                                          playlistDetails.containsKey(name)
                                              ? playlistDetails[name]['name']
                                                      ?.toString() ??
                                                  name
                                              : name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  builder: (BuildContext context, Box box, Widget? child) {
                    return (playlistNames.isEmpty ||
                            !(box.get('showPlaylist', defaultValue: true)
                                as bool) ||
                            (playlistNames.length == 1 &&
                                playlistNames.first == 'Favorite Songs' &&
                                likedCount() == 0))
                        ? const SizedBox()
                        : child!;
                  },
                );
              }
              if (lists[idx] == 'likedArtists') {
                final List likedArtistsList = likedArtists.values.toList();
                return likedArtists.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  'Liked Artists',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumsList(
                            songsList: likedArtistsList,
                            onTap: (int idx) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => ArtistSearchPage(
                                    data: likedArtistsList[idx] as Map,
                                    artistId:
                                        likedArtistsList[idx]['id'].toString(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
              }
              return null;
              // return null;
            },
          );
  }
}
