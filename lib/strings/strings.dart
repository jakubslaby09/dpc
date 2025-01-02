import 'dart:async';

import 'package:dpc/strings/cz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// A map of supported locales.
/// 
/// When adding a language here, don't forget to add it to:
/// - android/app/build.gradle (to resourceConfigurations)
/// - android/app/src/main/res/xml/locales_config.xml
/// - and create android/app/src/main/res/values-??
final supportedLocales = <Locale, S>{
  Locale('en'): S(),
  Locale('cs'): Czech(),
};

// English
class S {
  String get noFileOpenNotice => "No file open!";
  String get noFileOpenButton => "Go to files";
  String get navFilesPage => "Files";
  String get navListPage => "People";
  String get navChroniclePage => "Chronicle";
  String get navCommitPage => "Changes";
  String get noRepoOpened => "Nothing's here...";
  String get openRepo => "Open a repository";
  String get downloadRepo => "Download a repository";
  String get createRepo => "Create a repository";
  String get preferences => "Settings";
  String get searchLabel => "Search";
  String get peopleNameColumn => "Name";
  String get peopleBirthColumn => "Birth";
  String get chronicleNameHint => "Name the chronicle";
  String get chronicleAddAuthor => "Add an author";
  String get chronicleAddFiles => "Přidat soubory";
  String get chronicleFilePickerTitle => "Vybrat soubory do kroniky";
  String get chronicleFileImportSheetTitle => "Vybrali jste soubor mimo repozitář. Vyberte pro něj v repozitáři umístění";
  String get chronicleFileImportSheetSuggestedDirectory => "kronika";

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S();
  }
  static const LocalizationsDelegate<S> delegate = _Delegate();
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];


}

class _Delegate extends LocalizationsDelegate<S> {
  const _Delegate();
  @override
  Future<S> load(Locale locale) {
    final match = supportedLocales[locale];
    if(match == null) {
      throw FlutterError(
        "Failed to load an unsupported locale: $locale"
        "Please report to https://github.com/jakubslaby09/dpc/issues/new"
      );
    }
    return SynchronousFuture(match);
  }
  @override
  bool isSupported(Locale locale) => supportedLocales.containsKey(locale);
  @override
  bool shouldReload(_Delegate _) => false;
}