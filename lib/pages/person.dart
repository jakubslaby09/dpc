import 'dart:ui';
import 'package:dpc/main.dart';
import 'package:dpc/widgets/person_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dpc.dart';

class PersonPage extends StatefulWidget {
  const PersonPage(this.id, {super.key});
  final int id;

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  late final Person person = App.pedigree!.people[widget.id];
  late final Person unchangedPerson = App.unchangedPedigree!.people[widget.id];

  late TextEditingController nameController = TextEditingController(text: person.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
      ),
      body: ListView(
        children: [
          ListTile(
            title: TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Jméno",
                icon: IconButton(
                  icon: Icon(person.sex.icon),
                  onPressed: () => setState(() {
                    person.sex == Sex.male ? person.sex = Sex.female : person.sex = Sex.male;
                  }),
                  padding: EdgeInsets.zero, // TODO: make it work
                ),
              ),
              controller: nameController,
              onChanged: (name) => setState(() => person.name = name),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.backspace_outlined),
              onPressed: person.name != unchangedPerson.name || person.sex != unchangedPerson.sex ? () => setState(() {
                person.name = unchangedPerson.name;
                person.sex = unchangedPerson.sex;
                nameController = TextEditingController(text: person.name);
              }) : null,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          Divider(height: 16, color: Colors.transparent),
          ListTile(
            title: PersonField(
              labelText: "Otec",
              sex: Sex.male,
              initialId: person.father != -1 ? person.father : null,
              onPick: (fatherId) => setState(() => person.father = fatherId),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.backspace_outlined),
              onPressed: person.father != unchangedPerson.father ? () => setState(() {
                person.father = unchangedPerson.father;
              }) : null,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          ListTile(
            title: PersonField(
              labelText: "Matka",
              sex: Sex.female,
              initialId: person.mother != -1 ? person.mother : null,
              onPick: (motherId) => setState(() => person.mother = motherId),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.backspace_outlined),
              onPressed: person.mother != unchangedPerson.mother ? () => setState(() {
                person.mother = unchangedPerson.mother;
              }) : null,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}