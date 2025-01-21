import 'package:dpc/main.dart';
import 'package:dpc/pages/screens/chronicle.dart';
import 'package:dpc/pages/screens/commit.dart';
import 'package:dpc/pages/screens/file.dart';
import 'package:dpc/pages/screens/list.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final List<Destination> _destinations = [
    const Destination(
      label: "Soubor",
      screen: FileScreen(),
      icon: Icons.file_open_outlined,
      activeIcon: Icons.file_open,
      
    ),
    Destination(
      label: "Seznam",
      screen: ListScreen(key: GlobalKey()),
      icon: Icons.list,
      needsPedigree: true,
    ),
    Destination(
      label: "Kronika",
      screen: ChronicleScreen(key: GlobalKey()),
      icon: Icons.history_edu,
      // activeIcon: Icons.library_books,
      needsPedigree: true,
    ),
    Destination(
      label: "Změny",
      screen: CommitScreen(key: GlobalKey()),
      icon: Icons.commit,
      needsPedigree: true,
    ),
  ];

  int _viewedScreen = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).orientation == Orientation.landscape) NavigationRail(
            labelType: NavigationRailLabelType.selected,
            destinations: _destinations.map((destination) => 
              NavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: destination.activeIcon != null ? Icon(destination.activeIcon) : null,
                label: Text(destination.label),
              ),
            ).toList(),
            selectedIndex: _viewedScreen,
            onDestinationSelected: (screen) => setState(() => _viewedScreen = screen),
          ),
          // const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            // width: MediaQuery.of(context).size.width - (MediaQuery.of(context).orientation == Orientation.landscape ? 80 : 0),
            child: App.pedigree != null || !_destinations[_viewedScreen].needsPedigree ? _destinations[_viewedScreen].screen : NoPedigreeScreen(
              onHome: () => setState(() => _viewedScreen = 0),
            ),
          ),
        ],
      ),
      bottomNavigationBar: OrientationBuilder(
        builder: (context, orientation) => Visibility(
          visible: orientation == Orientation.portrait,
          child: NavigationBar(
            // type: BottomNavigationBarType.fixed,
            // enableFeedback: true,
            destinations: _destinations.map((destination) => 
              NavigationDestination(
                label: destination.label,
                icon: Icon(destination.icon),
                selectedIcon: destination.activeIcon != null ? Icon(destination.activeIcon) : null,
              ),
            ).toList(),
            selectedIndex: _viewedScreen,
            onDestinationSelected: (screen) => setState(() => _viewedScreen = screen),
          ),
        ),
      ),
      floatingActionButton: (App.pedigree != null || !_destinations[_viewedScreen].needsPedigree) && _destinations[_viewedScreen].screen is FABScreen ? (_destinations[_viewedScreen].screen as FABScreen).fab(context) : null,
    );
  }
}

class NoPedigreeScreen extends StatelessWidget {
  const NoPedigreeScreen({required this.onHome, super.key});

  final Function() onHome;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Icon(
              Icons.sd_card_alert_rounded,
              size: 188,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
        const Text("Nemáte otevřený repozitář s rodokmenem.\nNa první stránce ho můžete otevřít, nebo založit nový.", textAlign: TextAlign.center),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: FilledButton.tonal(onPressed: onHome, child: const Text("Přejít na první stránku")),
        ),
      ],
    );
  }

}

class Destination {
  const Destination({ required this.screen, required this.label, required this.icon, this.activeIcon, this.needsPedigree = false });

  final Widget screen;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final bool needsPedigree;
}

abstract class FABScreen {
  Widget? fab(BuildContext context);
}