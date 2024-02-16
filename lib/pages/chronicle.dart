import 'dart:io';

import 'package:dpc/main.dart';
import 'package:dpc/pages/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

final RegExp authorPattern = RegExp(r"\[(\d*?)\]\((.*?)\):?\n?([\S\s]*)");

class ChroniclePage extends StatefulWidget {
  ChroniclePage(this.relativePath, BuildContext context, {super.key}) {
    file = File(p.join(App.pedigree!.dir, relativePath));
  }

  final String relativePath;
  static final markdownDocument = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );
  late final File file;

  @override
  State<ChroniclePage> createState() => _ChroniclePageState();
}

class _ChroniclePageState extends State<ChroniclePage> {
  final ScrollController scrollController = ScrollController();
  late final Future<QuillController> controller = readFile();
  bool markdown = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.relativePath),
        // actions: const [
        //   IconButton(
        //     style: ButtonStyle(
        //       fixedSize: MaterialStatePropertyAll(Size.square(50))
        //     ),
        //     icon: Icon(Icons.edit_note),
        //     onPressed: null,
        //   )
        // ],
      ),
      // TODO: loading widget and better error handling
      body: FutureBuilder(
        future: controller,
        builder: (context, controller) => !controller.hasData ? errorWidget(controller.error) : Column(
          children: [
            // TODO: custom toolbar
            QuillToolbar.simple(configurations: QuillSimpleToolbarConfigurations(
              controller: controller.requireData,
              showFontFamily: false,
              showFontSize: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              headerStyleType: HeaderStyleType.buttons,
              showListCheck: false,
              showSubscript: false,
              showSuperscript: false,
              showBoldButton: markdown,
              showItalicButton: markdown,
              showUnderLineButton: markdown,
              showStrikeThrough: markdown,
              showInlineCode: markdown,
              showClearFormat: markdown,
              showHeaderStyle: markdown,
              showListNumbers: markdown,
              showListBullets: markdown,
              showCodeBlock: markdown,
              showQuote: markdown,
              showIndent: markdown,
              showLink: markdown,
            )),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 75),
                  child: QuillEditor(
                    configurations: QuillEditorConfigurations(controller: controller.requireData),
                    scrollController: ScrollController(),
                    focusNode: FocusNode(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save_outlined),
        onPressed: () async {
          try {
            final String string;
            if(markdown) {
              string = DeltaToMarkdown().convert((await controller).document.toDelta());
            } else {
              string = (await controller).document.toPlainText();
            }
          } on Exception catch (e, t) {
            showException(context, "Nelze uložit Vaše změny.", e ,t);
          }
        },
      ),
    );
  }

  Widget errorWidget(Object? error) {
    // TODO
    return Text("chyba: $error");
  }

  Future<QuillController> readFile() async {
    final string = await widget.file.readAsString();
    markdown = widget.file.path.endsWith(".md");
    final Delta delta;
    if(markdown) {
      delta = MarkdownToDelta(
        markdownDocument: ChroniclePage.markdownDocument
      ).convert(string);
    } else {
      delta = Delta.fromOperations([Operation.insert(string)]);
    }
    return QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }
}