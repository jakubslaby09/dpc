import 'dart:math';

import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';

class PersonField extends StatefulWidget {
  PersonField({
    super.key,
    this.sex,
    this.labelText,
    this.initialId,
    this.onPick,
    this.icon,
    this.enabled = true,
    ValueNotifier<int?>? controller,
  }) {
    idController = controller ?? ValueNotifier(initialId);
  }

  final Sex? sex;
  final String? labelText;
  final int? initialId;
  final Widget? icon;
  final bool enabled;
  late final ValueNotifier<int?> idController;
  final Function(int? value)? onPick;

  @override
  State<PersonField> createState() => _PersonFieldState();
}

class _PersonFieldState extends State<PersonField> {
  late final TextEditingController fieldController = TextEditingController();
  late int? id = widget.idController.value; // TODO: make it work with just the idController value

  Person? get person {
    if (/* widget.idController.value */ id == null) return null;
    if (App.pedigree == null) return null;
    return App.pedigree!.people[/* widget.idController.value */ id!];
  }

  @override
  void initState() {
    super.initState();
    widget.idController.addListener(() => setState(() {
      id = widget.idController.value;
    }));
  }

  @override
  Widget build(BuildContext context) {
    fieldController.text = person?.name ?? "";

    // TODO: listen to ENTER
    return TextField(
      mouseCursor: SystemMouseCursors.click,
      enabled: widget.enabled,
      decoration: InputDecoration(
        icon: widget.icon ?? Icon(widget.sex.icon),
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: /* widget.idController.value */ id == null ? null : () {
              id = null;
              widget.idController.value = null;
              widget.onPick?.call(null);
            },
          ),
        )
      ),
      readOnly: true,
      controller: fieldController,
      onTap: () async {
        final id = await PersonPicker.show(context, sex: widget.sex);
        if(id == null) return;
        setState(() {
          widget.idController.value = id;
          this.id = id;
        });
        widget.onPick?.call(id);
      }
    );
  }
}

class PersonPicker extends StatefulWidget {
  const PersonPicker({super.key, this.onPick, this.sex});

  // TODO: add a filter for exclusion
  final Function(int value)? onPick;
  final Sex? sex;

  static Future<int?> show(BuildContext context, { Sex? sex }) async {
    return await showModalBottomSheet<int>(
      context: context,
      builder: (context) => PersonPicker(
        sex: sex,
        onPick: (id) => Navigator.pop(context, id),
      ),
    );
  }

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
              onTap: () {
                widget.onPick?.call(filtered[index].id);
              },
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