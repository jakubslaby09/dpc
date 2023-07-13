import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChronicleScreen extends StatelessWidget {
  const ChronicleScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    if(App.pedigree == null) {
      // TODO: make a widget for it
      return Text("none");
    }

    return ListView(
      children: App.pedigree!.chronicle.map((chronicle) => Padding(
        padding: const EdgeInsets.all(8),
        child: Card(
          // shape: RoundedRectangleBorder(
          //   side: BorderSide(
          //     color: Theme.of(context).colorScheme.outline,
          //   ),
          //   borderRadius: const BorderRadius.all(Radius.circular(12)),
          // ),
          // elevation: 0,
          child: Column(
            children: [
              ListTile(
                leading: Icon(chronicle.mime.icon, color: Theme.of(context).colorScheme.outline),
                title: Text(chronicle.name),
                subtitle: Row(
                  // TODO: fix overflow
                  children: chronicle.authors.map((e) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onBackground,
                      )
                    ),
                    child: Row(
                      children: [
                        // TODO: make a more robust person lookup fuction
                        Icon(App.pedigree!.people[e.round()].sex.icon),
                        Padding(
                          padding: const EdgeInsets.only(left: 2, right: 8),
                          child: Text(App.pedigree!.people[e.round()].name),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const Divider(),
              ...chronicle.files.map((fileName) => ListTile(
                // leading: Icon(chronicle.mime.icon, color: Theme.of(context).colorScheme.outline),
                title: Text(fileName),
                trailing: chronicle.mime.openable ? const Icon(Icons.navigate_next) : null,
                onTap: chronicle.mime.openable ? () {
                  // TODO: make a screen for md files
                } : null,
              ))
            ],
          ),
        ),
      )).toList(),
    );
  }
}