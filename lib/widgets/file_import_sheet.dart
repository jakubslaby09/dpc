import 'dart:async';
import 'dart:io';

import 'package:dpc/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileImportSheet extends StatefulWidget {
  FileImportSheet({super.key, required this.sourcePath, this.message, String? suggestedDirectory})
  : pathController = TextEditingController(
      text: p.join(suggestedDirectory ?? "", p.basename(sourcePath)),
    );

  final String? message;
  final String sourcePath;
  final TextEditingController pathController;

  @override
  State<FileImportSheet> createState() => _FileImportSheetState();
}

class _FileImportSheetState extends State<FileImportSheet> {
  String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if(widget.message != null) Padding(
          padding: const EdgeInsets.only(right: 24, left: 24, top: 24),
          child: Text(widget.message!, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24),
          child: TextFormField(
            decoration: const InputDecoration(
              icon: Icon(Icons.insert_drive_file_outlined),
              labelText: "Zdrojový soubor",
              border: OutlineInputBorder(),
            ),
            enabled: false,
            initialValue: widget.sourcePath,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          child: TextFormField(
            decoration: InputDecoration(
              icon: const Icon(Icons.file_copy_outlined),
              labelText: "Soubor v repozitáři",
              errorText: errorText,
              border: const OutlineInputBorder(),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.file_open_outlined),
                  onPressed: pickPath,
                ),
              ),
            ),
            autofocus: true,
            controller: widget.pathController,
            onChanged: (_) => setState(() {
              errorText = null;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text("Zahodit"),
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    validate();
                    if(errorText != null) {
                      setState(() {});
                      return;
                    }
                    Navigator.of(context).pop(pickedPath);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text("Přidat do kroniky"),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  String get pickedPath {
    return p.join(App.pedigree!.dir, widget.pathController.text);
  }

  void pickPath() async {
    final result = await FilePicker.platform.saveFile(
      initialDirectory: App.pedigree!.dir,
      dialogTitle: "Vybrat umístění pro soubor ${p.basename(widget.sourcePath)}",
      fileName: p.basename(widget.sourcePath),
      allowedExtensions: [p.extension(widget.sourcePath)],
    );

    if(result == null) {
      return;
    }

    widget.pathController.text = p.relative(result, from: App.pedigree!.dir);
  }

  validate() {
    final newFile = File(pickedPath);
    if(newFile.existsSync()) {
      errorText = "Takový soubor již existuje";
      return;
    }
    final sourceFile = File(widget.sourcePath);
    if(!sourceFile.existsSync()) {
      errorText = "Soubor, který jste vybrali, již neexistuje. Nesmazali jste ho?";
      return;
    }
    if(!p.isWithin(App.pedigree!.dir, newFile.path)) {
      errorText = "Nový soubor se musí nacházet v repozitáři kroniky";
      return;
    }
    if(p.extension(newFile.path) != p.extension(widget.sourcePath)) {
      errorText = "Přípona souboru se neshoduje. Zkuste ji změnit na ${p.extension(widget.sourcePath)}";
      return;
    }

    errorText = null;
  }
}

// TODO: use named arguments
Future<String?> showFileImportSheet(BuildContext context, String sourcePath, [String? message, String? suggestedDirectory]) {
  return showModalBottomSheet<String>(
    context: context,
    // showDragHandle: true,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: FileImportSheet(
        sourcePath: sourcePath,
        suggestedDirectory: suggestedDirectory,
        message: message,
      ),
    ),
  );
}