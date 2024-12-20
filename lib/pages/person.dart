import 'dart:io';
import 'dart:math';
import 'package:dpc/autosave.dart';
import 'package:dpc/pages/log.dart';
import 'package:dpc/widgets/add_child_sheet.dart';
import 'package:dpc/widgets/file_import_sheet.dart';
import 'package:file_picker/file_picker.dart';
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
                    color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Divider(height: 16, color: Colors.transparent),
                ListTile(
                  title: PersonField(
                    labelText: "Otec",
                    sex: Sex.male,
                    initialId: person.father,
                    onPick: (fatherId) => setState(() {
                      person.setParent(fatherId, Sex.male, App.pedigree!);

                      // TODO: update personField

                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.father != unchangedPerson!.father ? () => setState(() {
                      person.setParent(unchangedPerson!.father, Sex.male, App.pedigree!);
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                ListTile(
                  title: PersonField(
                    labelText: "Matka",
                    sex: Sex.female,
                    initialId: person.mother,
                    onPick: (motherId) => setState(() {
                      person.setParent(motherId, Sex.female, App.pedigree!);

                      // TODO: update personField

                      scheduleSave(context);
                    }),
                  ),
                  trailing: unchangedPerson == null ? null : IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: person.mother != unchangedPerson!.mother ? () => setState(() {
                      person.setParent(unchangedPerson!.mother, Sex.female, App.pedigree!);
                      scheduleSave(context);
                    }) : null,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Přidat dítě"),
                  onTap: () async {
                    final childId = await AddChildSheet.show(context, person);
                    if(childId == null) return;
                    setState(() {
                    // TODO: make ui for the otherParent argument
                      person.addChild(childId, null, App.pedigree!);
                    });

                    scheduleSave(context);
                  },
                ),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 8),
                //   child: Row(
                //     children: [
                //       Expanded(child: Text("Děti", style: Theme.of(context).textTheme.titleSmall)),
                //       IconButton.filledTonal(onPressed: () {}, icon: Icon(Icons.add))
                //     ],
                //   ),
                // ),
                ...person.getChildren(App.pedigree!).map((child) => ListTile(
                  leading: const Icon(Icons.child_friendly_outlined),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(child is Person ? child.name : child is UnknownChildren ? "neznámé děti (${child.subId})" : "neznámé dítě")
                      ),
                      if(child is HasOtherParent) const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.hotel_outlined),
                      ),
                      if(child is HasOtherParent) Text((child as HasOtherParent).otherParent(person, App.pedigree!)?.name ?? "?"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      person.removeChild(child.id, App.pedigree!);

                      scheduleSave(context);
                    }),
                  ),
                  onTap: () {
                    // TODO: navigate to child
                  },
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> readImage() async {
    try {
      imageProvider = await person.imageProvider(App.pedigree!.dir);
    } on Exception catch (e, t) {
      showException(context, "nelze načíst profilovou fotku", e, t);
    }
    setState(() {});
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
                    onPressed: () async {
                      final fileResult = (await FilePicker.platform.pickFiles(
                        allowMultiple: false,
                        dialogTitle: "Fotka - ${person.name}",
                        type: FileType.image,
                      ))?.files.elementAtOrNull(0);
                      if(fileResult == null) return;
                      final file = File(fileResult.path!);

                      // TODO: allow file overwrites
                      final newPath = await showFileImportSheet(context, file.path, "Pojmenujte fotku", "profilové fotky");
                      if(newPath == null) return;

                      try {
                        await File(newPath).parent.create(recursive: true);
                        await file.copy(newPath);
                        // TODO: should we delete the original person.image file?
                      } on Exception catch (e, t) {
                        showException(context, "nelze zkopírovat profilovou fotku", e, t);
                        return;
                      }

                      scheduleSave(context);
                      setState(() {
                        person.image = p.relative(newPath, from: App.pedigree!.dir);
                      });
                      readImage();
                    },
                  ),
                ),
                IconButton.filledTonal(
                  icon: person.image != unchangedPerson?.image ? const Icon(Icons.backspace_outlined) : const Icon(Icons.delete_outline),
                  onPressed: person.image != null ? () {
                    person.image = null;
                    readImage();
                    scheduleSave(context);
                  } : unchangedPerson?.image != null ? () {
                    person.image = unchangedPerson!.image;
                    readImage();
                    scheduleSave(context);
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