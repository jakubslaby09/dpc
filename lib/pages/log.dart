import 'dart:ui';

import 'package:dpc/strings/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LogPage extends StatelessWidget {
  const LogPage(this.log, {this.title, this.openedUnexpectedly = false, super.key});

  // TODO: add device info
  // TODO: encode markdown symbols
  Uri get reportUrl {
    String? shortenedLog;
    if(log.length > 6000) {
      shortenedLog = log.replaceRange(6000, log.length, "...");
    }
    return Uri.https("github.com", "/jakubslaby09/dpc/issues/new", {
      if(title != null) "title": title,
      // TODO: add device info
      "body": "```$title```\n```${shortenedLog ?? log}\n```",
    });
  }
  final String? title;
  final String log;
  final bool openedUnexpectedly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(openedUnexpectedly ? S(context).logTitleUnexpected : S(context).logTitle),
        backgroundColor: openedUnexpectedly ? Theme.of(context).colorScheme.error : null,
        foregroundColor: openedUnexpectedly ? Theme.of(context).colorScheme.onError : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            color: openedUnexpectedly ? Theme.of(context).colorScheme.onError : null,
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
                    TextSpan(text: log, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(172))),
                  ]
                ),
                style: const TextStyle(
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                  ],
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
          child: FloatingActionButton.extended(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            label: Text(S(context).logReportButton),
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => launchUrl(reportUrl),
          ),
        ),
      ),
    );
  }
}

void showExceptionPage(BuildContext context, [Exception? exception, StackTrace? trace]) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => LogPage(trace?.toString() ?? "", title: exception?.toString())
  ));
}

void showException(BuildContext context, String message, [Exception? exception, StackTrace? trace]) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    action: exception == null ? null : SnackBarAction(
      label: S(context).logDetailButton,
      onPressed: () => showExceptionPage(context, exception, trace),
    ),
  ));
}
