import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/pages/person.dart';
import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  _ListScreenState() {
    people = App.pedigree?.clone().people;
    sortPeople(0, true);
  }

  List<Person>? people;
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
            enabled: people != null,
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
        if (people != null) DataTable(
          sortAscending: sortAscending,
          sortColumnIndex: sortedColumn,
          showCheckboxColumn: false,
          columns: [
            DataColumn(label: const Text("Jméno"), onSort: (i, a) => sortPeople(i, a).then((_) => setState(() {}))),
            DataColumn(label: const Text("Narození"), onSort: (i, a) => sortPeople(i, a).then((_) => setState(() {}))),
          ],
          rows: filterPeople()!.map((person) => DataRow(
            cells: [
              DataCell(Text(person.name)),
              DataCell(Text(person.birth?.toString() ?? "chybí"), placeholder: person.birth == null),
            ],
            onSelectChanged: (value) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => PersonPage(person.id),
              ));
            },
          )).toList(),
        ),
      ],
    );
  }

  Future<void> sortPeople(int columnIndex, bool ascending) async {
    final direction = ascending ? 1 : -1;
    people?.sort((a, b) {
      switch (columnIndex) {
        case 1:
          return (a.birth != null ? direction * (b.birth != null ? (a.birth!).compareTo(b.birth!) : -1) : 1);
        case 0:
        default:
          return direction * a.name.compareTo(b.name);
      }
    });
    
    sortedColumn = columnIndex;
    sortAscending = ascending;
  }

  Iterable<Person>? filterPeople() {
    return people?.where((person) => person.name.toLowerCase().contains(filter.toLowerCase()));
  }
}