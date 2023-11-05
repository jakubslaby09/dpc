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
  Widget fab(_) => OrientationBuilder(
    builder: (context, orientation) => orientation == Orientation.portrait ? FloatingActionButton(
        onPressed: () => CommitSheet.show(context),
        tooltip: "Zveřejnit",
        child: const Icon(Icons.cloud_upload_outlined),
      ) : FloatingActionButton.extended(
        onPressed: () => CommitSheet.show(context),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text("Zveřejnit"),
      ),
  );
}

// TODO: make ChangeType more clear in the ui
// TODO: add a 'no changes' text
// TODO: add ui for unassigned files
// TODO: make people listTiles navigate to their pages on tap
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
              ...diff(App.unchangedPedigree!.people, App.pedigree!.people, (a, b) => a.compare(b)).map((change) {
                final person = App.pedigree!.people.elementAtOrNull(change.index) ?? change.unchanged!;
                  return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(person.sex.icon),
                        title: Text(person.name),
                        trailing: change.type == ChangeType.modification && person.name == change.unchanged?.name && person.sex == change.unchanged?.sex ? null : IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            switch (change.type) {
                              case ChangeType.modification:
                                person.sex = App.unchangedPedigree!.people[change.index].sex;
                                person.name = App.unchangedPedigree!.people[change.index].name;
                                break;
                              case ChangeType.addition:
                                App.pedigree!.people.removeAt(change.index);
                                break;
                              case ChangeType.removal:
                                // TODO: fix ordering
                                try {
                                  App.pedigree!.people.insert(change.index, change.unchanged!);
                                } on RangeError catch (_) {
                                  App.pedigree!.people.add(change.unchanged!);
                                }
                                break;
                            }
                            scheduleSave(context);
                          }),
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      if(change.unchanged != null && person.birth != change.unchanged!.birth) ListTile(
                        leading: const Icon(Icons.today_outlined),
                        title: Text(person.birth ?? "-"),
                        trailing: IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            person.birth = App.unchangedPedigree!.people[change.index].birth;
                          }),
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      if(change.unchanged != null && person.death != change.unchanged!.death) ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: Text(person.death ?? "-"),
                        trailing: IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            person.death = App.unchangedPedigree!.people[change.index].death;
                          }),
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      if(change.unchanged != null && person.father != change.unchanged!.father) ListTile(
                        leading: Icon(Sex.male.icon),
                        title: Text(person.father == null ? "-" : App.pedigree!.people.elementAtOrNull(person.father!)?.name ?? "?"),
                        trailing: IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            person.setParent(App.unchangedPedigree!.people[change.index].father, Sex.male, App.pedigree!);
                          }),
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      if(change.unchanged != null && person.mother != change.unchanged!.mother) ListTile(
                        leading: Icon(Sex.female.icon),
                        title: Text(person.mother == null ? "-" : App.pedigree!.people.elementAtOrNull(person.mother!)?.name ?? "?"),
                        trailing: IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            person.setParent(App.unchangedPedigree!.people[change.index].mother, Sex.female, App.pedigree!);
                          }),
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      if(
                        change.type == ChangeType.modification &&
                        change.unchanged!.children.length != person.children.length &&
                        person.children.safeFirstWhere((id) => !change.unchanged!.children.contains(id)) != null
                        )
                        ...simpleDiff(change.unchanged!.children, person.children).map((childChange) {
                        final child = Child(childChange.unchanged ?? person.children[childChange.index], App.pedigree!);
                        return ListTile(
                          tileColor: childChange.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                          textColor: childChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          iconColor: childChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          leading: const Icon(Icons.child_friendly_outlined),
                          title: Text(child is Person ? child.name : "id: ${child.id}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.backspace_outlined),
                            onPressed: () => setState(() {
                              if(childChange.type == ChangeType.addition) {
                                print("removing ${childChange.unchanged!} from ${person.name}");
                                person.removeChild(childChange.index, App.pedigree!);
                              } else if(childChange.type == ChangeType.removal) {
                                // TODO: fix ordering
                                person.addChild(childChange.unchanged!, null, App.pedigree!, childChange.index);
                                // person.children.add(childChange.unchanged!);
                              }
                              scheduleSave(context);
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
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
                        trailing: change.type == ChangeType.modification && changedChronicle?.name == change.unchanged?.name ? null : IconButton(
                          icon: Icon(change.type == ChangeType.addition ? Icons.delete_forever_outlined : Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            if(change.type == ChangeType.modification) {
                              changedChronicle?.name = change.unchanged!.name;
                            } else if(change.type == ChangeType.removal) {
                              // TODO: fix ordering
                              try {
                                App.pedigree!.chronicle.insert(change.index, change.unchanged!);
                              } on RangeError catch (_) {
                                App.pedigree!.chronicle.add(change.unchanged!);
                              }
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
                              // TODO: fix ordering
                              try {
                                changedChronicle.files.insert(fileChange.index, fileChange.unchanged!);
                              } on RangeError catch (_) {
                                changedChronicle.files.add(fileChange.unchanged!);
                              }
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

    if(originalIndex + indexDelta < 0) {
      // TODO: debug
      // print("diff: skipping $originalItem ($originalIndex) -> (${originalIndex + indexDelta})");
      continue;
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