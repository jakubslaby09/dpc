import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CommitScreen extends StatelessWidget {
  const CommitScreen({super.key});

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
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.face_6_outlined),
                      title: Text("Lorem Ipsum"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: const Text("1. 1. 1999"),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () {},
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.face_3_outlined),
                      title: const Text("Dolor Sit"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outlined),
                        onPressed: () {},
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: const Text("1. 1. 1999"),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () {},
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: const Text("1. 1. 1989"),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () {},
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.face_6_outlined),
                      title: const Text("Amet Sit"),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () {},
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.face_3_outlined),
                      title: const Text("Consecteur Elit"),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () {},
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color.fromARGB(64, 128, 128, 128)),
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 8),
        //   child: Text("Soubory", style: Theme.of(context).textTheme.titleMedium),
        // ),
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