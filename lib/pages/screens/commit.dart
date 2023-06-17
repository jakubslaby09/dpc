import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CommitScreen extends StatefulWidget {
  const CommitScreen({super.key});

  @override
  State<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends State<CommitScreen> {
  @override
  Widget build(BuildContext context) {
    // ScaffoldMessenger.of(context).
    return ListView(
      children: [
        // Card(
        //   elevation: 0,
        //   shape: RoundedRectangleBorder(
        //     side: BorderSide(
        //       color: Theme.of(context).colorScheme.outline,
        //     ),
        //     borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(16)),
        //   ),
        //   child: Column(
          // children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ...?App.pedigree?.people.indexed.map(
                (person) => (person.$1, person.$2, person.$2.compare(App.unchangedPedigree!.people[person.$1]))
              ).where(
                (person) => !person.$3.same()
              ).map((person) => Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(person.$2.sex.icon),
                      title: Text(person.$2.name),
                      trailing: person.$3.name == null && person.$3.sex == null ? null : IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                            person.$2.sex = App.unchangedPedigree!.people[person.$1].sex;
                            person.$2.name = App.unchangedPedigree!.people[person.$1].name;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    if (person.$3.birth != null) ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: Text(person.$3.birth!),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                          person.$2.birth = App.unchangedPedigree!.people[person.$1].birth;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    if (person.$3.death != null) ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(person.$3.death!),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                          person.$2.death = App.unchangedPedigree!.people[person.$1].death;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    if (person.$3.death != null) ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(person.$3.death!),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                          person.$2.death = App.unchangedPedigree!.people[person.$1].death;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const Divider(color: Color.fromARGB(64, 128, 128, 128)),
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 8),
        //   child: Text("Soubory", style: Theme.of(context).textTheme.titleMedium),
        // ),
        // TODO: implement files
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          // isThreeLine: true,
          title: const Text("lorem ipsum - dolor.pdf"),
          subtitle: const Text("3.2MiB"),
          trailing: IconButton(
            icon: const Icon(Icons.backspace_outlined),
            onPressed: () {},
          ),
        ),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          // isThreeLine: true,
          title: const Text("sit amet.jpg"),
          subtitle: const Text("53KiB"),
          trailing: IconButton(
            icon: const Icon(Icons.backspace_outlined),
            onPressed: () {},
          ),
          onTap: () {},
        ),
      ],
    );
  }
}