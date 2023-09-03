import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogPage extends StatelessWidget {
  const LogPage(this.log, {this.title, super.key});

  final String? title;
  final String log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Záznamy"),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () => Clipboard.setData(ClipboardData(text: "${title ?? ""}\n$log")),
          )
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextSpan(text: log, style: TextStyle(color: Theme.of(context).colorScheme.onBackground.withAlpha(172))),
                  ]
                ),
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

void showException(BuildContext context, String message, [Exception? exception, StackTrace? trace]) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    action: exception != null ? SnackBarAction(
      label: "Zobrazit detaily",
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => LogPage(trace.toString(), title: exception.toString())
      )),
      // onPressed: () {},
    ) : null,
  ));
}