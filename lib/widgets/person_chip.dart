import 'package:dpc/dpc.dart';
import 'package:dpc/widgets/avatar.dart';
import 'package:flutter/material.dart';

class PersonChip extends StatelessWidget {

  const PersonChip({
    super.key,
    required this.person,
    required this.repoDir,
    this.onRemove,
    this.removeIcon,
    this.backgroundColor,
    this.nameColor,
    this.avatarBackgroundColor,
  });

  final Person person;
  final String repoDir;
  final void Function()? onRemove;
  final Icon? removeIcon;
  final Color? backgroundColor;
  final Color? avatarBackgroundColor;
  final Color? nameColor;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
        )
      ),
      child: Row(
        children: [
          PersonAvatar(
            person: person,
            repoDir: repoDir,
            radius: 16,
            backgroundColor: avatarBackgroundColor,
          ),
          Padding(
            padding: EdgeInsets.only(left: 4, top: 4, bottom: 4, right: onRemove == null ? 8 : 0),
            child: Text(person.name, style: TextStyle(color: nameColor)),
          ),
          if(onRemove != null) SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              iconSize: 16,
              icon: removeIcon ?? const Icon(Icons.close),
              onPressed: onRemove,
            ),
          )
        ],
      ),
    );
  }
  
}