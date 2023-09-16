import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:dpc/main.dart';
import 'package:dpc/pages/screens/file.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

class CloneRepoSheet extends StatefulWidget {
  const CloneRepoSheet({super.key});

  @override
  State<CloneRepoSheet> createState() => _CloneRepoSheetState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      context: context,
      builder: (context) => const CloneRepoSheet(),
    );
  }
}

class _CloneRepoSheetState extends State<CloneRepoSheet> {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController pathController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  String? error;
  DownloadHandle? isolateHandle;
  double? progress;

  bool get finished => progress == 1.0 || error != null;
  bool get inProgress => progress != null && !finished;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: TextFormField(
              decoration: InputDecoration(
                icon: const Icon(Icons.file_copy_outlined),
                labelText: "Složka repozitáře",
                border: const OutlineInputBorder(),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.file_open_outlined),
                    onPressed: () async {
                      final dir = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: "Vybrat novou složku pro repozitář",
                      );
                      if(dir == null) return;
                      pathController.text = dir;
                    },
                  ),
                ),
              ),
              controller: pathController,
              // TODO: make the validator async
              validator: (value) {
                if(value == null || value.trim().isEmpty) {
                  return "Vyberte si, kam repozitář stáhnete";
                }
                final dir = Directory(value);
                if(!dir.existsSync()) {
                  // TODO: can't i just create the fucking folder for the user?
                  return "Taková složka neexistuje. Nezapoměli jste ji vytvořit?";
                }
                if(dir.listSync().isNotEmpty) {
                  // TODO: add ui to override this check
                  return "Složka není prázdná";
                }
                // TODO: check write permissions
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.link),
                labelText: "URL Adresa vzdáleného repozitáře",
                errorMaxLines: 5,
                border: OutlineInputBorder(),
              ),
              controller: urlController,
              // TODO: make the validator async
              validator: (value) {
                if(value == null || value.trim().isEmpty) {
                  return "Vyberte si, odkud repozitář stáhnete";
                }
                if(!(Uri.tryParse(value)?.isAbsolute ?? false)) {
                  return "Toto nevypadá jako URL, ani jako absolutní URI";
                }
                final uri = Uri.parse(value);
                if(uri.userInfo.isNotEmpty && !uri.userInfo.contains(":")) {
                  return "Adresa obsahuje '@', ale ne ':'. Použijte prosím formát jméno:${uri.userInfo}";
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                if(error != null) Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    // i didn't use `onErrorContainer` for the indicator because it is in contact with `surface` a lot more than with `errorContainer`
                    color: error == null ? null : Theme.of(context).colorScheme.error,
                    backgroundColor: error == null ? null : Theme.of(context).colorScheme.errorContainer,
                    value: progress ?? 0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text("${((progress ?? 0) * 100).round()} %"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      if(!inProgress) {
                        Navigator.of(context).pop();
                        return;
                      }
                      
                      isolateHandle?.abort();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: Icon(inProgress ? Icons.disabled_by_default_outlined : Icons.cancel_outlined),
                    label: Text(inProgress ? "Přerušit" : "Zahodit"),
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setState(() {
                      if(!formKey.currentState!.validate()) return;

                      error = null;

                      startDownload(context);
                    }),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: Icon(error != null ? Icons.restart_alt : Icons.download_for_offline_outlined),
                    label: Text(error != null ? "Zkusit znovu" : "Stáhnout"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void startDownload(BuildContext context) async {
    final handle = await spawnDownload(context, urlController.text, pathController.text);

    isolateHandle = handle;

    handle.progressReceiver.listen((message) { 
      if(context.mounted) {
        setState(() {
          progress = message;
        });
      }
    });

    handle.errorReceiver.listen((message) {
      final String errorString = (message as List)[0];
      // the error receiver message type is just fucking hilariously stupid, but still:
      // TODO: find a better way to get the error code
      if(errorString.contains(git_error_code.GIT_EUSER.toString())) {
        error = "Zrušeno";
      } else {
        error = errorString;
      }

      // TODO: make a way to report the error
    });
  }
}

class DownloadIsolateMessage {
  const DownloadIsolateMessage(this.sender, this.url, this.path, this.abortPtr);

  final SendPort sender;
  final String url;
  final String path;
  final int abortPtr;
}

// im sorry for sharing memory between isolates, i just wasn't able to use a simple receive port.
// TODO: rework repo cloning without sharing memory

int _fetchProgressCallback(ffi.Pointer<git_indexer_progress> progress, ffi.Pointer<ffi.Void> payloadPtr) {
  final payload = (payloadPtr as ffi.Pointer<ProgressCallbackPayload>).ref;
  final sender = IsolateNameServer.lookupPortByName(payload.nativeSender.toString());
  sender?.send(progress.ref.received_objects / progress.ref.total_objects);

  final ffi.Pointer<ffi.Bool> abort = ffi.Pointer.fromAddress(payload.abortPtr);
  return abort.value ? git_error_code.GIT_EUSER : 0;
}

void _checkoutProgressCallback(ffi.Pointer<ffi.Char> path, int current, int total, ffi.Pointer<ffi.Void> payloadPtr) {
  final payload = (payloadPtr as ffi.Pointer<ProgressCallbackPayload>).ref;
  final sender = IsolateNameServer.lookupPortByName(payload.nativeSender.toString());
  sender?.send(current / total);
}

void _isolateEntryPoint(DownloadIsolateMessage message) async {
  // final abortReceiver = ReceivePort();
  // message.sender.send(abortReceiver.sendPort);

  // TODO: free variables
  ffi.Pointer<ffi.Pointer<git_repository>> repo = ffi.calloc();
  ffi.Pointer<git_clone_options> options = ffi.calloc();
  final fetchCallback = ffi.Pointer.fromFunction<ffi.Int Function(ffi.Pointer<git_indexer_progress>, ffi.Pointer<ffi.Void>)>(_fetchProgressCallback, 0);
  final checkoutCallback = ffi.Pointer.fromFunction<ffi.Void Function(ffi.Pointer<ffi.Char>, ffi.Size, ffi.Size, ffi.Pointer<ffi.Void>)>(_checkoutProgressCallback);
  ffi.Pointer<ffi.Bool> abort = ffi.Pointer.fromAddress(message.abortPtr);
  ffi.Pointer<ProgressCallbackPayload> payload = ffi.calloc();
  message.sender.send(0.0);
  
  expectCode(App.git.git_clone_options_init(options, GIT_CLONE_OPTIONS_VERSION), "chyba při nastavování výchozího nastavení");
  // TODO: try to use less confusing identifier than nativePort
  IsolateNameServer.registerPortWithName(message.sender, message.sender.nativePort.toString());
  payload.ref.nativeSender = message.sender.nativePort;
  payload.ref.abortPtr = abort.address;
  options.ref.checkout_opts.progress_payload = payload.cast();
	options.ref.checkout_opts.progress_cb = checkoutCallback;
  options.ref.fetch_opts.callbacks.transfer_progress = fetchCallback;
  options.ref.fetch_opts.callbacks.payload = payload.cast();

  expectCode(App.git.git_clone(
    repo,
    message.url/* "https://github.com/jakubslaby09/rust-ytmapi.git" */.toNativeUtf8().cast(),
    message.path/* "/home/jakub/Projekty/dpc/test2" */.toNativeUtf8().cast(),
    options,
  ));

  message.sender.send(1.0);
}

Future<DownloadHandle> spawnDownload(BuildContext context, String url, String path) async {
  final progressReceiver = ReceivePort();
  final errorReceiver = ReceivePort();
  // TODO: free pointer
  final ffi.Pointer<ffi.Bool> abortPtr = ffi.calloc();
  await Isolate.spawn<DownloadIsolateMessage>(
    _isolateEntryPoint,
    DownloadIsolateMessage(progressReceiver.sendPort, url, path, abortPtr.address),
    onError: errorReceiver.sendPort,
  );

  return DownloadHandle(
    () => abortPtr.value = true,
    progressReceiver,
    errorReceiver,
  );
}

final class ProgressCallbackPayload extends ffi.Struct {
  @ffi.Int64()
  external int abortPtr;
  
  @ffi.Int64()
  external int nativeSender;
}

class DownloadHandle {
  const DownloadHandle(this.abort, this.progressReceiver, this.errorReceiver);

  final void Function() abort;

  final ReceivePort progressReceiver;
  final ReceivePort errorReceiver;
}