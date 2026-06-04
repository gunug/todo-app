import 'package:hive_ce_flutter/hive_flutter.dart';

class SettingsService {
  static const _boxName = 'settings';
  static const _langKey = 'language';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  String? getSavedLanguage() => _box.get(_langKey) as String?;

  Future<void> setLanguage(String langCode) async {
    await _box.put(_langKey, langCode);
  }
}
