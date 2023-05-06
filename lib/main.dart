import 'package:dpc/dpc.dart';
import 'package:dpc/pages/preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home.dart';

void main() async {
  App.prefs = await initPrefs();

  const App app = App();
  runApp(app);
}

class App extends StatelessWidget {
  const App({super.key});

  static late Preferences prefs;
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
  static Pedigree? pedigree;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode themeMode, __) => MaterialApp(
        title: 'Flutter Demo',
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
        ),
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: const HomePage(),
      )
    );
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

List<dynamic> safeSublist(List<dynamic> list, int start, int? end) {
  assert(start <= (end ?? start));
  if (list.length >= (end ?? start)) {
    return list.sublist(start, end);
  } else if (list.length >= start) {
    return list.sublist(start);
  } else {
    return list;
  }
}