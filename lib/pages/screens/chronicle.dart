import 'dart:io';

import 'package:dpc/autosave.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/chronicle.dart';
import 'package:dpc/widgets/file_import_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ChronicleScreen extends StatefulWidget {
  const ChronicleScreen({super.key});

  @override
  State<ChronicleScreen> createState() => _ChronicleScreenState();
}

class _ChronicleScreenState extends State<ChronicleScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: make the title and authors editable
    return ListView(
      children: App.pedigree!.chronicle.indexedMap((chronicle, chronicleIndex) => Padding(
        padding: const EdgeInsets.all(8),
        child: Card(
          // shape: RoundedRectangleBorder(
          //   side: BorderSide(
          //     color: Theme.of(context).colorScheme.outline,
          //   ),
          //   borderRadius: const BorderRadius.all(Radius.circular(12)),
          // ),
          // elevation: 0,
          child: Column(
            children: [
              ListTile(
                iconColor: Theme.of(context).colorScheme.outline,
                leading: Icon(chronicle.mime.icon),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text(chronicle.name)),
                    if(chronicle.files.isNotEmpty) IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        addFile(context, chronicle).then((_) => setState(() {}));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined),
                      onPressed: () => setState(() {
                        App.pedigree!.chronicle.removeAt(chronicleIndex);
                        scheduleSave(context);
                      }),
                    ),
                  ],
                ),
                subtitle: Row(
                  // TODO: fix overflow
                  children: chronicle.authors.map((e) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onBackground,
                      )
                    ),
                    child: Row(
                      children: [
                        // TODO: make a more robust person lookup fuction
                        Icon(App.pedigree!.people[e.round()].sex.icon),
                        Padding(
                          padding: const EdgeInsets.only(left: 2, right: 8),
                          child: Text(App.pedigree!.people[e.round()].name),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              Divider(height: chronicle.files.length <= 1 ? 2 : null),
              ...chronicle.files.indexedMap((fileName, index) => ListTile(
                // leading: Icon(chronicle.mime.icon, color: Theme.of(context).colorScheme.outline),
                title: Row(
                  children: [
                    Expanded(child: Text(fileName)),
                    if(chronicle.mime.openable) const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.navigate_next),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() {
                        chronicle.files.removeAt(index);
                        scheduleSave(context);
                      }),
                    )
                  ],
                ),
                onTap: chronicle.mime.openable ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ChroniclePage(fileName, context, markdown: chronicle.mime == ChronicleMime.textMarkdown),
                )) : null,
              )),
              if(chronicle.files.isEmpty) ListTile(
                iconColor: Theme.of(context).colorScheme.outline,
                title: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.add),
                    ),
                    Text("Přidat soubory", textAlign: TextAlign.center),
                  ],
                ),
                onTap: () => addFile(context, chronicle).then((_) => setState(() {})),
              )
            ],
          ),
        ),
      )).toList(),
    );
  }
}

Future<void> addFile(BuildContext context, Chronicle chronicle) async {
  // TODO: use allowedExtensions
  final picked = await FilePicker.platform.pickFiles(
    dialogTitle: "Vybrat soubory do kroniky",
    allowMultiple: true,
  );

  if(picked == null) {
    return;
  }

  for (final platformFile in picked.files) {
    if(platformFile.path == null) {
      // TODO: examine when it happens
      continue;
    }

    final sourceFile = File(platformFile.path!);
    File file;
    // TODO: debug with mounted subdirs
    if(p.isWithin(App.pedigree!.dir, sourceFile.path)) {
      file = sourceFile;
    } else {
      final filePath = await showFileImportSheet(context, sourceFile.path, "kronika", "Vybrali jste soubor mimo repozitář. Vyberte pro něj v repozitáři umístění");
      if(filePath == null) {
        return;
      }
      file = File(filePath);
      await file.create(recursive: true);
      await sourceFile.copy(file.path);
    }

    chronicle.files.add(p.relative(file.path, from: App.pedigree!.dir));
    // TODO: fix ordering
  }
}