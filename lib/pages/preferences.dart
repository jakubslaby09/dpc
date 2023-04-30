import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<StatefulWidget> createState() => _PreferencesPageState();

}

class _PreferencesPageState extends State<PreferencesPage> with TickerProviderStateMixin {
  late AnimationController themeModeSwitchControler = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: App.themeNotifier.value == ThemeMode.system ? 0 : 1,
  );

  int _maxRecents = App.prefs.maxRecentFiles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Předvolby"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("Vzhled", style: Theme.of(context).textTheme.titleMedium),
          ),
          // const Divider(),
          SwitchListTile(
            value: App.themeNotifier.value == ThemeMode.system,
            onChanged: (auto) {
              if (auto) {
                changeThemeMode(ThemeMode.system, context);
              } else if (Theme.of(context).brightness == Brightness.light) {
                changeThemeMode(ThemeMode.light, context);
              } else {
                changeThemeMode(ThemeMode.dark, context);
              }

              if (auto) {
                themeModeSwitchControler.reverse(from: 1);
              } else {
                themeModeSwitchControler.forward(from: 0);
              }
            },
            title: const Text("Tmavý režim dle systému"),
            secondary: const Icon(Icons.auto_awesome),
          ),
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: themeModeSwitchControler,
              curve: Curves.easeInOutCubic,
            ),
            child: SwitchListTile(
              value: App.themeNotifier.value == ThemeMode.dark,
              onChanged: (dark) {
                changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light, context);
                // App.themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
                // dark = App.themeNotifier.value == ThemeMode.system ? false : App.themeNotifier.value == ThemeMode.dark;
              },
              title: const Text("Tmavý režim"),
              secondary: const Icon(Icons.lightbulb_outline),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("Chování", style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Text("Nedávno otevřené soubory", style: Theme.of(context).textTheme.labelLarge),
          ),
          Slider(
            value: _maxRecents.toDouble(),
            max: 20,
            min: 1,
            divisions: 19,
            label: _maxRecents == 1 ? " Nezobrazovat " : _maxRecents.toString(),
            onChanged: (value) => setState(() => _maxRecents = value.floor()),
            onChangeEnd: (value) {
              App.prefs.maxRecentFiles = value.floor();
              setState(() => _maxRecents = App.prefs.maxRecentFiles); // dbg
            },
          ),
        ],
      ),
    );
  }

  void changeThemeMode(ThemeMode value, BuildContext context) {
    App.themeNotifier.value = value;
    App.prefs.themeMode = value;
  }
}

Future<Preferences> initPrefs() async {
  Preferences prefs = Preferences(await SharedPreferences.getInstance());

  App.themeNotifier.value = prefs.themeMode;
  
  return prefs;
}

class Preferences {
  Preferences(this._sharedPrefs);

  final SharedPreferences? _sharedPrefs;
  
  static const _themeModeKey = "themeMode";
  final _themeModeValues = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];
  ThemeMode get themeMode => _themeModeValues[_sharedPrefs!.getInt(_themeModeKey) ?? 0];
  set themeMode(ThemeMode value) {
    _sharedPrefs!.setInt(_themeModeKey, _themeModeValues.indexOf(value));
  }
  
  static const _recentFilesKey = "recentFiles";
  List<String> get recentFiles => _sharedPrefs!.getStringList(_recentFilesKey) ?? [];
  set recentFiles(List<String> value) {
    _sharedPrefs!.setStringList(_recentFilesKey, safeSublist(value, 0, maxRecentFiles) as List<String>);
  }
  
  static const _maxRecentFilesKey = "maxRecentFiles";
  int get maxRecentFiles => max(1, _sharedPrefs!.getInt(_maxRecentFilesKey) ?? 3);
  set maxRecentFiles(int value) {
    _sharedPrefs!.setInt(_maxRecentFilesKey, value);
    // recentFiles = safeSublist(recentFiles, 0, value) as List<String>;
  }
}