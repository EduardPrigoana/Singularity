import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:singularity/Helpers/config.dart';
import 'package:singularity/Helpers/logging.dart';
import 'package:singularity/Helpers/route_handler.dart';
import 'package:singularity/Screens/Common/routes.dart';
import 'package:singularity/Screens/Player/audioplayer.dart';
import 'package:singularity/constants/constants.dart';
import 'package:singularity/constants/languagecodes.dart';
import 'package:singularity/localization/app_localizations.dart';
import 'package:singularity/providers/audio_service_provider.dart';
import 'package:singularity/src/rust/frb_generated.dart';
import 'package:singularity/theme/app_theme.dart';
import 'package:sizer/sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  await hiveInit();
  await startService();

  runApp(MyApp());
}

Future<void> hiveInit() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final home = Platform.environment['HOME']!;
    Hive.init('$home/.local/share/Singularity/Database');
  } else if (Platform.isIOS) {
    await Hive.initFlutter('Database');
  } else {
    await Hive.initFlutter();
  }
  for (final box in hiveBoxes) {
    await openHiveBox(
      box['name'].toString(),
      limit: box['limit'] as bool? ?? false,
    );
  }
}

Future<void> startService() async {
  await initializeLogging();
  final audioHandlerHelper = AudioHandlerHelper();
  final AudioPlayerHandler audioHandler =
      await audioHandlerHelper.getAudioHandler();
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);
  GetIt.I.registerSingleton<MyTheme>(MyTheme());
}

Future<void> openHiveBox(String boxName, {bool limit = false}) async {
  final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
    Logger.root.severe('Failed to open $boxName Box', error, stackTrace);
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dirPath = dir.path;
    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbFile = File('$dirPath/Singularity/$boxName.hive');
      lockFile = File('$dirPath/Singularity/$boxName.lock');
    }
    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox(boxName);
    throw 'Failed to open $boxName Box\nError: $error';
  });
  // clear box if it grows large
  if (limit && box.length > 500) {
    box.clear();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  // ignore: unreachable_from_main
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');
  late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final String systemLangCode = Platform.localeName.substring(0, 2);
    final String? lang = Hive.box('settings').get('lang') as String?;
    if (lang == null &&
        LanguageCodes.languageCodes.values.contains(systemLangCode)) {
      _locale = Locale(systemLangCode);
    } else {
      _locale = Locale(LanguageCodes.languageCodes[lang ?? 'English'] ?? 'en');
    }

    AppTheme.currentTheme.addListener(() {
      setState(() {});
    });
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.themeMode == ThemeMode.system
            ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                ? Brightness.light
                : Brightness.dark
            : AppTheme.themeMode == ThemeMode.dark
                ? Brightness.light
                : Brightness.dark,
        systemNavigationBarIconBrightness:
            AppTheme.themeMode == ThemeMode.system
                ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark
                : AppTheme.themeMode == ThemeMode.dark
                    ? Brightness.light
                    : Brightness.dark,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OrientationBuilder(
            builder: (context, orientation) {
              SizerUtil.setScreenSize(constraints, orientation);
              return MaterialApp(
                title: 'Singularity',
                restorationScopeId: 'singularity',
                debugShowCheckedModeBanner: false,
                themeMode: AppTheme.themeMode,
                theme: AppTheme.lightTheme(
                  context: context,
                ),
                darkTheme: AppTheme.darkTheme(
                  context: context,
                ),
                locale: _locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LanguageCodes.languageCodes.entries
                    .map((languageCode) => Locale(languageCode.value, ''))
                    .toList(),
                routes: namedRoutes,
                navigatorKey: navigatorKey,
                onGenerateRoute: (RouteSettings settings) {
                  if (settings.name == '/player') {
                    return PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => const PlayScreen(),
                    );
                  }
                  return HandleRoute.handleRoute(settings.name);
                },
              );
            },
          );
        },
      ),
    );
  }
}
