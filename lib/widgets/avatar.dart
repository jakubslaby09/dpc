import 'dart:io';

import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    required this.repoDir,
    this.radius,
  });

  final Person person;
  final String repoDir;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      foregroundImage: person.imageProviderUnchecked(repoDir),
      onForegroundImageError: person.image == null ? null : (err, stack) {
        if(err is PathNotFoundException) return;
        throw err;
      },
      backgroundColor: App.prefs.filledAvatarIcons
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Colors.transparent,
      child: Icon(
        person.sex.icon,
        size: App.prefs.filledAvatarIcons ? null : 1.5 * (radius ?? 20),
      ),
    );
  }
  
}