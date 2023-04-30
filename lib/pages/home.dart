import 'package:dpc/pages/screens/file.dart';
import 'package:dpc/pages/screens/list.dart';
import 'package:flutter/material.dart';
import 'preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final List<Widget> _screens = [
    const FileScreen(),
    const ListScreen(),
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
            destinations: const [
              NavigationRailDestination(
                label: Text("Soubor"),
                icon: Icon(Icons.file_open_outlined),
                // activeIcon: Icon(Icons.file_open),
              ),
              NavigationRailDestination(
                label: Text("Seznam"),
                icon: Icon(Icons.list),
              ),
              // NavigationRailDestination(
              //   label: Text("Rodokmen"),
              //   icon: Icon(Icons.auto_stories),
              //   // activeIcon: Icon(Icons.auto_stories_outlined),
              // ),
              // NavigationRailDestination(
              //   label: Text("Kronika"),
              //   icon: Icon(Icons.source_outlined),
              //   // activeIcon: Icon(Icons.source),
              // ),
            ],
            selectedIndex: _viewedScreen,
            onDestinationSelected: (screen) => setState(() => _viewedScreen = screen),
          ),
          // const VerticalDivider(thickness: 1, width: 1),
          SizedBox(
            width: MediaQuery.of(context).size.width - (MediaQuery.of(context).orientation == Orientation.landscape ? 80 : 0),
            child: _screens[_viewedScreen],
          ),
        ],
      ),
      
      bottomNavigationBar: OrientationBuilder(
        builder: (context, orientation) => Visibility(
          visible: orientation == Orientation.portrait,
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                label: "Soubor",
                icon: Icon(Icons.file_open_outlined),
                activeIcon: Icon(Icons.file_open),
              ),
              BottomNavigationBarItem(
                label: "Seznam",
                icon: Icon(Icons.list),
              ),
              // BottomNavigationBarItem(
              //   label: "Rodokmen",
              //   icon: Icon(Icons.auto_stories),
              //   activeIcon: Icon(Icons.auto_stories_outlined),
              // ),
              // BottomNavigationBarItem(
              //   label: "Kronika",
              //   icon: Icon(Icons.source_outlined),
              //   activeIcon: Icon(Icons.source),
              // ),
            ],
            currentIndex: _viewedScreen,
            onTap: (screen) => setState(() => _viewedScreen = screen),
          ),
        ),
      ),
    );
  }
}
