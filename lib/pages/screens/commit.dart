import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:dpc/autosave.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/home.dart';
import 'package:dpc/pages/log.dart';
import 'package:dpc/pages/screens/file.dart';
import 'package:dpc/widgets/commit_sheet.dart';
import 'package:dpc/widgets/person_chip.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';
import 'package:path/path.dart' as p;

class CommitScreen extends UniqueWidget implements FABScreen {
  const CommitScreen({required super.key});

  @override
  State<CommitScreen> createState() => _CommitScreenState();
  
  @override
  Widget fab(_) => OrientationBuilder(
    builder: (context, orientation) => orientation == Orientation.portrait ? FloatingActionButton(
        onPressed: () => (currentState as _CommitScreenState?)?.commit(context),
        tooltip: "Zveřejnit",
        child: const Icon(Icons.cloud_upload_outlined),
      ) : FloatingActionButton.extended(
        onPressed: () => (currentState as _CommitScreenState?)?.commit(context),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text("Zveřejnit"),
      ),
  );
}

// TODO: make ChangeType more clear in the ui
// TODO: add a 'no changes' text
// TODO: add ui for unassigned files
// TODO: make people listTiles navigate to their pages on tap
// TODO: display dividers only when needed
class _CommitScreenState extends State<CommitScreen> {
  Future<List<(File, ChangeType)>> files = changedFiles(App.pedigree!.repo);
  Future<int> newChanges = fetchChanges(App.pedigree!.repo);

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
              FutureBuilder(
                future: newChanges,
                builder: (context, newChanges) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ListTile(
                    leading: !newChanges.hasData
                      ? newChanges.hasError
                        ? const Icon(Icons.cloud_off_outlined)
                        : const CircularProgressIndicator()
                      : newChanges.data == 0
                        ? const Icon(Icons.cloud_outlined)
                        : const Icon(Icons.cloud_download_outlined),
                    title: !newChanges.hasData
                    ? newChanges.hasError
                      ? const Text("Nelze zkontrolovat změny z internetu")
                      : const Text("Stahování změn...")
                    : newChanges.data! > 0
                      ? Text("Ve vzdáleném repozitáři je ${newChanges.data} ${newChanges.data! > 1 ? "nových příspěvků" : "nový příspěvek"}")
                      : null,
                    trailing: (newChanges.data ?? 0) > 0 ? FilledButton.icon(
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: Text("Přijmout ${newChanges.data} ${newChanges.data! > 1 ? "příspěvků" : "příspěvek"}"),
                      onPressed: null,
                    ) : newChanges.error is Exception ? TextButton(
                      child: const Text("Více"),
                      onPressed: () => showExceptionPage(context, newChanges.error as Exception),
                    ) : null,
                  ),
                ),
              ),
              const Divider(color: Color.fromARGB(64, 128, 128, 128)),
              if(App.unchangedPedigree!.version != App.pedigree!.version) const Card(
                child: ListTile(
                  leading: Icon(Icons.upgrade),
                  title: Text("Upgrade indexu"),
                ),
              ),
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
                                App.pedigree!.removePerson(change.index);
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
                final authorsDiff = change.unchanged == null || changedChronicle == null ? null : simpleDiff<num>(change.unchanged!.authors, changedChronicle.authors);

                return Card(
                // child: Text("${change.type.name}: ${changed}"),
                  color: change.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                  // elevation: change.type == ChangeType.removal ? 0 : null,
                  // elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(change.type == ChangeType.removal ? Icons.delete_outline : Icons.auto_stories_outlined),
                        title: Text(changedChronicle?.name ?? "test"),
                        subtitle: authorsDiff?.isEmpty ?? true ? null : Row(
                          // TODO: fix overflow
                          children: [
                            ...authorsDiff!.map((authorChange) => PersonChip(
                              // TODO: make a more robust person lookup fuction
                              person: App.pedigree!.people[(authorChange.unchanged ?? changedChronicle!.authors[authorChange.index]).round()],
                              repoDir: App.pedigree!.dir,
                              backgroundColor: authorChange.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                              nameColor: authorChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                              avatarBackgroundColor: authorChange.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                              removeIcon: const Icon(Icons.backspace_outlined),
                              onRemove: () => setState(() {
                                if(authorChange.type == ChangeType.addition) {
                                  changedChronicle!.authors.removeAt(authorChange.index);
                                } else if(authorChange.type == ChangeType.removal) {
                                  // TODO: fix ordering
                                  try {
                                    changedChronicle!.authors.insert(authorChange.index, authorChange.unchanged!);
                                  } on RangeError catch (_) {
                                    changedChronicle!.authors.add(authorChange.unchanged!);
                                  }
                                }
                              }),
                            )),
                          ],
                        ),
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
                      if(change.type == ChangeType.modification && (changedChronicle?.files.length != change.unchanged!.files.length || changedChronicle?.files.safeFirstWhere((e) => !change.unchanged!.files.contains(e)) != null)) ...simpleDiff(change.unchanged!.files, changedChronicle!.files).map((fileChange) {
                        final filePath = fileChange.unchanged ?? changedChronicle.files[fileChange.index];
                        return ListTile(
                          tileColor: fileChange.type == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                          textColor: fileChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          iconColor: fileChange.type == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          leading: Icon(fileTypeFromPath(filePath).icon),
                          title: Text(filePath),
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
                        );
                      })
                    ],
                  ),
                );
            }),
            FutureBuilder(
              future: files,
              builder: (context, files) =>  files.hasData ? Column(
                children: [
                  const Divider(color: Color.fromARGB(64, 128, 128, 128)),
                  ...files.data!.map((file) => Card(
                    child: ListTile(
                      tileColor: file.$2 == ChangeType.removal ? Theme.of(context).colorScheme.errorContainer : null,
                      textColor: file.$2 == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                      iconColor: file.$2 == ChangeType.removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                      leading: Icon(file.$2 == ChangeType.modification ? Icons.edit_outlined : Icons.file_present_outlined),
                      title: Text(file.$1.path),
                      // TODO: make all file changes revertable
                      trailing: file.$2 == ChangeType.addition ? IconButton(
                        icon: const Icon(Icons.delete_forever_outlined),
                        onPressed: () async {
                          // TODO: indicate progress in the ui
                          try {
                            final absolutePath = p.join(App.pedigree!.dir, file.$1.path);
                            if(await FileSystemEntity.isDirectory(absolutePath)) {
                              await Directory(absolutePath).delete(recursive: true);
                            } else {
                              // TODO: handle other fs types
                              await File(absolutePath).delete();
                            }
                          } on Exception catch (e, t) {
                            showException(context, "nelze smazat soubor", e, t);
                          }
                          this.files = changedFiles(App.pedigree!.repo);
                          setState(() { });
                        },
                      ) : null,
                    ),
                  )),
                ],
              ) : const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
            ),
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

  void commit(BuildContext context) async {
    final error = await CommitSheet.show(context);
    if(error != null && context.mounted) {
      showException(context, error.message, error.exception, error.trace);
    }
    try {
      readUnchanged(context, App.pedigree!.dir, App.pedigree!.repo);
    } on Exception catch (e, t) {
      showException(context, "Nelze porovnat rodokmen s právě zveřejněnou verzí.", e, t);
      App.unchangedPedigree = App.pedigree!.clone();
    }
    setState(() { });
  }
  
  static Future<int> fetchChanges(ffi.Pointer<git_repository> repo) async {
    final repoPtr = repo.address;
    return await Isolate.run(() {
      final ffi.Pointer<git_repository> repo = ffi.Pointer.fromAddress(repoPtr);
      ffi.Pointer<ffi.Pointer<git_remote>> remote = calloc();
      ffi.Pointer<git_fetch_options> options = calloc();
      ffi.Pointer<ffi.Size> aheadCount = calloc();
      ffi.Pointer<ffi.Size> behindCount = calloc();
      ffi.Pointer<git_oid> localOid = calloc();
      ffi.Pointer<ffi.Pointer<git_object>> remoteObject = calloc();
      expectCode(
        App.git.git_remote_lookup(remote, repo, "origin".toNativeUtf8().cast()),
        "nelze zjistit, odkud stáhnout změny",
      );
      expectCode(App.git.git_fetch_options_init(options, GIT_FETCH_OPTIONS_VERSION));
      // TODO: options.ref.callbacks.transfer_progress
      expectCode(
        App.git.git_remote_fetch(remote.value, ffi.nullptr, options, ffi.nullptr),
        "nelze stáhnout změny",
      );
      expectCode(
        App.git.git_reference_name_to_id(localOid, repo, "HEAD".toNativeUtf8().cast()),
        "nelze najít místní poslední příspěvek",
      );
      expectCode(
        App.git.git_revparse_single(remoteObject, repo, "origin/HEAD".toNativeUtf8().cast()),
        "nelze najít vzdálený poslední příspěvek",
      );
      
      expectCode(
        App.git.git_graph_ahead_behind(aheadCount, behindCount, repo, remoteObject.value.cast(), localOid),
        "nelze porovnat stažené změny mezi",
      );

      print("success: ${behindCount.value}, ${aheadCount.value}");
      return aheadCount.value;
    });
  }
}

Future<List<(File, ChangeType)>> changedFiles(ffi.Pointer<git_repository> repo) async {
  // TODO: don't share the repo pointer
  // TODO: free memory
  final repoPtr = repo.address;
  return await Isolate.run(() {
    final ffi.Pointer<ffi.Pointer<git_status_list>> statuslist = calloc();
    final ffi.Pointer<git_status_options> options = calloc();
    expectCode(
      App.git.git_status_options_init(options, GIT_STATUS_OPTIONS_VERSION),
      "chyba při nastavování zjišťování stavu ostatních souborů"
    );
    options.ref.flags |= git_status_opt_t.GIT_STATUS_OPT_INCLUDE_UNTRACKED;
    expectCode(
      App.git.git_status_list_new(statuslist, ffi.Pointer.fromAddress(repoPtr), options),
      "nelze získat stav ostatních souborů",
    );
    // git_error_code
    calloc.free(options);

    final List<(File, ChangeType)> files = [];
    // TODO: add a limit to prefs
    for (var i = 0;; i++) {
      final entry = App.git.git_status_byindex(statuslist.value, i);
      if(entry.address == ffi.nullptr.address) {
        break;
      }
      final status = fileStatus(entry);
      if(status != null) {
        files.add(status);
      }
    }

    App.git.git_status_list_free(statuslist.value);
    calloc.free(statuslist);
    return files;
  });
}

(File, ChangeType)? fileStatus(ffi.Pointer<git_status_entry> entry) {
  final ffi.Pointer<git_diff_delta> delta;
  if(entry.ref.index_to_workdir.address != ffi.nullptr.address) {
    delta = entry.ref.index_to_workdir;
  } else {
    delta = entry.ref.head_to_index;
  }
  final path = delta.ref.new_file.path.toDartString();
  final ChangeType changeType;
  switch (entry.ref.status) {
    case git_status_t.GIT_STATUS_INDEX_NEW:
    case git_status_t.GIT_STATUS_WT_NEW:
      changeType = ChangeType.addition;
      break;
    case git_status_t.GIT_STATUS_INDEX_DELETED:
    case git_status_t.GIT_STATUS_WT_DELETED:
      changeType = ChangeType.removal;
      break;
    case git_status_t.GIT_STATUS_INDEX_MODIFIED:
    case git_status_t.GIT_STATUS_WT_MODIFIED:
      if(p.basename(path) == "index.dpc") {
        return null;
      }
      changeType = ChangeType.modification;
      break;
    default:
      return null;
  }
  return (File(path), changeType);
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