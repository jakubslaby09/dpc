import 'dart:io';

import 'package:dpc/autosave.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/chronicle.dart';
import 'package:dpc/pages/home.dart';
import 'package:dpc/widgets/file_import_sheet.dart';
import 'package:dpc/widgets/person_chip.dart';
import 'package:dpc/widgets/person_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../strings/strings.dart';

class ChronicleScreen extends UniqueWidget implements FABScreen {
  const ChronicleScreen({required super.key});

  @override
  State<ChronicleScreen> createState() => _ChronicleScreenState();

  @override
  Widget? fab(BuildContext context) {
    return FloatingActionButton.small(
      child: const Icon(Icons.add),
      onPressed: () => (currentState as _ChronicleScreenState?)?.createEmpty(),
    );
  }
}

class _ChronicleScreenState extends State<ChronicleScreen> {
  final controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.only(bottom: 60),
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
                leading: const Icon(Icons.history_edu),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      // child: Text(chronicle.name)
                      child: TextFormField(
                        initialValue: chronicle.name,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: S(context).chronicleNameHint,
                        ),
                        onChanged: (newName) {
                          chronicle.name = newName;
                          scheduleSave(context);
                        },
                      ),
                    ),
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
                  children: [
                    ...chronicle.authors.map((authorId) => PersonChip(
                      margin: const EdgeInsets.only(right: 8, bottom: 4),
                      // TODO: make a more robust person lookup fuction
                      person: App.pedigree!.people[authorId.round()],
                      repoDir: App.pedigree!.dir,
                      onRemove: () {
                        setState(() {
                          chronicle.authors.remove(authorId);
                        });
                        scheduleSave(context);
                      },
                    )),
                    if(chronicle.authors.isEmpty) OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(S(context).chronicleAddAuthor),
                      onPressed: () => addAuthor(chronicle),
                    ),
                    if(chronicle.authors.isNotEmpty) SizedBox(
                      height: 32,
                      width: 32,
                      child: IconButton.outlined(
                        iconSize: 20,
                        icon: const Icon(Icons.add),
                        padding: EdgeInsets.zero,
                        onPressed: () => addAuthor(chronicle),
                      ),
                    )
                  ],
                ),
              ),
              Divider(height: chronicle.files.length <= 1 ? 2 : null),
              ...chronicle.files.indexedMap((fileName, index) {
                final fileType = fileTypeFromPath(fileName);
                return ListTile(
                  leading: Icon(
                    fileType.icon,
                    color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.6),
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(fileName)),
                      if(fileType.openable) const Padding(
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
                  onTap: fileType.openable ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChroniclePage(fileName, context, markdown: true),
                  )) : null,
                );
              }),
              if(chronicle.files.isEmpty) ListTile(
                iconColor: Theme.of(context).colorScheme.outline,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.add),
                    ),
                    Text(S(context).chronicleAddFiles, textAlign: TextAlign.center),
                  ],
                ),
                onTap: () => addFile(context, chronicle).then((_) => setState(() {})),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // TODO: confirm
  void createEmpty() async {
    setState(() {
      App.pedigree!.chronicle.add(Chronicle.empty());
      // controller.jumpTo(controller.position.maxScrollExtent);
    });
    // TODO: wait only for maxScrollExtent to refresh
    await Future.delayed(Durations.short1);
    controller.animateTo(
      controller.position.maxScrollExtent,
      duration: Durations.medium2,
      curve: standardEasing,
    );
    scheduleSave(context);
  }

  void addAuthor(Chronicle chronicle) async {
    // TODO: don't display people which are already authors
    final id = await PersonPicker.show(context);
    if(id == null) return;

    setState(() {
      if(chronicle.authors.contains(id)) {
        return;
      }
      chronicle.authors.add(id);
    });
    scheduleSave(context);
  }
}

Future<void> addFile(BuildContext context, Chronicle chronicle) async {
  // TODO: use allowedExtensions
  final picked = await FilePicker.platform.pickFiles(
    dialogTitle: S(context).chronicleFilePickerTitle,
    allowMultiple: true,
    initialDirectory: App.pedigree?.dir,
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
      final filePath = await showFileImportSheet(
        context,
        sourceFile.path,
        S(context).chronicleFileImportSheetTitle,
        S(context).chronicleFileImportSheetSuggestedDirectory,
      );
      if(filePath == null) {
        return;
      }
      file = File(filePath);
      await file.create(recursive: true);
      await sourceFile.copy(file.path);
    }

    // TODO: fix ordering
    chronicle.files.add(p.relative(file.path, from: App.pedigree!.dir));
    
    scheduleSave(context);
  }
}
