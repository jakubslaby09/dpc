import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
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
                  leading: Icon(Icons.file_open_outlined, color: Theme.of(context).colorScheme.onBackground),
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
              ) else const Card(
                // shape: RoundedRectangleBorder( // TODO: dashed borders
                //   borderRadius: BorderRadius.all(Radius.circular(8)),
                //   side: BorderSide(
                //     color: Theme.of(context).colorScheme.onBackground,
                //   )
                // ),
                child: ListTile(
                  leading: Icon(Icons.clear),
                  title: Center(child: Text("Nic tu není...")),
                ),
              ),
              ...(App.pedigree == null ? App.prefs.recentFiles : App.prefs.recentFiles.length > 1 ? App.prefs.recentFiles.sublist(1) : []).map((filePath) => Card(
                elevation: 0,
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
                        color: Theme.of(context).colorScheme.onBackground,
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
          title: const Text("Otevřít repozitář"),
          onTap: () => openRepo(context).then((_) => setState(() {})),
        ),
        ListTile(
          leading: const Icon(Icons.download_for_offline_outlined),
          title: const Text("Stáhnout repozitář"),
          onTap: () async {
            final path = await CloneRepoSheet.show(context);
            if(path == null) return;

            await openRepo(context, path);
            setState(() { });
          },
        ),
        ListTile(
          leading: const Icon(Icons.create_new_folder_outlined),
          title: const Text("Založit nový repozitář"),
          onTap: () => createRepo(context).then((_) => setState(() {})),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text("Předvolby"),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("V uloženém repozitáři se nepodařilo přečíst index. Možná jste ho přesunuli, nebo smazali."),
        ));
        return;
      }
    } else {
      directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Otevřít repozitář",
      );

      if (directory == null) return;
      index = File(join(directory, "index.dpc"));
      if (!await index.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Ve vybraném repozitáři se nepodařilo přečíst index. Vybrali jste správnou složku?"),
        ));
        return;
      }
    }
    
    Pointer<Pointer<git_repository>> repo = calloc();
    final repoOpenResult = App.git.git_repository_open(repo, directory.toNativeUtf8().cast());
    switch (repoOpenResult) {
      case 0:
        break;
      case git_error_code.GIT_ENOTFOUND:
        showException(context, "Vybraná složka není Git repozitář. Vybrali jste správnou složku? Možná jste smazali skrytou podsložku `.git`.");
        return;
      default:
        showException(context, "Git repozitář se nepodařilo otevřít. Skrytá podsložka `.git` je možná poškozená.", Exception(repoOpenResult));
        return;
    }
    
    bool broken = false;
    try {
      String indexString;
      try {
        indexString = await index.readAsString();
      } on PathAccessException catch (e) {
        if(await Permission.manageExternalStorage.isGranted) rethrow;
        // TODO: make a dialog for it
        await Permission.manageExternalStorage.request();
        indexString = await index.readAsString();
      }
      dynamic indexValues = json.decode(indexString);
      if(App.prefs.autoUpgradeFiles) {
        App.pedigree = Pedigree.upgrade(indexValues, directory, repo.value);
        scheduleSave(context);
      } else {
        App.pedigree = Pedigree.parse(indexValues, directory, repo.value);
      }
      try {
        readUnchanged(context, directory, repo.value);
      } on Exception catch (e, t) {
        showException(context, "Nelze porovnat rodokmen s verzí bez aktuálních změn.", e, t);
        App.unchangedPedigree = App.pedigree!.clone();
      }

    } on PathAccessException catch (e, t) {
      showException(context, "Aplikaci nebylo povoleno přečíst rodokmen.", e, t);
    } on Exception catch (e, t) {
      // TODO: make a pedigree upgrade dialog
      showException(context, "Vybraný soubor vypadá poškozeně! Opravdu je to soubor s rodokmenem?", e, t);
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
      dialogTitle: "Vybrat složku pro nový repozitář",
    );
    if(pickerResult == null) return;

    Directory directory = Directory(pickerResult);
    final sheetResult = await CreateRepoSheet.show(context, directory);
    if(sheetResult == null) return;
    directory = Directory(sheetResult.dir);
    await directory.create(recursive: true);
    
    try {
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
        saveDefaultSignature(repo.value, name, email);
      } on Exception catch (e, t) {
        showException(context, "Nelze pro nový repozitář nastavit Váš podpis", e, t);
      }
    } on Exception catch (e, t) {
      showException(context, "Nelze pro nový rodokmen založit Git repozitář", e, t);
    }

    await openRepo(context, directory.path);
  }
}

void saveDefaultSignature(Pointer<git_repository> repo, Pointer<Char> name, Pointer<Char>? email) {
  Pointer<Pointer<git_config>> config = calloc();
  expectCode(App.git.git_repository_config(config, repo), "nelze číst z configu repozitáře");
  expectCode(
    App.git.git_config_set_string(config.value, "user.name".toNativeUtf8().cast(), name),
    "nelze uložit jméno v configu repozitáře",
  );
  if(email != null) {
    expectCode(
      App.git.git_config_set_string(config.value, "user.email".toNativeUtf8().cast(), email),
      "nelze uložit email v configu repozitáře",
    );
  }
  App.git.git_config_free(config.value);
}

void readUnchanged(BuildContext context, String directory, Pointer<git_repository> repo) {
  Pointer<Pointer<git_index>> gitIndex = calloc();
  Pointer<git_oid> treeOid = calloc();
  Pointer<Pointer<git_tree>> tree = calloc();
  Pointer<Pointer<git_tree_entry>> entry = calloc();
  Pointer<Pointer<git_object>> object = calloc();
  Pointer<git_oid> objectOid = calloc();
  Pointer<Pointer<git_blob>> blob = calloc();
  expectCode(App.git.git_repository_index(gitIndex, App.pedigree!.repo));
  expectCode(App.git.git_index_write_tree(treeOid, gitIndex.value));
  expectCode(App.git.git_tree_lookup(tree, App.pedigree!.repo, treeOid));
  entry.value = App.git.git_tree_entry_byname(tree.value, "index.dpc".toNativeUtf8().cast());
  expectCode(App.git.git_tree_entry_to_object(object, App.pedigree!.repo, entry.value));
  objectOid = App.git.git_object_id(object.value);
  expectCode(App.git.git_blob_lookup(blob, App.pedigree!.repo, objectOid));
  Pointer<Void> blobBuffer = App.git.git_blob_rawcontent(blob.value);

  String text = (blobBuffer.cast<Pointer<Utf8>>() as Pointer<Utf8>).toDartString();
  dynamic values = json.decode(text);
  
  App.unchangedPedigree = Pedigree.upgrade(values, directory, repo);
}

void expectCode(int code, [String? message]) {
  if(code == 0) return;
  throw GitException(code, message);
}

class GitException implements Exception {
  GitException(this.code, [this.message]);

  int code;
  String? message;

  @override
  String toString() {
    return "Git Exception $code${message != null ? ": $message" : ""}";
  }
}