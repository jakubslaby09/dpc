import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:dpc/main.dart';
import 'package:dpc/pages/log.dart';
import 'package:dpc/pages/screens/file.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

// TODO: save commit message draft
class CommitSheet extends StatefulWidget {
  const CommitSheet({super.key});

  static Future<CommitSheet?> show(BuildContext context) {
    return showModalBottomSheet<CommitSheet>(
      context: context,
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const CommitSheet(),
      ),
    );
  }

  @override
  State<CommitSheet> createState() => _CommitSheetState();
}

class _CommitSheetState extends State<CommitSheet> {
  final commitMessageController = TextEditingController();
  final commitDesctiptionController = TextEditingController();
  late ExpansionTileController signatureTileController = ExpansionTileController();
  final formKey = GlobalKey<FormState>();
  String? error;
  bool saveSignature = true;
  // TODO: add an option to override it
  late ffi.Pointer<git_signature>? defaultSignature = readDefaultSignature(App.pedigree!.repo);
  late final authorNameController = TextEditingController(text: defaultSignature?.ref.name.toDartString());
  late final authorEmailController = TextEditingController(text: defaultSignature?.ref.email.toDartString());

  // TODO: commit message field validation
  String get wholeCommitMessage => "${commitMessageController.text}\n${commitDesctiptionController.text}";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text("Zveřejnit změny", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: TextFormField(
                controller: commitMessageController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.message_outlined),
                  labelText: "Zpráva příspěvku",
                ),
                validator: (value) {
                  if(value == null || value.trim().isEmpty) {
                    return "Napište k příspěvku zprávu";
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: TextFormField(
                controller: commitDesctiptionController,
                minLines: 2,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  icon: Icon(Icons.more_horiz),
                  labelText: "Popis příspěvku",
                ),
              ),
            ),
            ExpansionTile(
              controller: signatureTileController,
              leading: const Icon(Icons.contact_mail_outlined),
              title: const Text("Podpis autora"),
              maintainState: true,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: TextFormField(
                    controller: authorNameController,
                    decoration: const InputDecoration(
                      labelText: "Jméno autora příspěvku",
                      icon: Icon(Icons.contact_mail_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if(value == null || value.trim().isEmpty) {
                        signatureTileController.expand();
                        return "Zvolte si jméno autora";
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                  child: TextFormField(
                    controller: authorEmailController,
                    decoration: const InputDecoration(
                      labelText: "Email autora příspěvku",
                      icon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // TODO: check if email is valid
                      if(value == null || value.trim().isEmpty) {
                        signatureTileController.expand();
                        return "Zadejte prosím email autora";
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: CheckboxListTile(
                    title: const Text("Zapamatovat"),
                    value: saveSignature,
                    onChanged: (value) => setState(() {
                      // TODO: examine when value is null
                      if(value != null) saveSignature = value;
                    }),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                error ?? "",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text("Zahodit"),
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if(!formKey.currentState!.validate()) {
                          return;
                        }

                        commit(context, customSignature());
                      },
                      icon: const Icon(Icons.send_outlined),
                      label: const Text("Potvrdit"),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
  // TODO: Close upon success, reload App.unchangedPedigree and the commit page
  // TODO: free memory
  void commit(BuildContext context, ffi.Pointer<git_signature> signature) {
    print(signature.ref.email.toDartString());
    setState(() => error = null);
    try {
      assert(App.pedigree != null, "this should be checked in home.dart");
      App.pedigree!.save(context);

      ffi.Pointer<ffi.Pointer<git_index>> index = ffi.calloc();
      expectCode(App.git.git_repository_index(index, App.pedigree!.repo));

      // add
      expectCode(App.git.git_index_add_bypath(index.value, "index.dpc".toNativeUtf8().cast()));
      expectCode(App.git.git_index_write(index.value));

      // commit
      ffi.Pointer<git_oid> parentOid = ffi.calloc();
      ffi.Pointer<ffi.Pointer<git_commit>> parent = ffi.calloc();
      ffi.Pointer<git_oid> treeOid = ffi.calloc();
      ffi.Pointer<git_oid> commitOid = ffi.calloc();
      ffi.Pointer<ffi.Pointer<git_tree>> tree = ffi.calloc();

      expectCode(App.git.git_index_write_tree(treeOid, index.value));
      expectCode(App.git.git_index_write(index.value));
      expectCode(App.git.git_tree_lookup(tree, App.pedigree!.repo, treeOid));
      expectCode(App.git.git_reference_name_to_id(parentOid, App.pedigree!.repo, "HEAD".toNativeUtf8().cast()));
      expectCode(App.git.git_commit_lookup(parent, App.pedigree!.repo, parentOid));
      expectCode(App.git.git_commit_create(
        commitOid,
        App.pedigree!.repo,
        "HEAD".toNativeUtf8().cast(),
        signature,
        // ffi.nullptr,
        signature,
        "UTF-8".toNativeUtf8().cast(),
        wholeCommitMessage.toNativeUtf8().cast(),
        tree.value,
        1,
        parent,
      ), "couldn't create commit");

      App.git.git_tree_free(tree.value);
      
      // TODO: display progress with int callback(int current, int total, int bytes, ffi.Pointer<ffi.Void> payload)
      // push
      ffi.Pointer<ffi.Pointer<git_remote>> remote = ffi.calloc();
      ffi.Pointer<git_push_options> pushOptions = ffi.calloc();
      ffi.Pointer<git_strarray> refspecs = ffi.calloc<git_strarray>();
      ffi.Pointer<ffi.Pointer<ffi.Char>> refspecsArray = ffi.calloc();
      // TODO: use git_remote_get_refspec
      refspecsArray[0] = "refs/heads/main".toNativeUtf8().cast();
      refspecs.ref.strings = refspecsArray;
      refspecs.ref.count = 1;
      ffi.Pointer<ffi.Pointer<git_config>> config = ffi.calloc();
      final badCertCallback = ffi.Pointer.fromFunction<ffi.Int Function(ffi.Pointer<git_cert>, ffi.Int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>)>(_badCertificateCallback, minusOne);

      expectCode(
        App.git.git_remote_lookup(remote, App.pedigree!.repo, "origin".toNativeUtf8().cast()),
        "nelze zjistit, kam změny poslat",
      );
      expectCode(App.git.git_push_options_init(pushOptions, GIT_PUSH_OPTIONS_VERSION));
      pushOptions.ref.callbacks.certificate_check = badCertCallback;
      print("git_remote_push");
      print(remote);
      print(refspecs);
      print(pushOptions);
      expectCode(App.git.git_remote_push(remote.value, refspecs, pushOptions));
      
      try {
        expectCode(App.git.git_repository_config(config, App.pedigree!.repo), "nelze číst z configu repozitáře");
        expectCode(
          App.git.git_config_set_string(config.value, "user.name".toNativeUtf8().cast(), signature.ref.name),
          "nelze uložit jméno v configu repozitáře",
        );
        expectCode(
          App.git.git_config_set_string(config.value, "user.email".toNativeUtf8().cast(), signature.ref.email),
          "nelze uložit email v configu repozitáře",
        );
      } on Exception catch (e) {
        // TODO: close so the user doesn't commit again and call showException
      }
    } on Exception catch(e) {
      // TODO: fix unmouned context
      // showException(context, "Nepodařilo se zveřejnit Vaše změny", e, t);
      setState(() => error = "Nepodařilo se zveřejnit Vaše změny: $e");
      rethrow;
    }
    
    App.git.git_signature_free(signature);
  }

  ffi.Pointer<git_signature>? readDefaultSignature(ffi.Pointer<git_repository> repo) {
    ffi.Pointer<ffi.Pointer<git_signature>> signature = ffi.calloc();
    
    // TODO: display errors other than ENOTFOUND
    final int result = App.git.git_signature_default(signature, repo);
    print(result);
    
    return result == 0 ? signature.value : null;
  }

  ffi.Pointer<git_signature> customSignature() {
    ffi.Pointer<ffi.Pointer<git_signature>> signature = ffi.calloc();

    expectCode(App.git.git_signature_now(
      signature,
      authorNameController.text.toNativeUtf8().cast(),
      authorEmailController.text.toNativeUtf8().cast(),
    ));
    return signature.value;
  }
}

const minusOne = -1;
int _badCertificateCallback(ffi.Pointer<git_cert> cert, int valid, ffi.Pointer<ffi.Char> host, ffi.Pointer<ffi.Void> payloadPtr) {
  if(Platform.isAndroid) {
    // TODO: don't do such a stupid thing
    print("ignoring a bad certificate");
    return 0;
  }
  // TODO: ask the user
  return 1;
}