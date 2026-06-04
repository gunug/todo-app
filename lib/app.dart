import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:todo_lock_app/l10n/app_l10n.dart';
import 'package:todo_lock_app/screens/home_screen.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/settings_service.dart';

class TodoApp extends StatelessWidget {
  final HiveService hiveService;
  final SettingsService settingsService;
  final ValueNotifier<Locale> localeNotifier;

  const TodoApp({
    super.key,
    required this.hiveService,
    required this.settingsService,
    required this.localeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'TodoLift',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: const [
            AppL10nDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en')],
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.system,
          home: HomeScreen(
            hiveService: hiveService,
            settingsService: settingsService,
            localeNotifier: localeNotifier,
          ),
        );
      },
    );
  }
}
