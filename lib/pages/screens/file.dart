import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';
import 'package:path/path.dart';

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
                  subtitle: const Text("github.com/dolor-sit/amet", overflow: TextOverflow.ellipsis),
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
    switch (App.git.git_repository_open(repo, directory.toNativeUtf8().cast())) {
      case 0:
        break;
      case git_error_code.GIT_ENOTFOUND:
        showException(context, "Vybraná složka není Git repozitář. Vybrali jste správnou složku? Možná jste smazali skrytou podsložku `.git`.");
        return;
      default:
        showException(context, "Git repozitář se nepodařilo otevřít. Skrytá podsložka `.git` je možná poškozená.");
        return;
    }
    
    bool broken = false;
    try {
      dynamic values = json.decode(await index.readAsString());
      App.pedigree = Pedigree.parse(values, directory, repo);
      try {
        Pointer<Pointer<git_index>> gitIndex = calloc();
        Pointer<git_oid> treeOid = calloc();
        Pointer<Pointer<git_tree>> tree = calloc();
        Pointer<Pointer<git_tree_entry>> entry = calloc();
        Pointer<Pointer<git_object>> object = calloc();
        Pointer<git_oid> objectOid = calloc();
        Pointer<Pointer<git_blob>> blob = calloc();
        assert(0 == App.git.git_repository_index(gitIndex, App.pedigree!.repo.value));
        assert(0 == App.git.git_index_write_tree(treeOid, gitIndex.value));
        assert(0 == App.git.git_tree_lookup(tree, App.pedigree!.repo.value, treeOid));
        entry.value = App.git.git_tree_entry_byname(tree.value, "index.dpc".toNativeUtf8().cast());
        assert(0 == App.git.git_tree_entry_to_object(object, App.pedigree!.repo.value, entry.value));
        objectOid = App.git.git_object_id(object.value);
        assert(0 == App.git.git_blob_lookup(blob, App.pedigree!.repo.value, objectOid));
        Pointer<Void> blobBuffer = App.git.git_blob_rawcontent(blob.value);

        String text = (blobBuffer.cast<Pointer<Utf8>>() as Pointer<Utf8>).toDartString();
        dynamic values = json.decode(text);
        
        App.unchangedPedigree = Pedigree.upgrade(values, directory, repo);
      } on Exception catch (e, t) {
        showException(context, "Nelze porovnat rodokmen s verzí bez aktuálních změn.", e, t);
        App.unchangedPedigree = App.pedigree!.clone();
      }

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
}