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
  Locale('en'): const S.english(),
  Locale('cs'): const Czech(),
};

class S {
  const S.english();

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
  String get chronicleAddFiles => "Attach files";
  String get chronicleFilePickerTitle => "Attach files to a chronicle";
  String get chronicleFileImportSheetTitle => "The file isn't in the repository yet. Pick a place for it.";
  String get chronicleFileImportSheetSuggestedDirectory => "kronika"; //TODO: check if it's safe to translate
  String get fetchingCommits => "Downloading changes...";
  String get couldNotFetchCommits => "Could not fetch remote changes";
  String fetchedCommits(int count, bool localChanges) => "There ${count > 1 ? "are" : "is"} ${count > 1 ? "are $count new commits" : "a new commit"} in the remote repository.${localChanges ? " Downloading ${count > 1 ? "it" : "them"} will overwrite your local changes." : ""}";
  String get repoUpToDate => "Your repository is up to date";
  String get overwriteWorktree => "Overwrite";
  String ffCommits(int count) => "Download${count > 1 ? "" : " $count commits"}";
  String get fetchErrorDetails => "See details";
  String get indexUpgradeChange => "Indexu version upgrade";
  String get commitCannotReadHead => "Could not read the commit you just have published";
  String get fetchCouldNotLookupRemote => "Could not read from which remote repository to download changes";
  String get fetchCouldNotFetchRemote => "Could not download changes from the remote repository";
  String get fetchCouldNotReadHead => "Could not read your latest commit";
  String get fetchCouldNotReadFetchHead => "Could not read the latest commit you have just downloaded";
  String get fetchCouldNotCompareRemote => "Could not compare your changes with the remote ones";
  String get changesCouldNotDeleteFile => "Could not delete the file";
  String get changesCouldNotInitDiffOptions => "Could not initialize the comparison of your changes";
  String get changesCouldNotDiffNew => "Could not compare your attachment files";
  String get child => "Child";
  String get existingChild => "Existing child";
  String get unknownChild => "Unknown child";
  String get unknownChildren => "Unknown children";
  String get mother => "Mother";
  String get father => "Father";
  String get addChild => "Add child";

  factory S(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S.english();
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