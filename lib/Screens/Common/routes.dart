/*
 *  This file is part of BlackHole (https://github.com/atinba/Singularity).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:flutter/material.dart';
import 'package:singularity/Screens/Home/home.dart';
import 'package:singularity/Screens/Library/downloads.dart';
import 'package:singularity/Screens/Library/nowplaying.dart';
import 'package:singularity/Screens/Library/playlists.dart';
import 'package:singularity/Screens/Library/recent.dart';
import 'package:singularity/Screens/Library/stats.dart';
import 'package:singularity/Screens/Settings/new_settings_page.dart';

Widget initialFuntion() {
  return HomePage();
}

final Map<String, Widget Function(BuildContext)> namedRoutes = {
  '/': (context) => initialFuntion(),
  '/setting': (context) => const NewSettingsPage(),
  '/playlists': (context) => PlaylistScreen(),
  '/nowplaying': (context) => NowPlaying(),
  '/recent': (context) => RecentlyPlayed(),
  '/downloads': (context) => const Downloads(),
  '/stats': (context) => const Stats(),
};
