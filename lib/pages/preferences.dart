import 'dart:math';

import 'package:dpc/dpc.dart';
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
  late AnimationController brokenRecentsSwitchControler = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: _maxRecents > 1 ? 1 : 0,
  );

  int _maxRecents = App.prefs.maxRecentFiles;
  int _saveDelaySeconds = App.prefs.saveDelaySeconds;

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
          SwitchListTile(
            value: App.themeNotifier.value == ThemeMode.system,
            onChanged: (auto) => setState(() {
              if (auto) {
                changeThemeMode(ThemeMode.system, context);
              } else if (Theme.of(context).brightness == Brightness.light) {
                changeThemeMode(ThemeMode.light, context);
              } else {
                changeThemeMode(ThemeMode.dark, context);
              }

              if (auto) {
                themeModeSwitchControler.reverse();
              } else {
                themeModeSwitchControler.forward();
              }
            }),
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
              onChanged: (dark) => changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light, context),
              title: const Text("Tmavý režim"),
              secondary: const Icon(Icons.lightbulb_outline),
            ),
          ),
          SwitchListTile(
            value: App.prefs.filledAvatarIcons,
            onChanged: (value) => setState(() => App.prefs.filledAvatarIcons = value),
            title: const Text("Barevné ikony osob"),
            secondary: const Icon(Icons.face_retouching_natural_outlined),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("Nedávno otevřené soubory", style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: Row(
              children: [
                const Text("Kapacita"),
                Expanded(
                  child: Slider(
                    value: _maxRecents.toDouble(),
                    max: 20,
                    min: 1,
                    divisions: 19,
                    label: _maxRecents == 1 ? " Nezobrazovat " : _maxRecents.toString(),
                    onChanged: (value) => setState(() {
                      if (value > 1) {
                        brokenRecentsSwitchControler.forward();
                      } else {
                        brokenRecentsSwitchControler.reverse();
                      }
                      // if ((_maxRecents > 1) == (value > 1)) {
                      // }

                      _maxRecents = value.floor();
                    }),
                    onChangeEnd: (value) {
                      App.prefs.maxRecentFiles = value.floor();
                      _maxRecents = App.prefs.maxRecentFiles;
                    },
                  ),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: brokenRecentsSwitchControler,
              curve: Curves.easeInOutCubic,
            ),
            child: SwitchListTile(
              value: App.prefs.saveBrokenRecentFiles,
              onChanged: (value) => setState(() => App.prefs.saveBrokenRecentFiles = value),
              title: const Text("Pamatovat si rozbité soubory"),
              secondary: const Icon(Icons.broken_image_outlined),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("Změny", style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Row(
              children: [
                const Text("Prodleva před uložením"),
                Expanded(
                  child: Slider(
                    value: _saveDelaySeconds.toDouble(),
                    max: 30,
                    min: 0,
                    divisions: 12,
                    label: _saveDelaySeconds == 0 ? " Ukládat okamžitě " : "${_saveDelaySeconds}s",
                    onChanged: (value) => setState(() {
                      _saveDelaySeconds = value.floor();
                    }),
                    onChangeEnd: (value) {
                      App.prefs.saveDelaySeconds = value.floor();
                      _saveDelaySeconds = App.prefs.saveDelaySeconds;
                    },
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            value: App.prefs.autoUpgradeFiles,
            onChanged: (value) => setState(() => App.prefs.autoUpgradeFiles = value),
            title: const Text("Bez ptaní upgradovat soubory"),
            secondary: const Icon(Icons.upgrade),
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
    _sharedPrefs!.setStringList(_recentFilesKey, value.safeSublist(0, maxRecentFiles));
  }
  
  static const _maxRecentFilesKey = "maxRecentFiles";
  int get maxRecentFiles => max(1, _sharedPrefs!.getInt(_maxRecentFilesKey) ?? 3);
  set maxRecentFiles(int value) {
    _sharedPrefs!.setInt(_maxRecentFilesKey, value);
    recentFiles = recentFiles.safeSublist(0, value);
  }
  
  static const _saveDelaySecondsKey = "saveDelaySeconds";
  int get saveDelaySeconds => max(0, _sharedPrefs!.getInt(_saveDelaySecondsKey) ?? 5);
  set saveDelaySeconds(int value) {
    _sharedPrefs!.setInt(_saveDelaySecondsKey, value);
  }
  
  static const _saveBrokenRecentFilesKey = "saveBrokenRecentFiles";
  bool get saveBrokenRecentFiles => _sharedPrefs!.getBool(_saveBrokenRecentFilesKey) ?? false;
  set saveBrokenRecentFiles(bool value) {
    _sharedPrefs!.setBool(_saveBrokenRecentFilesKey, value);
  }
  
  static const _autoUpgradeFilesKey = "autoUpgradeFiles";
  bool get autoUpgradeFiles => _sharedPrefs!.getBool(_autoUpgradeFilesKey) ?? false;
  set autoUpgradeFiles(bool value) {
    _sharedPrefs!.setBool(_autoUpgradeFilesKey, value);
  }
  
  static const _filledAvatarIconsKey = "filledAvatarIcons";
  bool get filledAvatarIcons => _sharedPrefs!.getBool(_filledAvatarIconsKey) ?? true;
  set filledAvatarIcons(bool value) {
    _sharedPrefs!.setBool(_filledAvatarIconsKey, value);
  }
}