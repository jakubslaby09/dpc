import 'package:dpc/strings/strings.dart';

class Czech implements S {
  @override String get noFileOpenNotice => "Nemáte otevřený repozitář s rodokmenem.\nNa první stránce ho můžete otevřít, nebo založit nový.";  
  @override String get noFileOpenButton => "Přejít na první stránku";  
  @override String get navFilesPage => "Soubor";
  @override String get navListPage => "Seznam";
  @override String get navChroniclePage => "Kronika";
  @override String get navCommitPage => "Změny";
}