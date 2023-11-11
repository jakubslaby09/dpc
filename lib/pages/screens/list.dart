import 'package:dpc/autosave.dart';
import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/home.dart';
import 'package:dpc/pages/person.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListScreen extends UniqueWidget implements FABScreen {
  const ListScreen({required super.key});

  @override
  Widget? fab(BuildContext context) => App.pedigree == null ? null : FloatingActionButton.small(
    child: const Icon(Icons.add),
    onPressed: () async {
      final sex = SexExtension.random();
      final person = Person.empty(App.pedigree!.people.length, sex, await sex.randomName());
      App.pedigree!.people.add(person);
      scheduleSave(context);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PersonPage(person.id),
      ));
      final state = currentState as _ListScreenState?;
      state?.setState(() => state.sortPeople(state.sortedColumn, state.sortAscending));
    },
  );

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  _ListScreenState() {
    sortedPeople = App.pedigree?.clone().people;
    sortPeople(0, true);
  }

  List<Person>? sortedPeople;
  String filter = "";
  late bool sortAscending;
  late int sortedColumn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            enabled: sortedPeople != null,
            decoration: const InputDecoration(
              icon: Icon(Icons.search),
              // hintText: "",
              labelText: "Hledání",
            ),
            onChanged: (value) => setState(() {
              filter = value;
            }),
          ),
        ),
        if (sortedPeople != null) DataTable(
          sortAscending: sortAscending,
          sortColumnIndex: sortedColumn,
          showCheckboxColumn: false,
          columns: [
            DataColumn(label: const Text("Jméno"), onSort: (i, a) => setState(() => sortPeople(i, a))),
            DataColumn(label: const Text("Narození"), onSort: (i, a) => setState(() => sortPeople(i, a))),
          ],
          rows: filterPeople()!.map((person) => DataRow(
            cells: [
              DataCell(Text(person.name)),
              DataCell(Text(person.birth?.toString() ?? "chybí"), placeholder: person.birth == null),
            ],
            onSelectChanged: (value) async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PersonPage(person.id),
              ));
              setState(() => sortPeople(sortedColumn, sortAscending));
            },
          )).toList(),
        ),
      ],
    );
  }

  void sortPeople(int columnIndex, bool ascending) {
    final direction = ascending ? 1 : -1;
    sortedPeople = App.pedigree?.clone().people;
    sortedPeople?.sort((a, b) {
      switch (columnIndex) {
        case 1:
          return direction * compareDates(a.birth, b.birth);
        case 0:
        default:
          return direction * a.name.compareTo(b.name);
      }
    });
    
    sortedColumn = columnIndex;
    sortAscending = ascending;
  }


  Iterable<Person>? filterPeople() {
    return sortedPeople?.where((person) => person.name.toLowerCase().contains(filter.toLowerCase()));
  }
}
int compareDates(String? a, String? b) {
  if(a == null) return 1;
  if(b == null) return -1;
  final dateFormat = DateFormat("d.M.y");
  final yearFormat = DateFormat("y");
  DateTime? parsedA = DateTime.tryParse(a) ?? dateFormat.tryParseLoose(a) ?? yearFormat.tryParseLoose(a);
  DateTime? parsedB = DateTime.tryParse(b) ?? dateFormat.tryParseLoose(b) ?? yearFormat.tryParseLoose(b);
  if(parsedA == null || parsedB == null) {
    return (a).compareTo(b);
  }
  return parsedA.compareTo(parsedB);
}