import 'package:flutter/material.dart';

class AppL10n {
  final String languageCode;
  const AppL10n(this.languageCode);

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ?? const AppL10n('ko');
  }

  bool get isKo => languageCode == 'ko';

  String get appTitle => isKo ? '할일 목록' : 'Todo List';
  String get newTodo => isKo ? '새 할일' : 'New Todo';
  String get editTodo => isKo ? '할일 수정' : 'Edit Todo';
  String get titleLabel => isKo ? '제목' : 'Title';
  String get titleHint => isKo ? '할일을 입력하세요' : 'Enter a todo';
  String get titleRequired => isKo ? '제목을 입력해주세요' : 'Please enter a title';
  String get descriptionLabel => isKo ? '설명 (선택)' : 'Description (optional)';
  String get descriptionHint => isKo ? '상세 설명을 입력하세요' : 'Enter a description';
  String get cancel => isKo ? '취소' : 'Cancel';
  String get save => isKo ? '저장' : 'Save';
  String get add => isKo ? '추가' : 'Add';
  String get emptyTitle => isKo ? '할일이 없습니다' : 'No todos';
  String get emptySubtitle => isKo ? '+ 버튼을 눌러 새 할일을 추가하세요' : 'Tap + to add a new todo';
  String deletedMessage(String title) =>
      isKo ? "'$title' 삭제됨" : "'$title' deleted";
  String get undo => isKo ? '되돌리기' : 'Undo';
  String get confirm => isKo ? '확인' : 'Confirm';
  String elapsedDays(int days) => isKo ? '+$days일' : '+${days}day';
  String get settings => isKo ? '설정' : 'Settings';
  String get language => isKo ? '언어' : 'Language';
  String get korean => '한국어';
  String get english => 'English';
}

class AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ko' || locale.languageCode == 'en';

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale.languageCode);

  @override
  bool shouldReload(AppL10nDelegate old) => false;
}
