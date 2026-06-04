import 'package:flutter/material.dart';
import 'package:todo_lock_app/app.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  final deviceLang =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final savedLang = settingsService.getSavedLanguage();
  final initialLang =
      savedLang ?? (deviceLang == 'ko' ? 'ko' : 'en');

  final localeNotifier = ValueNotifier<Locale>(Locale(initialLang));

  runApp(TodoApp(
    hiveService: hiveService,
    settingsService: settingsService,
    localeNotifier: localeNotifier,
  ));
}
