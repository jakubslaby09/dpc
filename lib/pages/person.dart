import 'dart:io';
import 'dart:math';
import 'package:dpc/autosave.dart';
import 'package:path/path.dart' as p;

import 'package:dpc/main.dart';
import 'package:dpc/widgets/person_field.dart';
import 'package:flutter/material.dart';

import '../dpc.dart';

class PersonPage extends StatefulWidget {
  const PersonPage(this.id, {super.key});
  final int id;

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  late final Person person = App.pedigree!.people[widget.id];
  late final Person? unchangedPerson = App.unchangedPedigree!.people.elementAtOrNull(widget.id);

  late TextEditingController nameController = TextEditingController(text: person.name);
  late TextEditingController birthController = TextEditingController(text: person.birth);
  late TextEditingController deathController = TextEditingController(text: person.death);

  FileImage? imageProvider;

  @override
  void initState() {
    super.initState();
    readImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
      ),
      body: Flex(
        direction: Axis.horizontal,
        children: [
          if(MediaQuery.of(context).orientation == Orientation.landscape) buildImage(context),
          Expanded(
            child: ListView(
              children: [
                if(MediaQuery.of(context).orientation == Orientation.portrait) buildImage(context),
                ListTile(
                  title: TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Jméno",
                      icon: IconButton(
                        icon: Icon(person.sex.icon),
                        onPressed: () => setState(() {
                          person.sex == Sex.male ? person.sex = Sex.female : person.sex = Sex.male;
                          scheduleSave(context);
                        }),
                        padding: EdgeInsets.zero, // TODO: make it work
                      ),
                    ),
                    controller: nameController,
                    onChanged: (name) => setState(() {
                      person.name = name;
                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.name != unchangedPerson!.name || person.sex != unchangedPerson!.sex ? () => setState(() {
                      person.name = unchangedPerson!.name;
                      person.sex = unchangedPerson!.sex;
                      nameController = TextEditingController(text: person.name);
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Divider(height: 16, color: Colors.transparent),
                ListTile(
                  title: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Narození",
                      icon: Icon(Icons.today_outlined),
                    ),
                    controller: birthController,
                    onChanged: (birth) => setState(() {
                      person.birth = birth.isEmpty ? null : birth;
                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.birth != unchangedPerson!.birth ? () => setState(() {
                      person.birth = unchangedPerson!.birth;
                      birthController = TextEditingController(text: person.birth);
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                ListTile(
                  title: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Úmrtí",
                      icon: Icon(Icons.event_outlined),
                    ),
                    controller: deathController,
                    onChanged: (death) => setState(() {
                      person.death = death.isEmpty ? null : death;
                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.death != unchangedPerson!.death ? () => setState(() {
                      person.death = unchangedPerson!.death;
                      deathController = TextEditingController(text: person.death);
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Divider(height: 16, color: Colors.transparent),
                ListTile(
                  title: PersonField(
                    labelText: "Otec",
                    sex: Sex.male,
                    initialId: person.father,
                    onPick: (fatherId) => setState(() {
                      person.father = fatherId;

                      // TODO: Update children

                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.father != unchangedPerson!.father ? () => setState(() {
                      person.father = unchangedPerson!.father;
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                ListTile(
                  title: PersonField(
                    labelText: "Matka",
                    sex: Sex.female,
                    initialId: person.mother,
                    onPick: (motherId) => setState(() {
                      person.mother = motherId;

                      // TODO: Update children

                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.mother != unchangedPerson!.mother ? () => setState(() {
                      person.mother = unchangedPerson!.mother;
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void readImage() {
    try {
      if(person.image != null) {
        final file = File(p.join(App.pedigree!.dir, person.image));
        if(!file.existsSync()) {
          // TODO: try to load from .git/
          // TODO: make some error handling
        }
        imageProvider = FileImage(file);
      } else {
        imageProvider = null;
      }
      print(imageProvider);
    } catch (e) {
      // TODO: make some error handling
      print(e);
    }
  }

  // TODO: stop cropping when the screen is too wide
  Widget buildImage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CircleAvatar(
                radius: MediaQuery.of(context).orientation == Orientation.portrait
                    ? min(MediaQuery.of(context).size.width / 2 - 48, MediaQuery.of(context).size.height / 4 - 50)
                    : MediaQuery.of(context).size.width / 4 - 48,
                foregroundImage: imageProvider,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.hide_image_outlined),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    // TODO
                    onPressed: () {}
                  ),
                ),
                IconButton.filledTonal(
                  icon: person.image != unchangedPerson?.image ? const Icon(Icons.backspace_outlined) : const Icon(Icons.delete_outline),
                  onPressed: person.image != null ? () {
                    person.image = null;
                    readImage();
                    scheduleSave(context);
                    setState(() {});
                  } : unchangedPerson?.image != null ? () {
                    person.image = unchangedPerson!.image;
                    readImage();
                    scheduleSave(context);
                    setState(() {});
                  } : null
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}