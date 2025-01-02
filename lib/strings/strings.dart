import 'dart:async';

import 'package:dpc/strings/cz.dart';
import 'package:dpc/strings/de.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// A map of supported locales.
final supportedLocales = <Locale, S>{
  Locale('en'): S(),
  Locale('cs'): Czech(),
  Locale('de'): Deutsch(),
};

// English
class S {
  String get noFileOpenNotice => "No file open!";
  String get noFileOpenButton => "Go to files";

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S) ?? S();
  }
  static const LocalizationsDelegate<S> delegate = _Delegate();
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}

class _Delegate extends LocalizationsDelegate<S> {
  const _Delegate();
  @override
  Future<S> load(Locale locale) {
    final match = supportedLocales[locale];
    if(match == null) {
      throw FlutterError(
        "Failed to load an unsupported locale: $locale"
        "Please report to https://github.com/jakubslaby09/dpc/issues/new"
      );
    }
    return SynchronousFuture(match);
  }
  @override
  bool isSupported(Locale locale) => supportedLocales.containsKey(locale);
  @override
  bool shouldReload(_Delegate _) => false;
}