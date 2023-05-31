import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dpc.dart';

class PersonPage extends StatefulWidget {
  PersonPage(this.person, {super.key});

  final Person person;

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  late Person newPerson = widget.person; // TODO: copy object

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person.name),
      ),
      body: ListView(
        children: [
          ListTile(
            // leading: Icon(person.sex == Sex.male ? Icons.face : Icons.face_3),
            title: TextFormField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Jméno",
                icon: Icon(widget.person.sex == Sex.male ? Icons.face : Icons.face_3),
              ),
              initialValue: widget.person.name,
              onChanged: (name) => newPerson.name = name,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.backspace_outlined),
              onPressed: () => setState(() => newPerson.name = widget.person.name),
            ),
          ),
        ],
      ),
    );
  }
}