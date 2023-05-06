import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
                  title: Row(
                    children: [
                      Expanded(child: Text(App.pedigree?.name ?? "Lorem Ipsum")),
                      const Icon(Icons.people_outlined),
                      const Text("65"),
                      const VerticalDivider(),
                      const Icon(Icons.sd_storage_outlined),
                      const Text("19KiB"),
                    ],
                  ),
                  subtitle: const Text("github.com/dolor-sit/amet", overflow: TextOverflow.ellipsis),
                  // trailing: Row(
                  //   children: const [
                  //     Icon(Icons.people_alt_outlined),
                  //     Text("11")
                  //   ],
                  // ),
                  
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
                  onTap: () => openFile(context, filePath).then((_) => setState(() {})),
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
          title: const Text("Otevřít soubor"),
          onTap: () => openFile(context).then((_) => setState(() {})),
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

  Future<void> openFile(BuildContext context, [String? path]) async {
    String file;

    if (path != null) {
      try {
        file = await File(path).readAsString();
      } on FileSystemException catch(e) {
        if (e.osError?.errorCode == 36) {
          showException(context, "Soubor již neexistuje! Možná jste ho přesunuli, nebo smazali.", e);
          return;
        }
        showException(context, "Nelze přečíst soubor!", e);
        return;
      } on Exception catch (e) {
        showException(context, "Nelze přečíst soubor!", e);
        return;
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        withReadStream: true,
      );

      if (result == null) return;
      if (result.files.single.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Nelze přečíst cestu k vybranému souboru"),
        ));
        return;
      }
      path = result.files.single.path!;
      if (result.files.single.readStream == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Vybraný soubor se nepodařilo přečíst"),
        ));
        return;
      }
      file = await utf8.decodeStream(result.files.single.readStream!);
    }
    
    bool broken = false;
    try {
      dynamic values = json.decode(file);
      App.pedigree = Pedigree.parse(values);
    } on Exception catch (e) {
      showException(context, "Vybraný soubor vypadá poškozeně! Opravdu je to soubor s rodokmenem?", e);
      if (!App.prefs.saveBrokenRecentFiles) {
        return;
      }
      broken = true;
    }

    final recents = App.prefs.recentFiles;
    recents.removeWhere((recentPath) => recentPath == path);
    recents.insert(broken && App.pedigree != null && recents.isNotEmpty ? 1 : 0, path);
    App.prefs.recentFiles = recents;
  }
}