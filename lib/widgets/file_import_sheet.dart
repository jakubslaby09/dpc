import 'dart:async';
import 'dart:io';

import 'package:dpc/main.dart';
import 'package:dpc/strings/strings.dart';
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
            decoration: InputDecoration(
              icon: const Icon(Icons.insert_drive_file_outlined),
              labelText: S(context).importFileSourceFile,
              border: const OutlineInputBorder(),
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
              labelText: S(context).importFileDestFile,
              errorText: errorText,
              border: const OutlineInputBorder(),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.file_open_outlined),
                  onPressed: () => pickPath(S(context)),
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
                  label: Text(S(context).importFileCancel),
                ),
              ),
              const VerticalDivider(),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    validate(S(context));
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
                  label: Text(S(context).importFileConfirm),
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

  void pickPath(S s) async {
    final result = await FilePicker.platform.saveFile(
      initialDirectory: App.pedigree!.dir,
      dialogTitle: s.importFileDialogTitle(p.basename(widget.sourcePath)),
      fileName: p.basename(widget.sourcePath),
      allowedExtensions: [p.extension(widget.sourcePath)],
    );

    if(result == null) {
      return;
    }

    widget.pathController.text = p.relative(result, from: App.pedigree!.dir);
  }

  validate(S s) {
    final newFile = File(pickedPath);
    if(newFile.existsSync()) {
      errorText = s.importFileDestinationAlreadyExists;
      return;
    }
    final sourceFile = File(widget.sourcePath);
    if(!sourceFile.existsSync()) {
      errorText = s.importFileSourceDoesNotExist;
      return;
    }
    if(!p.isWithin(App.pedigree!.dir, newFile.path)) {
      errorText = s.importFileDestOutsideRepo;
      return;
    }
    if(p.extension(newFile.path) != p.extension(widget.sourcePath)) {
      errorText = s.importFileInvalidExt(p.extension(widget.sourcePath));
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