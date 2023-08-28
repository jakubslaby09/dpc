import 'dart:math';

import 'package:dpc/autosave.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/home.dart';
import 'package:dpc/widgets/commit_sheet.dart';
import 'package:flutter/material.dart';

class CommitScreen extends StatefulWidget implements FABScreen {
  const CommitScreen({super.key});

  @override
  State<CommitScreen> createState() => _CommitScreenState();
  
  @override
  Widget get fab => OrientationBuilder(
    builder: (context, orientation) => orientation == Orientation.portrait ? FloatingActionButton(
        onPressed: () => commit(context),
        tooltip: "Zveřejnit",
        child: const Icon(Icons.cloud_upload_outlined),
      ) : FloatingActionButton.extended(
        onPressed: () => commit(context),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text("Zveřejnit"),
      ),
  );

  void commit(BuildContext context) {
    showCommitSheet(context);
  }
}

// TODO: make ChangeType more clear in the ui
// TODO: add a 'no changes' text
class _CommitScreenState extends State<CommitScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Card(
        //   elevation: 0,
        //   shape: RoundedRectangleBorder(
        //     side: BorderSide(
        //       color: Theme.of(context).colorScheme.outline,
        //     ),
        //     borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(16)),
        //   ),
        //   child: Column(
          // children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ...?App.pedigree?.people.indexed.map(
                (person) => (person.$1, person.$2, person.$2.compare(App.unchangedPedigree!.people[person.$1]))
              ).where(
                (person) => !person.$3.same()
              ).map((person) => Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(person.$2.sex.icon),
                      title: Text(person.$2.name),
                      trailing: person.$3.name == null && person.$3.sex == null ? null : IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                            person.$2.sex = App.unchangedPedigree!.people[person.$1].sex;
                            person.$2.name = App.unchangedPedigree!.people[person.$1].name;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    if (person.$3.birth != null) ListTile(
                      leading: const Icon(Icons.today_outlined),
                      title: Text(person.$3.birth!),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                          person.$2.birth = App.unchangedPedigree!.people[person.$1].birth;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    if (person.$3.death != null) ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(person.$3.death!),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                          person.$2.death = App.unchangedPedigree!.people[person.$1].death;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    if (person.$3.death != null) ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(person.$3.death!),
                      trailing: IconButton(
                        icon: const Icon(Icons.backspace_outlined),
                        onPressed: () => setState(() {
                          person.$2.death = App.unchangedPedigree!.people[person.$1].death;
                        }),
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(color: Color.fromARGB(64, 128, 128, 128)),
              ...diff(App.unchangedPedigree!.chronicle, App.pedigree!.chronicle, (a, b) => a.compare(b)).map((change) {
                final changedChronicle = App.pedigree!.chronicle.elementAtOrNull(change.index);
                final chronicle = change.unchanged ?? changedChronicle!;

                return Card(
                // child: Text("${change.type.name}: ${changed}"),
                  color: change.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                  // elevation: change.type == ChangeType.removal ? 0 : null,
                  // elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(change.type == ChangeType.removal ? Icons.delete_outline : Icons.auto_stories_outlined),
                        title: Text(chronicle.name),
                        trailing: change.unchanged != null && changedChronicle?.name == change.unchanged!.name ? null : IconButton(
                          icon: Icon(change.type == ChangeType.addition ? Icons.delete_forever_outlined : Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            if(change.type == ChangeType.modification) {
                              changedChronicle?.name = change.unchanged!.name;
                            } else if(change.type == ChangeType.removal) {
                              App.pedigree!.chronicle.insert(change.index, change.unchanged!);
                            } else if(change.type == ChangeType.addition)  {
                              App.pedigree!.chronicle.removeAt(change.index);
                            }
                            scheduleSave(context);
                          }),
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      if(change.type == ChangeType.modification && (changedChronicle?.files.length != change.unchanged!.files.length || changedChronicle?.files.safeFirstWhere((e) => !change.unchanged!.files.contains(e)) != null)) ...simpleDiff(change.unchanged!.files, changedChronicle!.files).map((fileChange) => ListTile(
                        tileColor: fileChange.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                        textColor: fileChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                        iconColor: fileChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                        leading: Icon(chronicle.mime.icon),
                        title: Text(fileChange.unchanged ?? changedChronicle.files[fileChange.index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            if(fileChange.type == ChangeType.addition) {
                              changedChronicle.files.removeAt(fileChange.index);
                            } else if(fileChange.type == ChangeType.removal) {
                              changedChronicle.files.insert(fileChange.index, fileChange.unchanged!);
                            }
                            scheduleSave(context);
                          }),
                        ),
                      ))
                    ],
                  ),
                );
            }),
            // Space for FAB
            const Padding(
              padding: EdgeInsets.only(bottom: 75)
            ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ChangeType {
  addition,
  removal,
  modification,
}

class Change<T> {
  ChangeType type;
  int index;
  /// only set when the type is [ChangeType.modification] or [ChangeType.removal]
  T? unchanged;

  Change.addition(this.index)
  : type = ChangeType.addition;
  
  Change.removal(this.index, this.unchanged)
  : type = ChangeType.removal;
  
  Change.modification(this.index, this.unchanged)
  : type = ChangeType.modification;

  static List<Change<T>> additions<T>(int startInclusive, int end) {
    if(end <= startInclusive) return [];
    return List.generate(end - startInclusive, (index) => Change<T>.addition(index + startInclusive));
  }
  
  static List<Change<T>> removals<T>(int startInclusive, List<T> unchanged) {
    return List.generate(unchanged.length, (index) => Change.removal(index + startInclusive, unchanged[index]));
  }

  @override
  String toString() {
    if(unchanged != null) {
      return "[${type.name} of `$unchanged` at $index]";
    } else {
      return "[${type.name} at $index]";
    }
  }
}

List<Change<T>> simpleDiff<T>(List<T> original, List<T> changed) {
  List<Change<T>> result = original.indexedFilteredMap<Change<T>>(
    (originalItem, index) => !changed.contains(originalItem) ? Change.removal(index, originalItem) : null
  ).toList();

  result.addAll(changed.indexedFilteredMap<Change<T>>(
    (changedItem, index) => !original.contains(changedItem) ? Change.addition(index) : null
  ));

  return result;
}

List<Change<T>> diff<T>(List<T> original, List<T> changed, bool Function(T a, T b) comparator) {
  List<Change<T>> result = [];

  int additions = 0;
  int removals = 0;
  outer: for (var originalIndex = 0; originalIndex < original.length; originalIndex++) {
    final originalItem = original[originalIndex];
    final indexDelta = additions - removals;
    
    if(changed.length <= originalIndex + indexDelta) {
      // print("reached end of changed array.");
      // print("removed ${original.sublist(originalIndex)}");
      result.addAll(Change.removals(originalIndex + indexDelta, original.sublist(originalIndex)));
      break;
    }
    final changedItem = changed[originalIndex + indexDelta];

    if(comparator(originalItem, changedItem)) {
      // print("$originalIndex. original item ($originalItem) is ${originalIndex + indexDelta}. changed item");
      continue;
    }
    
    // print("$originalIndex. original item ($originalItem) mismatches ${originalIndex + indexDelta}. changed item ($changedItem)");

    for (var peekIndex = originalIndex + 1; peekIndex < max(original.length, changed.length - indexDelta); peekIndex++) {
      if(changed.length > peekIndex + indexDelta) {
        final peekedChangedItem = changed[peekIndex + indexDelta];
        if(comparator(peekedChangedItem, originalItem)) {
          // print("   ${peekIndex + indexDelta}. changed item ($peekedChangedItem) is $originalIndex. original item ($originalItem)");
          // print("added ${changed.sublist(originalIndex + indexDelta, peekIndex + indexDelta)}");
          result.addAll(Change.additions<T>(originalIndex + indexDelta, peekIndex + indexDelta));
          additions += peekIndex - originalIndex;
          continue outer;
        } else {
          // print("   ${peekIndex + indexDelta}. changed item ($peekedChangedItem) mismatches $originalIndex. original item ($originalItem)");
        }
      }
      
      if(original.length > peekIndex) {
        final peekedOriginalItem = original[peekIndex];
        if(comparator(peekedOriginalItem, changedItem)) {
          // print("   ${peekIndex}. original item ($peekedOriginalItem) is ${originalIndex + indexDelta}. changed item ($changedItem)");
          // print("removed ${original.sublist(originalIndex, peekIndex)}");
          result.addAll(Change.removals(originalIndex + indexDelta, original.sublist(originalIndex, peekIndex)));
          removals += peekIndex - originalIndex;
          continue outer;
        } else {
          // print("   ${peekIndex}. original item ($peekedOriginalItem) mismatches ${originalIndex + indexDelta}. changed item ($changedItem)");
        }
      }
    }

    // print("$originalIndex. original item ($originalItem) could been ${originalIndex + indexDelta}. changed item ($changedItem)");
    // print("changed $originalItem to $changedItem");
    result.add(Change.modification(originalIndex + indexDelta, originalItem));
  }
  // print("reached end of original array. results: $additions+ $removals-");
  if(changed.length > original.length + additions - removals) {
    // print("added ${changed.sublist(original.length + additions - removals)}");
    result.addAll(Change.additions(original.length + additions - removals, changed.length));
  }

  return result;
}