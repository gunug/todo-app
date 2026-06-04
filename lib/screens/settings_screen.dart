import 'package:flutter/material.dart';
import 'package:todo_lock_app/l10n/app_l10n.dart';
import 'package:todo_lock_app/services/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final SettingsService settingsService;
  final ValueNotifier<Locale> localeNotifier;

  const SettingsDialog({
    super.key,
    required this.settingsService,
    required this.localeNotifier,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _selectedLang;

  @override
  void initState() {
    super.initState();
    _selectedLang = widget.localeNotifier.value.languageCode;
  }

  Future<void> _selectLang(String? lang) async {
    if (lang == null || lang == _selectedLang) return;
    setState(() => _selectedLang = lang);
    await widget.settingsService.setLanguage(lang);
    widget.localeNotifier.value = Locale(lang);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AlertDialog(
      title: Text(l10n.settings),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.language),
          RadioGroup<String>(
            groupValue: _selectedLang,
            onChanged: _selectLang,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text(l10n.korean),
                  value: 'ko',
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  title: Text(l10n.english),
                  value: 'en',
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
