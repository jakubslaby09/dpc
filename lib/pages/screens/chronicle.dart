import 'package:dpc/autosave.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/chronicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChronicleScreen extends StatefulWidget {
  const ChronicleScreen({super.key});

  @override
  State<ChronicleScreen> createState() => _ChronicleScreenState();
}

class _ChronicleScreenState extends State<ChronicleScreen> {
  @override
  Widget build(BuildContext context) {
    if(App.pedigree == null) {
      // TODO: make a widget for it
      return Text("none");
    }

    return ListView(
      children: App.pedigree!.chronicle.indexedMap((chronicle, chronicleIndex) => Padding(
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
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text(chronicle.name)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // TODO: implement adding files a to chronicle
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined),
                      onPressed: () => setState(() {
                        App.pedigree!.chronicle.removeAt(chronicleIndex);
                        scheduleSave(context);
                      }),
                    ),
                  ],
                ),
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
                title: Row(
                  children: [
                    Text(fileName),
                    if(chronicle.mime.openable) const Icon(Icons.navigate_next),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        // TODO: implement removing files from a chronicle
                      },
                    )
                  ],
                ),
                onTap: chronicle.mime.openable ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ChroniclePage(fileName, context, markdown: chronicle.mime == ChronicleMime.textMarkdown),
                )) : null,
              ))
            ],
          ),
        ),
      )).toList(),
    );
  }
}