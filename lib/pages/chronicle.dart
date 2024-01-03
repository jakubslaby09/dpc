import 'dart:io';

import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;

final RegExp authorPattern = RegExp(r"\[(\d*?)\]\((.*?)\):?\n?([\S\s]*)");

class ChroniclePage extends StatelessWidget {
  ChroniclePage(this.relativePath, BuildContext context, {super.key, this.markdown = false}) {
    // TODO: don't add that subdirectory in dpc v5
    // TODO: async with loading widget and error handling
    string = File(p.join(App.pedigree!.dir, "kronika", relativePath)).readAsStringSync();
  }

  // final Chronicle chronicle;
  final String relativePath;
  final bool markdown;
  late final String string;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(relativePath),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText.rich(
            TextSpan(
              children: formatText(string, context),
            )
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit_outlined),
        // TODO: insert a comment at cursor
        onPressed: null,
      ),
    );
  }

  List<InlineSpan> formatText(String string, BuildContext context) {
    List<InlineSpan> output = [];

    int startChar = 0;
    bool inline = false;
    bool block = false;
    for ((int, int) c in string.codeUnits.indexed) {
      final String char = String.fromCharCode(c.$2);
      if("<>".contains(char) && !block || block && char == "\n" && c.$1 + 1 < string.codeUnits.length && String.fromCharCode(string.codeUnits[c.$1 + 1]) != ">" || c.$1 == string.length - 1) {
        String substring = string.substring(startChar, c.$1);
        Person? author;
        String? authorString;
        if(inline || block) {
          final match = authorPattern.firstMatch(substring);
          if(match != null) {
            substring = match.group(3) ?? substring;
            author = App.pedigree?.people[int.parse(match.group(1)!)];
            authorString = match.group(2);
          }
        }

        if(inline) {
          output.add(WidgetSpan(
            child: Card(
              margin: const EdgeInsets.all(0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(author != null) Text(authorString!, style: Theme.of(context).textTheme.labelSmall),
                  if(author != null) Icon(author.sex.icon),
                  Flexible(child: markdown ? MarkdownBody(data: substring) : Text(substring)),
                ],
              ),
            )
          ));
        } else if(block) {
          substring = substring.replaceAll("\n>", "\n");
          output.add(WidgetSpan(
            child: Row(
              children: [
                if(author != null) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: Column(
                    children: [
                      Icon(author.sex.icon),
                      Text(authorString!, style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                Card(
                  child: markdown ? MarkdownBody(data: substring) : Text(substring),
                ),
              ],
            )
          ));
        } else {
          if(markdown) {
            output.add(WidgetSpan(
              child: MarkdownBody(data: substring),
            ));
          } else {
            output.add(TextSpan(text: substring));
          }
        }

        startChar = c.$1 + 1;
        switch (char) {
          case "<":
            inline = true;
          case ">":
            if(inline) {
              inline = false;
            } else {
              block = true;
            }
          case "\n":
            block = false;
        }
      }

    }

    return output;
  }
}