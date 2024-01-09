import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:dpc/main.dart';
import 'package:dpc/pages/screens/file.dart';
import 'package:dpc/secrets.dart';
import 'package:ffi/ffi.dart' as ffi;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class CloneRepoSheet extends StatefulWidget {
  const CloneRepoSheet({super.key});

  @override
  State<CloneRepoSheet> createState() => _CloneRepoSheetState();

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const CloneRepoSheet(),
      ),
    );
  }
}

class _CloneRepoSheetState extends State<CloneRepoSheet> {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController pathController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController repoNameController = TextEditingController();
  String? error;
  DownloadHandle? isolateHandle;
  CloneProgress? progress;
  AuthOptions selectedAuthOption = AuthOptions.github;

  bool get inProgress => progress != null && error == null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: SegmentedButton<AuthOptions>(
                segments: const [
                  ButtonSegment(
                    icon: Icon(Icons.cloud_outlined),
                    value: AuthOptions.github,
                    label: Text("Github"),
                  ),
                  ButtonSegment(
                    icon: Icon(Icons.settings_outlined),
                    value: AuthOptions.manual,
                    label: Text("Vlastní URL"),
                  ),
                ],
                selected: { selectedAuthOption },
                onSelectionChanged: (selection) => setState(() {
                  selectedAuthOption = selection.first;
                }),
              ),
            ),
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
                  if(Platform.isAndroid && !dir.existsSync()) {
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
            if(selectedAuthOption == AuthOptions.manual) Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.link),
                  labelText: "URL Adresa vzdáleného repozitáře",
                  errorMaxLines: 5,
                  border: OutlineInputBorder(),
                ),
                enabled: selectedAuthOption == AuthOptions.manual,
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
            if(selectedAuthOption == AuthOptions.github) Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextFormField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.share_outlined),
                  labelText: "Jméno repozitáře",
                  border: OutlineInputBorder(),
                ),
                enabled: selectedAuthOption == AuthOptions.github,
                controller: repoNameController,
                validator: (value) {
                  if(value == null || value.trim().isEmpty) {
                    return "Vyberte si repozitář";
                  }

                  final split = value.split("/");
                  if(split.length < 2) {
                    return "Uveďte prosím vlastníka repozitáře, ve formátu vlastník/repozitář";
                  }

                  if(split.length > 2) {
                    return "Uveďte prosím pouze repozitář a vlastníka. Možná zkuste: ${split[split.length - 2]}/${split[split.length - 1]}";
                  }

                  return null;
                },
              ),
            ),
            if(error != null) Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 8),
                    child: Text(
                    error!,
                    softWrap: true,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  if(progress?.bytes != null) Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text("${((progress!.bytes ?? 0) / 1048576).round()} MiB"),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      // i didn't use `onErrorContainer` for the indicator because it is in contact with `surface` a lot more than with `errorContainer`
                      color: error == null ? null : Theme.of(context).colorScheme.error,
                      backgroundColor: error == null ? null : Theme.of(context).colorScheme.errorContainer,
                      value: progress?.ratio ?? 0,
                    ),
                  ),
                  if(progress != null) Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text("${(progress!.ratio * 100).round().toString().padLeft(1, "0")} %"),
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
                        if(!inProgress || isolateHandle == null) {
                          Navigator.of(context).pop();
                          return;
                        }

                        isolateHandle!.abort();
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
                      onPressed: inProgress ? null : () async {
                        // TODO: check file permissions before asking
                        if(Platform.isAndroid && !await Permission.manageExternalStorage.isGranted) {
                          if((await Permission.manageExternalStorage.request()).isGranted) {
                            error = "oprávnění zamítnuto";
                          }
                        }

                        if(!Platform.isAndroid) {
                          try {
                            File(pathController.text).createSync(recursive: true);
                          } on Exception catch(e) {
                            error = "nelze vytvořit složku. Zkuste ji vytvořit sami: $e";
                          }
                        }

                        if(!formKey.currentState!.validate()) return;

                        error = null;
                        final Uri url;
                        final String name;
                        String? email;
                        setState(() => progress = CloneProgress(ratio: 0));
                        switch (selectedAuthOption) {
                          case AuthOptions.manual:
                            url = Uri.parse(urlController.text);
                            name = url.userInfo.split(":")[0];
                            break;
                          case AuthOptions.github:
                            final String token;
                            try {
                                token = await githubOauth();
                                name = await githubUsername(token);
                                email = await githubEmail(token);
                            } catch (e) {
                                setState(() {
                                    // TODO: display less of the error, make a way to report it
                                    error = e.toString();
                                });
                                return;
                            }
                            url = Uri(
                              scheme: "https",
                              host: "github.com",
                              userInfo: "$name:$token",
                              path: repoNameController.text.endsWith(".git") ? repoNameController.text : "${repoNameController.text}.git",
                            );
                            debugPrint("repo url: $url");
                            break;
                        }

                        startDownload(context, url.toString(), name, email);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      icon: Icon(error != null ? Icons.restart_alt : Icons.download_for_offline_outlined),
                      label: Text(error != null ? "Zkusit znovu" : selectedAuthOption == AuthOptions.manual ? "Stáhnout" : "Přihlásit se a stáhnout"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startDownload(BuildContext context, String url, String name, String? email) async {
    final handle = await spawnDownload(context, url, pathController.text, name, email);

    isolateHandle = handle;

    handle.progressReceiver.listen((message) async {
      // TODO: log error when message is of a wrong type
      // this gives false positives
      // assert(message is! CloneProgress, "a message sent by the clone isolate is not a CloneProgress: $message");

      if(context.mounted) {
        if(message.ratio == 1 && await Navigator.of(context).maybePop(pathController.text)) {
          return;
        }
        setState(() {
          progress = message;
        });
      }
    });

    handle.errorReceiver.listen((message) {
      final String errorString = (message as List)[0];
      // the error receiver message type is just fucking hilariously stupid, but still:
      // TODO: find a better way to get the error code

      setState(() {
        if(errorString.contains(git_error_code.GIT_EUSER.toString())) {
          error = "Zrušeno";
        } else {
          error = errorString;
        }
      });

      // TODO: make a way to report the error
    });
  }

  Future<String> githubOauth() async {
    final codeCompleter = Completer<String>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080, shared: true);
    server.forEach((req) {
      req.response.headers.contentType = ContentType.html;
      req.response.write("<script>window.close()</script><h1>Nyní můžete toto okno zavřít</h1>");
      req.response.close();
      server.close();
      if(!req.uri.queryParameters.containsKey("code")) {
        codeCompleter.completeError(req.uri.queryParameters);
      }
      codeCompleter.complete(req.uri.queryParameters["code"]);
    });
    final authorizationUri = Uri(
      scheme: "https",
      host: "github.com",
      path: "/login/oauth/authorize",
      queryParameters: {
        "client_id": "d484387b4d7fa68eb87f",
        "redirect_uri": "http://localhost:8080",
        "scope": "repo,user:email",
      }
    );
    await launchUrl(authorizationUri);
    final code = await codeCompleter.future;

    final tokenResponse = await http.post(Uri(
      scheme: "https",
      host: "github.com",
      path: "login/oauth/access_token",
      queryParameters: {
        "client_id": "d484387b4d7fa68eb87f",
        "client_secret": githubClientSecret,
        "code": code,
      }
    ), headers: {"Accept": "application/json"});
    final tokenResponseValues = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    assert(
      tokenResponseValues.containsKey("access_token"),
      "error when requesting token: ${tokenResponseValues["error"] ?? tokenResponseValues.toString()}"
    );
    return tokenResponseValues["access_token"];
  }

  Future<String> githubUsername(String token) async {
    final res = await http.get(Uri(
      scheme: "https",
      host: "api.github.com",
      path: "user",
    ), headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
      "X-GitHub-Api-Version": "2022-11-28",
    });
    final resValues = jsonDecode(res.body) as Map<String, dynamic>;
    assert(
      resValues.containsKey("login"),
      "error when requesting token: ${resValues["error"] ?? resValues.toString()}"
    );
    return resValues["login"];
  }

  Future<String?> githubEmail(String token) async {
    final res = await http.get(Uri(
      scheme: "https",
      host: "api.github.com",
      path: "user/emails",
    ), headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
      "X-GitHub-Api-Version": "2022-11-28",
    });
    final _resValues = jsonDecode(res.body);
    assert(
      _resValues is List<dynamic>,
      "error when requesting token: ${(_resValues is Map ? _resValues["message"] : null) ?? _resValues.toString()}"
    );
    final resValues = _resValues as List<dynamic>;
    final email = resValues.firstWhere(
      (email) => email is Map && (email["primary"] as bool? ?? false),
      orElse: () => resValues.elementAtOrNull(0)
    );
    return email?["email"];
  }
}

class DownloadIsolateMessage {
  const DownloadIsolateMessage({
    required this.sender,
    required this.url,
    required this.path,
    required this.abortPtr,
    required this.name,
    this.email,
  });

  final SendPort sender;
  final String url;
  final String path;
  final int abortPtr;
  final String name;
  final String? email;
}

// im sorry for sharing memory between isolates, i just wasn't able to use a simple receive port.
// TODO: rework repo cloning without sharing memory

int _fetchProgressCallback(ffi.Pointer<git_indexer_progress> progress, ffi.Pointer<ffi.Void> payloadPtr) {
  final payload = (payloadPtr as ffi.Pointer<ProgressCallbackPayload>).ref;
  final sender = IsolateNameServer.lookupPortByName(payload.nativeSender.toString());
  sender?.send(CloneProgress(
    ratio: progress.ref.received_objects / progress.ref.total_objects,
    bytes: progress.ref.received_bytes,
  ));

  final ffi.Pointer<ffi.Bool> abort = ffi.Pointer.fromAddress(payload.abortPtr);
  return abort.value ? git_error_code.GIT_EUSER : 0;
}

void _checkoutProgressCallback(ffi.Pointer<ffi.Char> path, int current, int total, ffi.Pointer<ffi.Void> payloadPtr) {
  final payload = (payloadPtr as ffi.Pointer<ProgressCallbackPayload>).ref;
  final sender = IsolateNameServer.lookupPortByName(payload.nativeSender.toString());
  sender?.send(CloneProgress(
    ratio: current / total,
  ));
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

const minusOne = -1;
void _isolateEntryPoint(DownloadIsolateMessage message) async {
  // final abortReceiver = ReceivePort();
  // message.sender.send(abortReceiver.sendPort);

  // TODO: free variables
  ffi.Pointer<ffi.Pointer<git_repository>> repo = ffi.calloc();
  ffi.Pointer<git_clone_options> options = ffi.calloc();
  final fetchCallback = ffi.Pointer.fromFunction<ffi.Int Function(ffi.Pointer<git_indexer_progress>, ffi.Pointer<ffi.Void>)>(_fetchProgressCallback, 0);
  final checkoutCallback = ffi.Pointer.fromFunction<ffi.Void Function(ffi.Pointer<ffi.Char>, ffi.Size, ffi.Size, ffi.Pointer<ffi.Void>)>(_checkoutProgressCallback);
  final badCertCallback = ffi.Pointer.fromFunction<ffi.Int Function(ffi.Pointer<git_cert>, ffi.Int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>)>(_badCertificateCallback, minusOne);
  ffi.Pointer<ffi.Bool> abort = ffi.Pointer.fromAddress(message.abortPtr);
  ffi.Pointer<ProgressCallbackPayload> payload = ffi.calloc();
  message.sender.send(CloneProgress(ratio: 0));

  expectCode(App.git.git_clone_options_init(options, GIT_CLONE_OPTIONS_VERSION), "chyba při nastavování výchozího nastavení");
  // TODO: try to use less confusing identifier than nativePort
  IsolateNameServer.registerPortWithName(message.sender, message.sender.nativePort.toString());
  payload.ref.nativeSender = message.sender.nativePort;
  payload.ref.abortPtr = abort.address;
  options.ref.checkout_opts.progress_payload = payload.cast();
	options.ref.checkout_opts.progress_cb = checkoutCallback;
  options.ref.fetch_opts.callbacks.payload = payload.cast();
  options.ref.fetch_opts.callbacks.transfer_progress = fetchCallback;
  options.ref.fetch_opts.callbacks.certificate_check = badCertCallback;

  expectCode(App.git.git_clone(
    repo,
    message.url.toNativeUtf8().cast(),
    message.path.toNativeUtf8().cast(),
    options,
  ), "nelze stáhnout repozitář");

  saveDefaultSignature(
    repo.value, message.name.toNativeUtf8().cast(), message.email?.toNativeUtf8().cast(),
  );

  message.sender.send(CloneProgress(ratio: 1));
}

Future<DownloadHandle> spawnDownload(BuildContext context, String url, String path, String name, String? email) async {
  final progressReceiver = ReceivePort();
  final errorReceiver = ReceivePort();
  // TODO: free pointer
  final ffi.Pointer<ffi.Bool> abortPtr = ffi.calloc();
  await Isolate.spawn<DownloadIsolateMessage>(
    _isolateEntryPoint,
    DownloadIsolateMessage(
      sender: progressReceiver.sendPort,
      url: url,
      path: path,
      abortPtr: abortPtr.address,
      name: name,
      email: email,
    ),
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

final class CloneProgress {
  CloneProgress({required this.ratio, this.bytes});
  double ratio;
  int? bytes;
}

class DownloadHandle {
  const DownloadHandle(this.abort, this.progressReceiver, this.errorReceiver);

  final void Function() abort;

  final ReceivePort progressReceiver;
  final ReceivePort errorReceiver;
}

enum AuthOptions {
  manual,
  github,
}
