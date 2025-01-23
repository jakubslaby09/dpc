import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:dpc/widgets/confirm_upgrade_sheet.dart';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:dpc/autosave.dart';
import 'package:dpc/widgets/clone_repo_sheet.dart';
import 'package:dpc/widgets/create_repo_sheet.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/preferences.dart';
import 'package:dpc/pages/log.dart';

import '../../strings/strings.dart';

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (App.pedigree != null) Card(
                child: ListTile(
                  leading: Icon(Icons.file_open_outlined, color: Theme.of(context).colorScheme.onSurface),
                  title: Text(App.pedigree!.name),
                  subtitle: Text(App.pedigree!.dir, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outlined),
                      Text(App.pedigree!.people.length.toString(), style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                ),
              ) else Card(
                // shape: RoundedRectangleBorder( // TODO: dashed borders
                //   borderRadius: BorderRadius.all(Radius.circular(8)),
                //   side: BorderSide(
                //     color: Theme.of(context).colorScheme.onBackground,
                //   )
                // ),
                child: ListTile(
                  leading: const Icon(Icons.clear),
                  title: Center(child: Text(S(context).noRepoOpened)),
                ),
              ),
              ...(App.pedigree == null ? App.prefs.recentFiles : App.prefs.recentFiles.length > 1 ? App.prefs.recentFiles.sublist(1) : []).map((filePath) => Card(
                elevation: 0,
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.file_copy_outlined),
                  onTap: () => openRepo(context, filePath).then((_) => setState(() {})),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // const Icon(Icons.file_copy_outlined),
                      Expanded(child: Text(filePath)),
                      IconButton(
                        color: Theme.of(context).colorScheme.onSurface,
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          final recents = App.prefs.recentFiles;
                          recents.removeWhere((recentPath) => recentPath == filePath);
                          App.prefs.recentFiles = recents;
                        }),
                      ),
                    ],
                  ),
                  // subtitle: const Text("/adiscipling/Elit/", overflow: TextOverflow.ellipsis),
                ),
              )),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: Text(S(context).openRepo),
          onTap: () => openRepo(context).then((_) => setState(() {})),
        ),
        ListTile(
          leading: const Icon(Icons.download_for_offline_outlined),
          title: Text(S(context).downloadRepo),
          onTap: () async {
            final path = await CloneRepoSheet.show(context);
            if(path == null) return;

            await openRepo(context, path);
            setState(() { });
          },
        ),
        ListTile(
          leading: const Icon(Icons.create_new_folder_outlined),
          title: Text(S(context).createRepo),
          onTap: () => createRepo(context).then((_) => setState(() {})),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(S(context).preferences),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const PreferencesPage(),
          )).then((_) => setState(() {})),
        ),
      ],
    );
  }

  Future<void> openRepo(BuildContext context, [String? directory]) async {
    File index;

    if (directory != null) {
      // index = await File(path).readAsString();
      index = File(join(directory, "index.dpc"));
      if (!await index.exists()) {
        showException(context, S(context).openRepoFromRecentsMissingIndex);
        return;
      }
    } else {
      directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: S(context).openRepoDialogTitle,
      );

      if (directory == null) return;
      index = File(join(directory, "index.dpc"));
      if (!await index.exists()) {
        showException(context, S(context).openRepoDialogMissingIndex);
        return;
      }
    }

    Pointer<Pointer<git_repository>> repo = calloc();
    final repoOpenResult = App.git.git_repository_open(repo, directory.toNativeUtf8().cast());
    switch (repoOpenResult) {
      case 0:
        break;
      case git_error_code.GIT_ENOTFOUND:
        showException(context, S(context).openRepoMissingGitDir);
        return;
      default:
        showException(context, S(context).openRepoCouldNotOpenGitRepo, Exception(repoOpenResult));
        return;
    }

    bool broken = false;
    try {
      String indexString;
      try {
        indexString = await index.readAsString();
      } on PathAccessException catch (_) {
        if(await Permission.manageExternalStorage.isGranted) rethrow;
        // TODO: make a dialog for it
        await Permission.manageExternalStorage.request();
        indexString = await index.readAsString();
      }
      dynamic indexValues = json.decode(indexString);
      try {
        App.pedigree = Pedigree.parse(indexValues, directory, repo.value);
      } on OutdatedPedigreeException catch (e, _) {
        if(!App.prefs.autoUpgradeFiles && !await UpgradeSheet.show(context, e.version, index.parent.path)) {
          return;
        }
        App.pedigree = Pedigree.upgrade(indexValues, directory, repo.value);
        scheduleSave(context);
      }
      try {
        loadUnchanged(context, directory, repo.value);
      } on Exception catch (e, t) {
        showException(context, S(context).openRepoCouldNotLoadUnchanged, e, t);
        App.unchangedPedigree = App.pedigree!.clone();
      }

    } on PathAccessException catch (e, t) {
      showException(context, S(context).openRepoInaccessibleRepo, e, t);
    } on OutdatedPedigreeException catch (e, t) {
      broken = true;
      showException(context, S(context).openRepoOutdatedIndex, e, t);
      if (!App.prefs.saveBrokenRecentFiles) {
        return;
      }
    } on Exception catch (e, t) {
      showException(context, S(context).openRepoInvalidIndex, e, t);
      if (!App.prefs.saveBrokenRecentFiles) {
        return;
      }
      broken = true;
    }

    final recents = App.prefs.recentFiles;
    recents.removeWhere((recentPath) => recentPath == directory);
    recents.insert(broken && App.pedigree != null && recents.isNotEmpty ? 1 : 0, directory);
    App.prefs.recentFiles = recents;
  }

  // TODO: move into sheet file
  createRepo(BuildContext context) async {
    final pickerResult = await FilePicker.platform.getDirectoryPath(
      dialogTitle: S(context).createRepoDialogTitle,
    );
    if(pickerResult == null) return;

    Directory directory = Directory(pickerResult);
    final sheetResult = await CreateRepoSheet.show(context, directory);
    if(sheetResult == null) return;
    directory = Directory(sheetResult.dir);
    try {
        await directory.create(recursive: true);
    } on PathAccessException catch (e) {
        showException(context, S(context).createRepoInaccessibleDir, e);
    } on Exception catch (e) {
        showException(context, S(context).createRepoCouldNotCreateDir, e);
    }

    try {
      // just to test ownership
      // TODO: use join instead
      await Directory("${directory.path}/.git").create(recursive: true);

      // TODO: free memory
      Pointer<Pointer<git_repository>> repo = calloc();
      Pointer<Pointer<git_signature>> signature = calloc();
      Pointer<Pointer<git_index>> index = calloc();
      Pointer<git_oid> treeId = calloc();
      Pointer<Pointer<git_tree>> tree = calloc();
      Pointer<git_oid> commitId = calloc();
      expectCode(App.git.git_repository_init(repo, directory.path.toNativeUtf8().cast(), 0));

      final pedigree = Pedigree.empty(sheetResult.name, directory.path, repo.value);
      await pedigree.save(context, true);

      final Pointer<Char> name = sheetResult.gitName.toNativeUtf8().cast();
      final Pointer<Char> email = sheetResult.gitEmail.toNativeUtf8().cast();
      expectCode(App.git.git_signature_now(signature, name, email));
      expectCode(App.git.git_repository_index(index, repo.value));
      expectCode(App.git.git_index_add_bypath(index.value, "index.dpc".toNativeUtf8().cast()));
      expectCode(App.git.git_index_write(index.value));
      expectCode(App.git.git_index_write_tree(treeId, index.value));
      expectCode(App.git.git_tree_lookup(tree, repo.value, treeId));
      expectCode(App.git.git_commit_create(
        commitId,
        repo.value,
        "HEAD".toNativeUtf8().cast(),
        signature.value,
        signature.value,
        "UTF-8".toNativeUtf8().cast(),
        sheetResult.commitMessage.toNativeUtf8().cast(),
        tree.value,
        0,
        nullptr,
      ));

      try {
        saveDefaultSignature(repo.value, name, email, S(context));
      } on Exception catch (e, t) {
        showException(context, S(context).createRepoCouldNotSaveSig, e, t);
      }
    } on PathAccessException catch (e, t) {
      showException(context, S(context).createRepoInaccessibleGitDir, e, t);
      return;
    } on Exception catch (e, t) {
      showException(context, S(context).createRepoCouldNotCreateGitDir, e, t);
      return;
    }

    await openRepo(context, directory.path);
  }
}

void saveDefaultSignature(Pointer<git_repository> repo, Pointer<Char> name, Pointer<Char>? email, S s) {
  Pointer<Pointer<git_config>> config = calloc();
  expectCode(App.git.git_repository_config(config, repo), s.createRepoCouldNotOpenGitConfig);
  expectCode(
    App.git.git_config_set_string(config.value, "user.name".toNativeUtf8().cast(), name),
    s.createRepoCouldNotSaveSigName,
  );
  if(email != null) {
    expectCode(
      App.git.git_config_set_string(config.value, "user.email".toNativeUtf8().cast(), email),
      s.createRepoCouldNotSaveSigEmail,
    );
  }
  App.git.git_config_free(config.value);
}

void loadUnchanged(BuildContext context, String directory, Pointer<git_repository> repo) {
  String text = readUnchangedString(repo);
  dynamic values = json.decode(text);

  final version = values['version'] as int;
  App.unchangedPedigree = Pedigree.upgrade(values, directory, repo);
  App.unchangedPedigree!.version = version;
}

String readUnchangedString(Pointer<git_repository> repo) {
  Pointer<Pointer<git_index>> gitIndex = calloc();
  Pointer<git_oid> treeOid = calloc();
  Pointer<Pointer<git_tree>> tree = calloc();
  Pointer<Pointer<git_tree_entry>> entry = calloc();
  Pointer<Pointer<git_object>> object = calloc();
  Pointer<git_oid> objectOid = calloc();
  Pointer<Pointer<git_blob>> blob = calloc();
  expectCode(App.git.git_repository_index(gitIndex, repo));
  expectCode(App.git.git_index_write_tree(treeOid, gitIndex.value));
  expectCode(App.git.git_tree_lookup(tree, repo, treeOid));
  entry.value = App.git.git_tree_entry_byname(tree.value, "index.dpc".toNativeUtf8().cast());
  expectCode(App.git.git_tree_entry_to_object(object, repo, entry.value));
  objectOid = App.git.git_object_id(object.value);
  expectCode(App.git.git_blob_lookup(blob, repo, objectOid));
  Pointer<Void> blobBuffer = App.git.git_blob_rawcontent(blob.value);

  return (blobBuffer.cast<Pointer<Utf8>>() as Pointer<Utf8>).toDartString();
}

void expectCode(int code, [String? message, Pointer<git_error>? gitError]) {
  if(code == 0) return;
  throw GitException(code, message, gitError?.ref.message.toDartString());
}

class GitException implements Exception {
  GitException(this.code, [this.message, this.gitMessage]);

  int code;
  String? message;
  String? gitMessage;

  @override
  String toString() {
    String? gitMessage = this.gitMessage;
    try {
      gitMessage ??= ": last libgit error: ${App.git.git_error_last().ref.message.toDartString()}";
    } catch (e) {
      gitMessage = " (could not get last libgit error: ${e.toString()})";
    }
    return "Git Exception $code${message != null ? ": $message" : ""}$gitMessage";
  }
}
