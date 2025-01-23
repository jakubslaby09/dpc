import 'dart:io';

import 'package:dpc/strings/strings.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class CreateRepoSheet extends StatefulWidget {
  CreateRepoSheet(this.directory, {super.key})
  : repoDirState = checkNewRepoDir(directory);

  final Directory directory;
  final NewRepoDirResult repoDirState;

  @override
  State<CreateRepoSheet> createState() => _CreateRepoSheetState();

  static Future<CreateRepoSheetResult?> show(BuildContext context, Directory directory) {
    return showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: CreateRepoSheet(directory),
      ),
    );
  }
}

// TODO: make it async
NewRepoDirResult checkNewRepoDir(Directory dir) {
    try {
        return dir.listSync().isEmpty ? NewRepoDirState.empty : NewRepoDirState.full;
    } on PathAccessException catch (e) {
        return NewRepoDirException(e.path, e.osError);
    }
}

// TODO: add a field for setting a remote, push the repo there
class _CreateRepoSheetState extends State<CreateRepoSheet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dirController = TextEditingController();
  final TextEditingController subdirController = TextEditingController();
  final TextEditingController commitMessageController = TextEditingController();
  final TextEditingController gitNameController = TextEditingController();
  final TextEditingController gitEmailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    dirController.text = wholeDirectory;
    commitMessageController.text = S(context).createRepoDefaultCommitMessage;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              if(widget.repoDirState is NewRepoDirException) Card(
                margin: const EdgeInsets.only(bottom: 24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outlined),
                  title: Text(S(context).createRepoCouldNotAccessDir),
                ),
              ),
              // TODO: add an override button
              if(widget.repoDirState == NewRepoDirState.full) Card(
                margin: const EdgeInsets.only(bottom: 24),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(S(context).createRepoDirtyDir),
                ),
              ),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.face_2_outlined),
                  labelText: S(context).createRepoChronicleNameLabel,
                  hintText: S(context).createRepoChronicleNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? S(context).createRepoMissingName : null,
              ),
              const Divider(color: Colors.transparent),
              // TODO: add a button to change the repo directory
              TextField(
                controller: dirController,
                decoration: InputDecoration(
                  icon: Icon(widget.repoDirState == NewRepoDirState.full ? Icons.folder_outlined : Icons.create_new_folder_outlined),
                  labelText: widget.repoDirState == NewRepoDirState.full ?  S(context).createRepoDirWithSubdirName : S(context).createRepoDirName,
                  border: const OutlineInputBorder(),
                ),
                enabled: false,
              ),
              if(widget.repoDirState == NewRepoDirState.full) const Divider(color: Colors.transparent),
              if(widget.repoDirState == NewRepoDirState.full) TextFormField(
                controller: subdirController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.create_new_folder_outlined),
                  labelText: S(context).createRepoSubirName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? S(context).createRepoMissingSubdirName : null,
                onChanged: (_) => setState(() {}),
              ),
              const Divider(color: Colors.transparent),
              TextFormField(
                controller: commitMessageController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.commit),
                  labelText: S(context).createRepoCommitMessage,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? S(context).createRepoMissingCommitMessage : null,
              ),
              // TODO: add an option to use git_signature_default
              const Divider(color: Colors.transparent),
              TextFormField(
                controller: gitNameController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.contact_mail_outlined),
                  labelText: S(context).createRepoSignatureName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? S(context).createRepoMissingSignatureName : null,
              ),
              const Divider(color: Colors.transparent),
              TextFormField(
                controller: gitEmailController,
                decoration: InputDecoration(
                  icon: const Icon(Icons.email_outlined),
                  labelText: S(context).createRepoSignatureEmail,
                  border: const OutlineInputBorder(),
                ),
                // TODO: validate with email_validator
                validator: (value) => value?.trim().isEmpty ?? false ? S(context).createRepoMissingSignatureEmail : null,
              ),
              // TODO: add an option to push the repo after creation
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(S(context).createRepoAbort),
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.repoDirState is NewRepoDirException ? null : () => setState(() {
                          if(!formKey.currentState!.validate()) return;
                          Navigator.of(context).pop(CreateRepoSheetResult(
                            nameController.text,
                            wholeDirectory,
                            commitMessageController.text,
                            gitNameController.text,
                            gitEmailController.text,
                          ));
                        }),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        icon: const Icon(Icons.cake_outlined),
                        label: Text(S(context).createRepoConfirm),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get wholeDirectory => widget.repoDirState == NewRepoDirState.full ? p.join(widget.directory.path, subdirController.text) : widget.directory.path;
}

class CreateRepoSheetResult {
  const CreateRepoSheetResult(this.name, this.dir, this.commitMessage, this.gitName, this.gitEmail);

  final String name;
  final String dir;
  final String commitMessage;
  final String gitName;
  final String gitEmail;
}

abstract class NewRepoDirResult {}

enum NewRepoDirState implements NewRepoDirResult {
  empty,
  full,
}

class NewRepoDirException extends PathAccessException implements NewRepoDirResult {
    const NewRepoDirException(String? path, OSError? error) : super(path ?? "", error ?? const OSError());
}

