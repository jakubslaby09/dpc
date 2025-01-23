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
import 'package:dpc/strings/strings.dart';
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
        tooltip: S(context).commitFAB,
        child: const Icon(Icons.cloud_upload_outlined),
      ) : FloatingActionButton.extended(
        onPressed: () => (currentState as _CommitScreenState?)?.commit(context),
        icon: const Icon(Icons.cloud_upload_outlined),
        label: Text(S(context).commitFAB),
      ),
  );
}

// TODO: make ChangeType more clear in the ui
// TODO: add a 'no changes' text
// TODO: add ui for unassigned files
// TODO: make people listTiles navigate to their pages on tap
// TODO: display dividers only when needed
class _CommitScreenState extends State<CommitScreen> {
  Future<List<(File, ChangeType)>>? files;
  Future<int>? remoteChanges;

  @override
  Widget build(BuildContext context) {
    files ??= changedFiles(App.pedigree!.repo, S(context));
    remoteChanges ??= fetchChanges(App.pedigree!.repo, S(context));
    List<Change<Person>> peopleChanges = diff(App.unchangedPedigree!.people, App.pedigree!.people, (a, b) => a.compare(b));
    List<Change<Chronicle>> chronicleChanges = diff(App.unchangedPedigree!.chronicle, App.pedigree!.chronicle, (a, b) => a.compare(b));
    bool someChanges = peopleChanges.isNotEmpty || chronicleChanges.isNotEmpty;
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
                future: remoteChanges,
                builder: (context, remoteChanges) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ListTile(
                    leading: !remoteChanges.hasData
                      ? remoteChanges.hasError
                        ? const Icon(Icons.cloud_off_outlined)
                        : const CircularProgressIndicator()
                      : remoteChanges.data == 0
                        ? const Icon(Icons.cloud_outlined)
                        : const Icon(Icons.cloud_download_outlined),
                    title: !remoteChanges.hasData
                    ? remoteChanges.hasError
                      ? Text(S(context).couldNotFetchCommits)
                      : Text(S(context).fetchingCommits)
                    : remoteChanges.data! > 0
                      ? Text(S(context).fetchedCommits(remoteChanges.data!, someChanges))
                      : Text(S(context).repoUpToDate),
                    trailing: (remoteChanges.data ?? 0) > 0 ? FilledButton.icon(
                      icon: const Icon(Icons.download_for_offline_outlined),
                      style: someChanges
                        ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error)
                        : null,
                      label: someChanges ? Text(S(context).overwriteWorktree) : Text(S(context).ffCommits(remoteChanges.data!)),
                      onPressed: () => pullChanges(App.pedigree!.repo),
                    ) : remoteChanges.error is Exception ? TextButton(
                      child: Text(S(context).fetchErrorDetails),
                      onPressed: () => showExceptionPage(context, remoteChanges.error as Exception),
                    ) : null,
                  ),
                ),
              ),
              const Divider(color: Color.fromARGB(64, 128, 128, 128)),
              if(App.unchangedPedigree!.version != App.pedigree!.version) Card(
                child: ListTile(
                  leading: const Icon(Icons.upgrade),
                  title: Text(S(context).indexUpgradeChange),
                ),
              ),
              ...peopleChanges.map((change) {
                final person = App.pedigree!.people.elementAtOrNull(change.index) ?? change.unchanged;
                if(person == null) {
                  throw Exception("The person change isn't a removal, but it has an out-of-bounds index");
                }
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(person.sex.icon),
                        title: Text(person.name),
                        trailing: change.isModificationAnd((change) => person.name == change.unchanged.name && person.sex == change.unchanged.sex) ?? false ? null : IconButton(
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            change.mapType(
                              ifModification: (change) {
                                person.sex = change.unchanged.sex;
                                person.name = change.unchanged.name;
                              },
                              ifAddition: (change) {
                                App.pedigree!.removePerson(change.index);
                              },
                              ifRemoval: (change) {
                                // TODO: fix ordering
                                try {
                                  App.pedigree!.people.insert(change.index, change.unchanged);
                                } on RangeError catch (_) {
                                  App.pedigree!.people.add(change.unchanged);
                                }
                              },
                            );
                            scheduleSave(context);
                          }),
                          color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).colorScheme.onSurface,
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if(
                        change.isModificationAnd(
                          (change) => change.unchanged.children.length != person.children.length
                            || person.children.safeFirstWhere((id) => !change.unchanged.children.contains(id)) != null
                        ) ?? false)
                        ...simpleDiff(change.unchanged!.children, person.children).map((childChange) {
                        final child = Child(childChange.unchanged ?? person.children[childChange.index], App.pedigree!);
                        return ListTile(
                          tileColor: childChange is Removal ? Theme.of(context).colorScheme.errorContainer : null,
                          textColor: childChange is Removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          iconColor: childChange is Removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          leading: const Icon(Icons.child_friendly_outlined),
                          // TODO: display negative ids properly
                          title: Text(child is Person ? child.name : "id: ${child.id}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.backspace_outlined),
                            onPressed: () => setState(() {
                              childChange.mapType(
                                ifAddition: (childChange) {
                                  person.removeChild(person.children[childChange.index], App.pedigree!);
                                },
                                ifRemoval: (childChange) {
                                  // TODO: fix ordering
                                  person.addChild(childChange.unchanged, null, App.pedigree!, childChange.index);
                                },
                                ifModification: (_) {},
                              );
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
              ...chronicleChanges.map((change) {
                final changedChronicle = App.pedigree!.chronicle.elementAtOrNull(change.index);
                final authorsDiff = change.unchanged == null || changedChronicle == null ? null : simpleDiff<num>(change.unchanged!.authors, changedChronicle.authors);

                return Card(
                // child: Text("${change.type.name}: ${changed}"),
                  color: change is Removal ? Theme.of(context).colorScheme.errorContainer : null,
                  // elevation: change is Removal ? 0 : null,
                  // elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(change is Removal ? Icons.delete_outline : Icons.auto_stories_outlined),
                        title: Text(changedChronicle?.name ?? ""),
                        subtitle: authorsDiff?.isEmpty ?? true ? null : Row(
                          // TODO: fix overflow
                          children: [
                            ...authorsDiff!.map((authorChange) => PersonChip(
                              // TODO: make a more robust person lookup fuction
                              person: App.pedigree!.people[(authorChange.unchanged ?? changedChronicle!.authors[authorChange.index]).round()],
                              repoDir: App.pedigree!.dir,
                              backgroundColor: authorChange is Removal ? Theme.of(context).colorScheme.errorContainer : null,
                              nameColor: authorChange is Removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                              avatarBackgroundColor: authorChange is Removal ? Theme.of(context).colorScheme.errorContainer : null,
                              removeIcon: const Icon(Icons.backspace_outlined),
                              onRemove: () => setState(() {
                                authorChange.mapType(
                                  ifAddition: (change) {
                                    changedChronicle!.authors.removeAt(authorChange.index);
                                  },
                                  ifRemoval: (change) {
                                    // TODO: fix ordering
                                    try {
                                      changedChronicle!.authors.insert(authorChange.index, authorChange.unchanged!);
                                    } on RangeError catch (_) {
                                      changedChronicle!.authors.add(authorChange.unchanged!);
                                    }
                                  },
                                  ifModification: (change) {},
                                );
                              }),
                            )),
                          ],
                        ),
                        trailing: change is Modification && changedChronicle?.name == change.unchanged?.name ? null : IconButton(
                          icon: Icon(change is Addition ? Icons.delete_forever_outlined : Icons.backspace_outlined),
                          onPressed: () => setState(() {
                            change.mapType(
                              ifModification: (change) {
                                changedChronicle?.name = change.unchanged.name;
                              },
                              ifRemoval: (change) {
                                // TODO: fix ordering
                                try {
                                  App.pedigree!.chronicle.insert(change.index, change.unchanged);
                                } on RangeError catch (_) {
                                  App.pedigree!.chronicle.add(change.unchanged);
                                }
                              },
                              ifAddition: (change) {
                                App.pedigree!.chronicle.removeAt(change.index);
                              },
                            );
                            scheduleSave(context);
                          }),
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if(
                        change.isModificationAnd((change) => changedChronicle?.files.length != change.unchanged.files.length
                          || changedChronicle?.files.safeFirstWhere((e) => !change.unchanged.files.contains(e)) != null) ?? false
                      ) ...simpleDiff(change.unchanged!.files, changedChronicle!.files).map((fileChange) {
                        final filePath = fileChange.unchanged ?? changedChronicle.files[fileChange.index];
                        return ListTile(
                          tileColor: fileChange is Removal ? Theme.of(context).colorScheme.errorContainer : null,
                          textColor: fileChange is Removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          iconColor: fileChange is Removal ? Theme.of(context).colorScheme.onErrorContainer : null,
                          leading: Icon(fileTypeFromPath(filePath).icon),
                          title: Text(filePath),
                          trailing: IconButton(
                            icon: const Icon(Icons.backspace_outlined),
                            onPressed: () => setState(() {
                              if(fileChange is Addition) {
                                changedChronicle.files.removeAt(fileChange.index);
                              } else if(fileChange is Removal) {
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
                            showException(context, S(context).changesCouldNotDeleteFile, e, t);
                          }
                          this.files = changedFiles(App.pedigree!.repo, S(context));
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
      loadUnchanged(context, App.pedigree!.dir, App.pedigree!.repo);
    } on Exception catch (e, t) {
      showException(context, S(context).commitCannotReadHead, e, t);
      App.unchangedPedigree = App.pedigree!.clone();
    }
    setState(() { });
  }
  
  static Future<int> fetchChanges(ffi.Pointer<git_repository> repo, S s) async {
    final repoPtr = repo.address;
    return await Isolate.run(() {
      // TODO: free
      final ffi.Pointer<git_repository> repo = ffi.Pointer.fromAddress(repoPtr);
      ffi.Pointer<ffi.Pointer<git_remote>> remote = calloc();
      ffi.Pointer<git_fetch_options> options = calloc();
      ffi.Pointer<ffi.Size> aheadCount = calloc();
      ffi.Pointer<ffi.Size> behindCount = calloc();
      ffi.Pointer<git_oid> localOid = calloc();
      ffi.Pointer<ffi.Pointer<git_object>> remoteObject = calloc();
      expectCode(
        App.git.git_remote_lookup(remote, repo, "origin".toNativeUtf8().cast()),
        s.fetchCouldNotLookupRemote,
      );
      expectCode(App.git.git_fetch_options_init(options, GIT_FETCH_OPTIONS_VERSION));
      options.ref.callbacks.certificate_check = ffi.Pointer.fromFunction<ffi.Int Function(ffi.Pointer<git_cert>, ffi.Int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>)>(_badCertificateCallback, minusOne);
      // TODO: options.ref.callbacks.transfer_progress
      expectCode(
        App.git.git_remote_fetch(remote.value, ffi.nullptr, options, ffi.nullptr),
        s.fetchCouldNotFetchRemote,
      );
      expectCode(
        App.git.git_reference_name_to_id(localOid, repo, "HEAD".toNativeUtf8().cast()),
        s.fetchCouldNotReadHead,
      );
      expectCode(
        App.git.git_revparse_single(remoteObject, repo, "origin/HEAD".toNativeUtf8().cast()),
        s.fetchCouldNotReadFetchHead,
      );
      expectCode(
        App.git.git_graph_ahead_behind(aheadCount, behindCount, repo, remoteObject.value.cast(), localOid),
        s.fetchCouldNotCompareRemote,
      );
      return aheadCount.value;
    });
  }
  
  void pullChanges(ffi.Pointer<git_repository> repo) async {
    final repoPtr = repo.address;
    try {
      return await Isolate.run(() {
        // TODO: free
        // TODO: write error messages
        final ffi.Pointer<git_repository> repo = ffi.Pointer.fromAddress(repoPtr);
        ffi.Pointer<git_checkout_options> opts = calloc();
        ffi.Pointer<git_strarray> indexPath = calloc<git_strarray>();
        ffi.Pointer<ffi.Pointer<ffi.Char>> indexPathArray = calloc();
        ffi.Pointer<ffi.Pointer<git_annotated_commit>> fetchhead = calloc();
        ffi.Pointer<ffi.Pointer<git_object>> fetchedObject = calloc();
        ffi.Pointer<ffi.Pointer<git_reference>> head = calloc();
        ffi.Pointer<ffi.Pointer<git_reference>> newRef = calloc();
        expectCode(App.git.git_checkout_options_init(opts, GIT_CHECKOUT_OPTIONS_VERSION));
        indexPathArray[0] = "index.dpc".toNativeUtf8().cast();
        indexPath.ref.strings = indexPathArray;
        indexPath.ref.count = 1;
        expectCode(
          App.git.git_annotated_commit_from_revspec(fetchhead, repo, "FETCH_HEAD".toNativeUtf8().cast()),
        );
        final fetchedOid = App.git.git_annotated_commit_id(fetchhead.value);

        expectCode(
          App.git.git_repository_head(head, repo),
        );

        expectCode(
          App.git.git_object_lookup(fetchedObject, repo, fetchedOid, git_object_t.GIT_OBJECT_COMMIT),
        );
        expectCode(
          App.git.git_checkout_options_init(opts, GIT_CHECKOUT_OPTIONS_VERSION),
        );
        opts.ref.checkout_strategy = git_checkout_strategy_t.GIT_CHECKOUT_FORCE;
        expectCode(
          App.git.git_checkout_tree(repo, fetchedObject.value, opts),
        );
        expectCode(
          App.git.git_reference_set_target(newRef, head.value, fetchedOid, ffi.nullptr),
        );
        print("success");
      });
    } on Exception catch(e, t) {
      showException(context, "", e, t);
    }
  }
}

Future<List<(File, ChangeType)>> changedFiles(ffi.Pointer<git_repository> repo, S s) async {
  // TODO: don't share the repo pointer
  // TODO: free memory
  final repoPtr = repo.address;
  return await Isolate.run(() {
    final ffi.Pointer<ffi.Pointer<git_status_list>> statuslist = calloc();
    final ffi.Pointer<git_status_options> options = calloc();
    expectCode(
      App.git.git_status_options_init(options, GIT_STATUS_OPTIONS_VERSION),
      s.changesCouldNotInitDiffOptions,
    );
    options.ref.flags |= git_status_opt_t.GIT_STATUS_OPT_INCLUDE_UNTRACKED;
    expectCode(
      App.git.git_status_list_new(statuslist, ffi.Pointer.fromAddress(repoPtr), options),
      s.changesCouldNotDiffNew,
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

abstract class Change<T> {
  const Change(this.index);
  final int index;

  // TODO: implement
  @override
  String toString();

  T? get unchanged;

  M mapType<M>({
    required M Function(Addition<T> change) ifAddition,
    required M Function(Modification<T> change) ifModification,
    required M Function(Removal<T> change) ifRemoval,
  });

  M? isModificationAnd<M>(M Function(Modification<T> change) map) {
    return null;
  }
}

class Addition<T> extends Change<T> {
  const Addition(super.index);

  @override
  Null get unchanged => null;

  static List<Addition<T>> range<T>(int startInclusive, int end) {
    if(end <= startInclusive) return [];
    return List.generate(end - startInclusive, (index) => Addition(index + startInclusive));
  }

  @override
  M mapType<M>({
    required M Function(Addition<T> change) ifAddition,
    required M Function(Modification<T> change) ifModification,
    required M Function(Removal<T> change) ifRemoval,
  }) {
    return ifAddition(this);
  }
}

class Removal<T> extends Change<T> {
  const Removal(super.index, this.unchanged);
  @override
  final T unchanged;

  static List<Removal<T>> range<T>(int startInclusive, List<T> unchanged) {
    return List.generate(unchanged.length, (index) => Removal(index + startInclusive, unchanged[index]));
  }

  @override
  M mapType<M>({
    required M Function(Addition<T> change) ifAddition,
    required M Function(Modification<T> change) ifModification,
    required M Function(Removal<T> change) ifRemoval,
  }) {
    return ifRemoval(this);
  }
}

class Modification<T> extends Change<T> {
  const Modification(super.index, this.unchanged);
  @override
  final T unchanged;

  @override
  M isModificationAnd<M>(M Function(Modification<T> change) map) {
    return map(this);
  }

  @override
  M mapType<M>({
    required M Function(Addition<T> change) ifAddition,
    required M Function(Modification<T> change) ifModification,
    required M Function(Removal<T> change) ifRemoval,
  }) {
    return ifModification(this);
  }
}

List<Change<T>> simpleDiff<T>(List<T> original, List<T> changed) {
  List<Change<T>> result = original.indexedFilteredMap<Change<T>>(
    (originalItem, index) => !changed.contains(originalItem) ? Removal(index, originalItem) : null
  ).toList();

  result.addAll(changed.indexedFilteredMap<Change<T>>(
    (changedItem, index) => !original.contains(changedItem) ? Addition(index) : null
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
      result.addAll(Removal.range(originalIndex + indexDelta, original.sublist(originalIndex)));
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
          result.addAll(Addition.range<T>(originalIndex + indexDelta, peekIndex + indexDelta));
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
          result.addAll(Removal.range(originalIndex + indexDelta, original.sublist(originalIndex, peekIndex)));
          removals += peekIndex - originalIndex;
          continue outer;
        } else {
          // print("   ${peekIndex}. original item ($peekedOriginalItem) mismatches ${originalIndex + indexDelta}. changed item ($changedItem)");
        }
      }
    }

    // print("$originalIndex. original item ($originalItem) could been ${originalIndex + indexDelta}. changed item ($changedItem)");
    // print("changed $originalItem to $changedItem");
    result.add(Modification(originalIndex + indexDelta, originalItem));
  }
  // print("reached end of original array. results: $additions+ $removals-");
  if(changed.length > original.length + additions - removals) {
    // print("added ${changed.sublist(original.length + additions - removals)}");
    result.addAll(Addition.range(original.length + additions - removals, changed.length));
  }

  return result;
}

int _badCertificateCallback(ffi.Pointer<git_cert> cert, int valid, ffi.Pointer<ffi.Char> host, ffi.Pointer<ffi.Void> payloadPtr) {
  if(Platform.isAndroid) {
    // TODO: don't do such a stupid thing
    print("ignoring a bad certificate");
    return 0;
  }
  // TODO: ask the user
  return 1;
}