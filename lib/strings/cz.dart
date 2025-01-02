import 'package:dpc/strings/strings.dart';

class Czech implements S {
  @override String get noFileOpenNotice => "Nemáte otevřený repozitář s rodokmenem.\nNa první stránce ho můžete otevřít, nebo založit nový.";  
  @override String get noFileOpenButton => "Přejít na první stránku";  
  @override String get navFilesPage => "Soubor";
  @override String get navListPage => "Seznam";
  @override String get navChroniclePage => "Kronika";
  @override String get navCommitPage => "Změny";
  @override String get noRepoOpened => "Nic tu není...";
  @override String get openRepo => "Otevřít repozitář";
  @override String get downloadRepo => "Stáhnout repozitář";
  @override String get createRepo => "Založit nový repozitář";
  @override String get preferences => "Předvolby";
}