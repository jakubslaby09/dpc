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
  String fetchedCommits(int count, bool localChanges) => "There ${count > 1 ? "are $count new commits" : "is a new commit"} in the remote repository.${localChanges ? " Downloading ${count > 1 ? "it" : "them"} will overwrite your local changes." : ""}";
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
  String get cloneGithub => "Github";
  String get cloneCustomUrl => "Custom URL";
  String get cloneTargetDir => "Repository directory";
  String get clonePickTargetDir => "Choose a new repository folder";
  String get cloneMissingTargetDir => "Choose where you'd like to store the repository";
  String get cloneNonexistentTargetDir => "The folder doesn't exist. Did you create it?";
  String get cloneDirtyTargetDir => "The folder is not empty";
  String get cloneUrl => "Repository URL";
  String get cloneMissingUrl => "Specify an address to download from";
  String get cloneInvalidUrl => "This isn't a valid URL nor a valid absolute URI";
  String cloneMissingUsername(String host) => "'@' is included, but ':' is missing. Please specify a username: user:$host";
  String get cloneGithubRepoName => "Repository name";
  String get cloneGithubMissingRepoName => "Pick a github repository";
  String get cloneMissingGithubUser => "Please specify the repository owner, e.g. owner/repository";
  String cloneGithubUrlTooManySlashes(String username, String repo) => "Please provide only an author and their repository. Consider: $username/$repo";
  String cloneProgressMiB(int mib) => "$mib MiB";
  String cloneProgressPercent(String percent) => "$percent %";
  String get cloneAbort => "Abort";
  String get cloneCancel => "Cancel";
  String get cloneStoragePermissionRejected => "Permission denied";
  String cloneCouldNotCreateDir(Exception e) => "Could not create folder. Try creating it manually: $e";
  String get cloneTryAgain => "Try again";
  String get cloneConfirm => "Download";
  String get cloneGithubConfirm => "Log in & download";
  String get cloneCanceled => "Canceled";
  String get cloneOAuthHtmlText => "You can close this window now";
  String get cloneCouldNotInit => "Could not initialize cloning the repository";
  String get cloneCouldNotClone => "Could not download";
  String get commitChanges => "Publish";
  String get commitMessage => "Commit message";
  String get commitMessageMissing => "Please describe your changes";
  String get commitDescription => "Long description";
  String get commitSignature => "Author signature";
  String get commitSignatureName => "Name";
  String get commitSignatureNameMissing => "Please specify who made the changes";
  String get commitSignatureEmail => "Email";
  String get commitSignatureEmailMissing => "Please provide the author's email";
  String get commitSignatureSave => "Remember this signature";
  String get commitCancel => "Cancel";
  String get commitPush => "Send commit";
  String get commitCouldNotCreateCommit => "Could not create the commit";
  String get commitCouldNotLookupRemote => "Could not read which remote repository to send the commit to";
  String get commitCouldNotSaveSignature => "Could not save the signature";
  String commitCouldNotCommit(Exception e) => "Could not send your changes: $e";
  String get upgradeRepo => "Upgrade pedigree index?";
  String upgradeRepoDir(String path) => "In $path";
  String get upgradeRepoFromVersion => "from version ";
  String get upgradeRepoToVersion => "to version ";
  String get upgradeRepoButton => "Upgrade";
  String get createRepoDefaultCommitMessage => "Create repository";
  String get createRepoCouldNotAccessDir => "This directory is not accessible";
  String get createRepoDirtyDir => "This directory is not empty. A subdirectory will be created.";
  String get createRepoChronicleNameLabel => "Chronicle name";
  String get createRepoChronicleNameHint => "The Glanzmanns";
  String get createRepoMissingName => "Please name the chronicle";
  String get createRepoDirName => "New repository directory";
  String get createRepoDirWithSubdirName => "Path to the repository";
  String get createRepoSubirName => "Repository directory name";
  String get createRepoMissingSubdirName => "Please choose a directory name";
  String get createRepoCommitMessage => "First commit message";
  String get createRepoMissingCommitMessage => "Please choose a commit message";
  String get createRepoSignatureName => "Commit signature name";
  String get createRepoMissingSignatureName => "Please provide a signature name";
  String get createRepoSignatureEmail => "Commit signature email";
  String get createRepoMissingSignatureEmail => "Please provide a signature email";
  String get createRepoAbort => "Cancel";
  String get createRepoConfirm => "Create";
  String get importFileSourceFile => "Source file";
  String get importFileDestFile => "Destination in the repository";
  String get importFileCancel => "Cancel";
  String get importFileConfirm => "Add to repository";
  String importFileDialogTitle(String filename) => "Pick a destination for $filename";
  String get importFileDestinationAlreadyExists => "That path already exists";
  String get importFileSourceDoesNotExist => "The file does not exist anymore. Did you delete it?";
  String get importFileDestOutsideRepo => "The destination must be inside the repository";
  String importFileInvalidExt(String requiredExt) => "The file extension is not the same. Try changing it to $requiredExt";
  String get personFieldSearchHint => "Name";
  String get pedigreeSaveMissingFile => "Could not save your changes to the chronicle file. Did you delete it?";
  String get pedigreeSaveCouldNotSave => "Could not save your changes.";
  String get logTitle => "Error log";
  String get logTitleUnexpected => "An error has just happened!";
  String get logDetailButton => "See more";
  String get logReportButton => "Report";
  String get preferencesAppearance => "Appearance";
  String get preferencesTitle => "Preferences";
  String get preferencesAutoTheme => "Use system's theme";
  String get preferencesDarkTheme => "Dark theme";
  String get preferencesColoredAvatars => "Colored avatar icons";
  String get preferencesRecentFiles => "Recently opened";
  String get preferencesRecentFilesCapacity => "Capacity";
  String get preferencesRecentFilesDisabled => " Don't show ";
  String get preferencesRecentFilesSaveBroken => "Remember broken files";
  String get preferencesChanges => "Your changes";
  String get preferencesChangesSaveDelay => "Save delay";
  String preferencesChangesSaveDelaySeconds(int count) => "${count}s";
  String get preferencesChangesSaveDelayDisabled => " Save immediately ";
  String get preferencesAutoUpgrade => "Upgrade files without confirmation";
  String personPictureDialogTitle(String name) => "Picture of $name";
  String personPictureImportTitle(String name) => "Name $name's picture";
  String get personPictureDefaultImportDir => "profile pictures";
  String get personPictureCouldNotCopy => "Could not copy the profile picture";
  String get personPictureCouldNotLoad => "Could not load the profile picture";
  String get personNameAndSex => "Name";
  String get personBirth => "Date of birth";
  String get personDeath => "Date of death";
  String get personFather => "Father";
  String get personMother => "Mother";
  String get personAddChild => "Add a child";
  String get personUnknownChild => "unknown child";
  String get personUnknownChildren => "unknown children";
  String personUnknownChildrenWith(String name) => "unknown children with $name";

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