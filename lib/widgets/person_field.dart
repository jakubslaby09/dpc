import 'dart:math';

import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';

class PersonField extends StatelessWidget {
  PersonField({super.key, this.sex, this.labelText, this.initialId, this.onPick});

  final Sex? sex;
  final String? labelText;
  final int? initialId;
  late int? id = initialId;

  late final TextEditingController controller = TextEditingController(text: person?.name);
  final Function(int? value)? onPick;

  Person? get person {
    if (id == null) return null;
    if (App.pedigree == null) return null;
    return App.pedigree!.people[id!];
  }

  @override
  Widget build(BuildContext context) {
    // TODO: listen to ENTER
    return TextField(
      mouseCursor: SystemMouseCursors.click,
      decoration: InputDecoration(
        icon: Icon(sex.icon),
        labelText: labelText,
        // hintText: sex.string,
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: id == null ? null : () {
              id = null;
              controller.text = "";
              onPick?.call(null);
            },
          ),
        )
      ),
      readOnly: true,
      controller: controller,
      onTap: () => showModalBottomSheet(
        context: context,
        builder: (context) => PersonPicker(
          sex: sex,
          onPick: (id) {
            this.id = id;
            Navigator.pop(context);
            onPick?.call(id);
          },
        )
      ),
    );
  }
}

class PersonPicker extends StatefulWidget {
  const PersonPicker({super.key, this.onPick, this.sex});

  final Function(int value)? onPick;
  final Sex? sex;

  @override
  State<PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<PersonPicker> {
  late List<Person> filtered = filterPeople("");

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: const InputDecoration(
              label: Text("Search"),
            ),
            onChanged: (filter) => setState(() => filtered = filterPeople(filter)),
          ),
        ),
        SizedBox(
          height: max(MediaQuery.of(context).size.height / 2 - 50, 0) /* Search field */,
          child: ListView.builder(
            // shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (_, index) => ListTile(
              // leading: Icon(filtered[index].sex.icon),
              title: Text(filtered[index].name),
              trailing: Text(
                "${filtered[index].birth ?? "?"} - ${filtered[index].death ?? "?"}",
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                ),
              ),
              onTap: () => widget.onPick?.call(filtered[index].id),
            ),
          ),
        ),
      ],
    );
  }

  List<Person> filterPeople(String filter) {
    return (App.pedigree?.people ?? []).where(
      (person) => (widget.sex ?? person.sex) == person.sex && person.name.toLowerCase().contains(filter.toLowerCase())
    ).toList();
  }
}