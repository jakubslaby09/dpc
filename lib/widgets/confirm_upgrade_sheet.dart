import 'package:dpc/dpc.dart';
import 'package:dpc/strings/strings.dart';
import 'package:flutter/material.dart';

class UpgradeSheet extends StatelessWidget {
  const UpgradeSheet(this.indexValues, this.dirPath, {super.key});
  final int indexValues;
  final String dirPath;

  static Future<bool> show(BuildContext context, int indexValues, String dirPath) async {
    return await showModalBottomSheet<bool>(
      showDragHandle: true,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: UpgradeSheet(indexValues, dirPath),
      ),
    ) ?? false;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(S(context).upgradeRepo, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        ),
        Text(S(context).upgradeRepoDir(dirPath)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(S(context).upgradeRepoFromVersion),
            Text(indexValues.toString(), style: const TextStyle(fontSize: 20)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward),
            ),
            Text(S(context).upgradeRepoToVersion),
            const Text("${Pedigree.maxVersion}", style: TextStyle(fontSize: 20)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.update_outlined),
                  label: Text(S(context).upgradeRepoButton),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}