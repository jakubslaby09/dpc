import 'dart:ffi' as ffi;

import 'package:dpc/main.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

class CommitSheet extends StatelessWidget {
  const CommitSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Zpráva příspěvku',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              minLines: 2,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Popis příspěvku',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton(
              onPressed: () => onConfirm(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text("Potvrdit"),
            ),
          )
        ],
      );
  }
  
  void onConfirm(BuildContext context) {
    // print("running libgit2");
    // TODO: make an exception for it
    if(App.pedigree == null) return;
    App.pedigree!.save(context);

    ffi.Pointer<ffi.Pointer<git_index>> index = ffi.calloc();
    print(App.git.git_repository_index(index, App.pedigree!.repo.value));

    // add
    print(App.git.git_index_add_bypath(index.value, "index.dpc".toNativeUtf8().cast()));
    print(App.git.git_index_write(index.value));

    // commit
    ffi.Pointer<git_oid> parentOid = ffi.calloc();
    ffi.Pointer<ffi.Pointer<git_commit>> parent = ffi.calloc();
    ffi.Pointer<git_oid> treeOid = ffi.calloc();
    ffi.Pointer<git_oid> commitOid = ffi.calloc();
    ffi.Pointer<ffi.Pointer<git_tree>> tree = ffi.calloc();
    ffi.Pointer<ffi.Pointer<git_signature>> signature = ffi.calloc();

    print(App.git.git_index_write_tree(treeOid, index.value));
    print(App.git.git_index_write(index.value));
    print(App.git.git_tree_lookup(tree, App.pedigree!.repo.value, treeOid));
    print(App.git.git_reference_name_to_id(parentOid, App.pedigree!.repo.value, "HEAD".toNativeUtf8().cast()));
    print(App.git.git_commit_lookup(parent, App.pedigree!.repo.value, parentOid));
    print(App.git.git_signature_default(signature, App.pedigree!.repo.value));
    print(App.git.git_commit_create(
      commitOid,
      App.pedigree!.repo.value,
      "HEAD".toNativeUtf8().cast(),
      signature.value,
      // ffi.nullptr,
      signature.value,
      "UTF-8".toNativeUtf8().cast(),
      // TODO: use the actual commit message
      "test".toNativeUtf8().cast(),
      tree.value,
      1,
      parent,
    ));

    App.git.git_signature_free(signature.value);
    App.git.git_tree_free(tree.value);
    
    // TODO: make it functional
    // push
    // ffi.Pointer<ffi.Pointer<git_remote>> remote = ffi.calloc();
    // ffi.Pointer<git_push_options> defaultOptions = ffi.calloc();
    // // var refspecsArray = const ffi.Array<git_strarray>(1);
    // ffi.Pointer<git_strarray> refspecs = ffi.calloc<git_strarray>();
    // refspecs.ref.count = 1;
    // refspecs.ref.strings.value = "refs/heads/master".toNativeUtf8().cast();

    // print(App.git.git_remote_lookup(remote, App.pedigree!.repo.value, "origin".toNativeUtf8().cast()));
    // print(App.git.git_push_options_init(defaultOptions, GIT_PUSH_OPTIONS_VERSION));
    // print(App.git.git_remote_push(remote.value, refspecs, defaultOptions));

    
    // App.git.git_index_free(index.value);
  }
}

Future<CommitSheet?> showCommitSheet(BuildContext context) {
  return showModalBottomSheet<CommitSheet>(
    context: context,
    showDragHandle: true,
    builder: (context) => const CommitSheet(),
  );
}