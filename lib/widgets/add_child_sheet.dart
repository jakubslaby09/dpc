import 'package:dpc/main.dart';
import 'package:dpc/strings/strings.dart';
import 'package:dpc/widgets/person_field.dart';
import 'package:flutter/material.dart';

import '../dpc.dart';

class AddChildSheet extends StatefulWidget {
  const AddChildSheet({required this.parent, super.key});

  @override
  State<AddChildSheet> createState() => _AddChildSheetState();
  final Person parent;

  static Future<num?> show(BuildContext context, Person parent) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => AddChildSheet(parent: parent),
    );
  }
}

class _AddChildSheetState extends State<AddChildSheet> {
  AddChildOptions selectedOption = AddChildOptions.existingChild;
  num? id;
  ValueNotifier<int?> otherParentIdController = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: SegmentedButton<AddChildOptions>(
            segments: [
              ButtonSegment(
                icon: const Icon(Icons.child_care_outlined),
                value: AddChildOptions.existingChild,
                label: Text(S.of(context).existingChild),
              ),
              ButtonSegment(
                icon: const Icon(Icons.person_off_outlined),
                value: AddChildOptions.unknownChild,
                label: Text(S.of(context).unknownChild),
              ),
              ButtonSegment(
                icon: const Icon(Icons.person_add_disabled_outlined),
                value: AddChildOptions.unknownChildren,
                label: Text(S.of(context).unknownChildren),
              ),
            ],
            selected: { selectedOption },
            onSelectionChanged: (selection) => setState(() {
              selectedOption = selection.first;
              if(selectedOption == AddChildOptions.unknownChildren) otherParentIdController.value = null;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PersonField(
            labelText: S.of(context).child,
            icon: const Icon(Icons.child_friendly_outlined),
            enabled: selectedOption == AddChildOptions.existingChild,
            onPick: (id) => setState(() {
              this.id = id;
              otherParentIdController.value = id == null ? null : App.pedigree!.people[id].otherParent(widget.parent, App.pedigree!)?.id;
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: PersonField(
            labelText: widget.parent.sex == Sex.male ? S.of(context).mother : S.of(context).father,
            sex: widget.parent.sex == Sex.male ? Sex.female : Sex.male,
            controller: otherParentIdController,
            enabled: selectedOption == AddChildOptions.unknownChildren,
            onPick: (id) => otherParentIdController.value = id,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton(
            child: Text(S.of(context).addChild),
            onPressed: id == null && selectedOption == AddChildOptions.existingChild ? null : () {
              final num id;
              switch (selectedOption) {
                case AddChildOptions.existingChild:
                  id = this.id!;
                case AddChildOptions.unknownChild:
                  id = const UnknownChild().id;
                case AddChildOptions.unknownChildren:
                  id = UnknownChildren(otherParentIdController.value).wholeId;
              }
              Navigator.of(context).pop(id);
            },
          ),
        ),
      ],
    );
  }
}

enum AddChildOptions {
  existingChild,
  unknownChild,
  unknownChildren,
}