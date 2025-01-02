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
  @override String get searchLabel => "Hledat";
  @override String get peopleNameColumn => "Jméno";
  @override String get peopleBirthColumn => "Narození";
  @override String get chronicleNameHint => "Pojmenujte kroniku";
  @override String get chronicleAddAuthor => "Přidat autora";
  @override String get chronicleAddFiles => "Přidat soubory";
  @override String get chronicleFilePickerTitle => "Vybrat soubory do kroniky";
  @override String get chronicleFileImportSheetTitle => "Vybrali jste soubor mimo repozitář. Vyberte pro něj v repozitáři umístění";
  @override String get chronicleFileImportSheetSuggestedDirectory => "kronika";
  @override String get fetchingCommits => "Stahování změn...";
  @override String get couldNotFetchCommits => "Nelze zkontrolovat změny z internetu";
  @override String fetchedCommits(int count, bool localChanges) => "Ve vzdáleném repozitáři je $count ${count > 1 ? "nových příspěvků" : "nový příspěvek"}.${localChanges ? " Přijetím své změny přepíšete." : ""}";
  @override String get repoUpToDate => "Váš repozitář je aktuální";
  @override String get overwriteWorktree => "Zahodit a přijmout";
  @override String ffCommits(int count) => "Přijmout $count ${count > 1 ? "příspěvků" : "příspěvek"}";
  @override String get fetchErrorDetails => "Více";
  @override String get indexUpgradeChange => "Upgrade indexu";
  @override String get commitCannotReadHead => "nelze porovnat rodokmen s právě zveřejněnou verzí.";
  @override String get fetchCouldNotLookupRemote => "nelze zjistit, odkud stáhnout změny";
  @override String get fetchCouldNotFetchRemote => "nelze stáhnout změny";
  @override String get fetchCouldNotReadHead => "nelze najít místní poslední příspěvek";
  @override String get fetchCouldNotReadFetchHead => "nelze najít vzdálený poslední příspěvek";
  @override String get fetchCouldNotCompareRemote => "nelze porovnat stažené změny s místními";
  @override String get changesCouldNotDeleteFile => "nelze smazat soubor";
  @override String get changesCouldNotInitDiffOptions => "chyba při nastavování zjišťování stavu ostatních souborů";
  @override String get changesCouldNotDiffNew => "nelze získat stav ostatních souborů";

}