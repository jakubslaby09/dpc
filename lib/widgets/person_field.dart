import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';

class PersonField extends StatelessWidget {
  PersonField({super.key, this.sex, this.labelText, this.initialId});

  final Sex? sex;
  final String? labelText;
  final int? initialId;
  late int? id = initialId;

  late final TextEditingController controller = TextEditingController(text: person?.name);

  Person? get person {
    if (id == null) return null;
    if (App.pedigree == null) return null;
    return App.pedigree!.people[id!];
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TextField(
        decoration: InputDecoration(
          icon: Icon(sex.icon),
          labelText: labelText,
          // hintText: sex.string,
          border: const OutlineInputBorder(),
        ),
        readOnly: true,
        controller: controller,
        onTap: () => print("clicked"),
      ),
    );
  }
}