import 'package:dpc/main.dart';
import 'package:flutter/material.dart';

DateTime? scheduledSave;

void scheduleSave(BuildContext context) async {
  if(App.pedigree == null) {
    return;
  }

  final saveDelay = Duration(seconds: App.prefs.saveDelaySeconds);
  final time = DateTime.now().add(saveDelay);

  if(scheduledSave != null && scheduledSave!.isAfter(DateTime.now())) {
    return;
  }

  scheduledSave = time;
  await Future.delayed(saveDelay);
  App.pedigree!.save(context);
}