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
  static const List<Destination> _destinations = [
    Destination(
      label: "Soubor",
      screen: FileScreen(),
      icon: Icons.file_open_outlined,
      activeIcon: Icons.file_open,
    ),
    Destination(
      label: "Seznam",
      screen: ListScreen(),
      icon: Icons.list,
    ),
    Destination(
      label: "Změny",
      screen: CommitScreen(),
      icon: Icons.commit,
    ),
  ];

  int _viewedScreen = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: PreferredSize(
      //   preferredSize: const Size.fromHeight(80),
      //   child: OrientationBuilder(
      //     builder: (context, orientation) => Visibility(
      //       visible: orientation == Orientation.portrait,
      //       child: AppBar(
      //         title: const Text("Digitální kronika"), // TODO: Display opened pedigree name
      //         leading: IconButton(
      //           icon: const Icon(Icons.settings_outlined),
      //           onPressed: () => Navigator.of(context).push(MaterialPageRoute(
      //             builder: (context) => PreferencesPage(),
      //           )),
      //         ),
      //       ),
      //     ),
      //   ),
      // ),
      body: Row(
        children: [
          if (MediaQuery.of(context).orientation == Orientation.landscape) NavigationRail(
            labelType: NavigationRailLabelType.selected,
            destinations: _destinations.map((destination) => 
              NavigationRailDestination(
                icon: Icon(destination.icon),
                label: Text(destination.label),
              ),
            ).toList(),
            selectedIndex: _viewedScreen,
            onDestinationSelected: (screen) => setState(() => _viewedScreen = screen),
          ),
          // const VerticalDivider(thickness: 1, width: 1),
          SizedBox(
            width: MediaQuery.of(context).size.width - (MediaQuery.of(context).orientation == Orientation.landscape ? 80 : 0),
            child: _destinations[_viewedScreen].screen,
          ),
        ],
      ),
      bottomNavigationBar: OrientationBuilder(
        builder: (context, orientation) => Visibility(
          visible: orientation == Orientation.portrait,
          child: BottomNavigationBar(
            items: _destinations.map((destination) => 
              BottomNavigationBarItem(
                label: destination.label,
                icon: Icon(destination.icon),
                activeIcon: destination.activeIcon != null ? Icon(destination.activeIcon) : null,
              ),
            ).toList(),
            currentIndex: _viewedScreen,
            onTap: (screen) => setState(() => _viewedScreen = screen),
          ),
        ),
      ),
      floatingActionButton: _destinations[_viewedScreen].screen is FABScreen ? (_destinations[_viewedScreen].screen as FABScreen).fab : null,
    );
  }
}

class Destination {
  const Destination({ required this.screen, required this.label, required this.icon, this.activeIcon, });

  final Widget screen;
  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

abstract class FABScreen {
  Widget get fab;
}