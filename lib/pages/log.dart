import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LogPage extends StatelessWidget {
  const LogPage(this.log, {this.title, super.key});

  // TODO: add device info
  Uri get reportUrl => Uri.https("github.com", "/jakubslaby09/dpc/issues/new", {
    if(title != null) "title": title,
    "body": "```$title```\n```$log```",
  });
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
                      text: title != null ? "$title\n" : "",
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
      floatingActionButton: FutureBuilder(
        future: canLaunchUrl(reportUrl),
        builder: (context, canLaunch) => Visibility(
          visible: canLaunch.data ?? false,
          child: FloatingActionButton(
            child: const Icon(Icons.bug_report_outlined),
            onPressed: () => launchUrl(reportUrl),
          ),
        ),
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