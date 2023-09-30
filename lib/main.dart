import 'dart:ffi';
import 'dart:io';

import 'package:dpc/dpc.dart';
import 'package:dpc/pages/preferences.dart';
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';
import 'package:path/path.dart';

import 'pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  App.prefs = await initPrefs();

  const App app = App();
  runApp(app);
}

class App extends StatelessWidget {
  const App({super.key});

  static late Preferences prefs;
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
  static Pedigree? unchangedPedigree;
  static Pedigree? pedigree;
  static final Libgit2 git = App.initLibgit2();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode themeMode, __) => MaterialApp(
        // title: 'Flutter Demo',
        theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        // primarySwatch: Colors.blue,
          useMaterial3: true,
          splashFactory: InkRipple.splashFactory,
          //TODO: add to settings
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBA9666)).copyWith(
            // 669DBA
            // FFD8A6
            // 6E5431
            // primary: const Color(0xFF26546E),
            // secondaryContainer: const Color(0xFF669DBA),
            // onSecondaryContainer: Colors.white,
          ),
        ),
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: const HomePage(),
      )
    );
  }

  static Libgit2 initLibgit2() {
    final String libraryPath;
    if(Platform.isAndroid) {
      libraryPath = "libgit2.so";
    } else {
      // TODO: debug
      libraryPath = "lib/libgit2/build/x86_64/libgit2.so";
    }
    Libgit2 git = Libgit2(DynamicLibrary.open(libraryPath));
    git.git_libgit2_init();

    return git;
  }
}

class Result<T, E> {
  Result(this.value);
  Result.error(this.error);

  T? value;
  E? error;

  bool isOk() {
    return value != null;
  }
}

extension ListExtension<T> on List<T> {
  List<T> safeSublist(int start, int? end) {
    if(end != null && end < start) {
      return [];
    }
    if (length >= (end ?? start)) {
      return sublist(start, end);
    }
    if (length >= start) {
      return sublist(start);
    }

    return this;
  }

  T? safeFirstWhere(bool Function(T) test, {T? or, T Function()? orElse}) {
    try {
      return firstWhere(test as dynamic, orElse: orElse);
    } on StateError catch (_) {
      return or;
    }
  }
}

extension IterableExtension<E> on Iterable<E> {
  Iterable<T> indexedMap<T>(T Function(E element, int index) toElement) {
    return indexed.map<T>((e) => toElement(e.$2, e.$1));
  }
  
  Iterable<T> indexedFilteredMap<T>(T? Function(E element, int index) toElement) {
    return indexed.map<T?>((e) => toElement(e.$2, e.$1)).where((e) => e != null).cast();
  }
}