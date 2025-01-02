import 'package:dpc/strings/strings.dart';

class Czech implements S {
  @override
  String get noFileOpenNotice => "Nemáte otevřený repozitář s rodokmenem.\nNa první stránce ho můžete otevřít, nebo založit nový.";
  
  @override
  // TODO: implement noFileOpenButton
  String get noFileOpenButton => "Přejít na první stránku";
}