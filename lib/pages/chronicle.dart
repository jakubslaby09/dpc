import 'dart:io';

import 'package:dpc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;

class ChroniclePage extends StatelessWidget {
  ChroniclePage(this.relativePath, BuildContext context, {super.key, this.markdown = false}) {
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
        actions: [
          IconButton(
            style: const ButtonStyle(
              fixedSize: MaterialStatePropertyAll(Size.square(50))
            ),
            icon: const Icon(Icons.edit_note),
            // TODO: insert a comment at cursor
            onPressed: null,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText.rich(
            TextSpan(
              children: formatComments(string),
            )
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  // TODO: implement block comments
  List<InlineSpan> formatComments(String string) {
    List<InlineSpan> output = [];

    int startChar = 0;
    bool insert = false;
    for ((int, int) c in string.codeUnits.indexed) {
      final String char = String.fromCharCode(c.$2);
      if("<>".contains(char) || c.$1 + 1 == string.length) {
        final String substring = string.substring(startChar, c.$1);

        if(insert) {
          output.add(WidgetSpan(
            child: Card(
              margin: const EdgeInsets.all(0),
              child: markdown ? MarkdownBody(data: substring) : Text(substring)
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
      }

      if(char == "<") {
        insert = true;
      } else if (char == ">") {
        insert = false;
      }
    }

    return output;
  }
}