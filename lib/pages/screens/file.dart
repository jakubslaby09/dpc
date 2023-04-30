import 'dart:convert';

import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
        // Row(
        //   children: [
        //     IconButton(
        //       icon: const Icon(Icons.settings_outlined),
        //       // child: const Text("Předvolby"),
        //       onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        //         builder: (context) => PreferencesPage(),
        //       )),
        //     ),
        //   ],
        // ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: Icon(Icons.file_open_outlined, color: Theme.of(context).colorScheme.onBackground),
                  title: Row(
                    children: const [
                      Expanded(child: Text("Lorem Ipsum")),
                      Icon(Icons.people_outlined),
                      Text("65"),
                      VerticalDivider(),
                      Icon(Icons.sd_storage_outlined),
                      Text("19KiB"),
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
              ),
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.file_copy_outlined),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Expanded(child: Text("Consecteur")),
                      IconButton(
                        color: Theme.of(context).colorScheme.onBackground,
                        icon: const Icon(Icons.clear),
                        onPressed: () {},
                      ),
                      IconButton(
                        color: Theme.of(context).colorScheme.onBackground,
                        icon: const Icon(Icons.open_in_browser_outlined),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  subtitle: const Text("/adiscipling/Elit/", overflow: TextOverflow.ellipsis),
                  // trailing: Row(
                  //   children: const [
                  //     Icon(Icons.people_alt_outlined),
                  //     Text("11")
                  //   ],
                  // ),
                  // trailing: Row(
                  //   children: [
                  //     IconButton(
                  //       color: Theme.of(context).colorScheme.onBackground,
                  //       icon: const Icon(Icons.open_in_browser_outlined),
                  //       onPressed: () {},
                  //     ),
                  //     IconButton(
                  //       color: Theme.of(context).colorScheme.onBackground,
                  //       icon: const Icon(Icons.open_in_browser_outlined),
                  //       onPressed: () {},
                  //     ),
                  //   ],
                  // ),
                  
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text("Otevřít soubor"),
          onTap: () => openFile(context),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text("Předvolby"),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PreferencesPage(),
          )),
        ),
      ],
    );
  }

  void openFile(BuildContext context) async {
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
    if (result.files.single.readStream == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Vybraný soubor se nepodařilo přečíst"),
      ));
      return;
    }

    dynamic file = json.decode(await utf8.decodeStream(result.files.single.readStream!));

    final recents = App.prefs.recentFiles;
    recents.removeWhere((path) => path == result.files.single.path);
    recents.insert(0, result.files.single.path!);
  }
}