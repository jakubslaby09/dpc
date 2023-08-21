import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogPage extends StatelessWidget {
  const LogPage(this.log, {super.key});

  final String log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Záznamy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () => Clipboard.setData(ClipboardData(text: log)),
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                log,
                style: const TextStyle(
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                  ]
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.bug_report_outlined),
        onPressed: () {}, // TODO: redirect to a new Github issue page
      ),
    );
  }
}

// TODO: accept a stack trace
void showException(BuildContext context, String message, [Exception? exception]) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    action: exception != null ? SnackBarAction(
      label: "Zobrazit detaily",
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LogPage(exception.toString())
      )),
      // onPressed: () {},
    ) : null,
  ));
}