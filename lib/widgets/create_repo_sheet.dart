import 'dart:io';

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
  final TextEditingController commitMessageController = TextEditingController(text: "Vytvořit repozitář");
  final TextEditingController gitNameController = TextEditingController();
  final TextEditingController gitEmailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    dirController.text = wholeDirectory;

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
                child: const ListTile(
                  leading: Icon(Icons.error_outlined),
                  title: Text("Nelze přistupovat ke složce, kterou jste vybrali"),
                ),
              ),
              // TODO: add an override button
              if(widget.repoDirState == NewRepoDirState.full) Card(
                margin: const EdgeInsets.only(bottom: 24),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const ListTile(
                  leading: Icon(Icons.warning_amber_outlined),
                  title: Text("Složka, kterou jste vybrali, není prázdná. Bude tedy vytvořena podsložka."),
                ),
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.face_2_outlined),
                  labelText: "Jméno kroniky",
                  hintText: "Novákovi",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? "Zvolte si jméno kroniky" : null,
              ),
              const Divider(color: Colors.transparent),
              // TODO: add a button to change the repo directory
              TextField(
                controller: dirController,
                decoration: InputDecoration(
                  icon: Icon(widget.repoDirState == NewRepoDirState.full ? Icons.folder_outlined : Icons.create_new_folder_outlined),
                  labelText: widget.repoDirState == NewRepoDirState.full ? "Cesta k novému repozitáři" : "Složka nového repozitáře",
                  border: const OutlineInputBorder(),
                ),
                enabled: false,
              ),
              if(widget.repoDirState == NewRepoDirState.full) const Divider(color: Colors.transparent),
              if(widget.repoDirState == NewRepoDirState.full) TextFormField(
                controller: subdirController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.create_new_folder_outlined),
                  labelText: "Jméno složky repozitáře",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? "Zvolte si jméno nové složky" : null,
                onChanged: (_) => setState(() {}),
              ),
              const Divider(color: Colors.transparent),
              TextFormField(
                controller: commitMessageController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.commit),
                  labelText: "Zpráva prvního příspěvku",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? "Zvolte si jméno kroniky" : null,
              ),
              // TODO: add an option to use git_signature_default
              const Divider(color: Colors.transparent),
              TextFormField(
                controller: gitNameController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.contact_mail_outlined),
                  labelText: "Jméno autora příspěvku",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty ?? false ? "Napište prosím jméno autora" : null,
              ),
              const Divider(color: Colors.transparent),
              TextFormField(
                controller: gitEmailController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.email_outlined),
                  labelText: "Email autora příspěvku",
                  border: OutlineInputBorder(),
                ),
                // TODO: validate with email_validator
                validator: (value) => value?.trim().isEmpty ?? false ? "Napište prosím email autora" : null,
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
                        label: const Text("Zahodit"),
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
                        label: const Text("Vytvořit"),
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

