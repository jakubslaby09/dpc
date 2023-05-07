import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  _ListScreenState() {
    people = App.pedigree?.people;
    sort(0, true);
  }

  List<Person>? people;
  late bool sortAscending;
  late int sortedColumn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: TextField(
            enabled: people != null,
            onChanged: (value) {
              
            },
          ),
        ),
        if (people != null) DataTable(
          sortAscending: sortAscending,
          sortColumnIndex: sortedColumn,
          columns: [
            DataColumn(label: const Text("Jméno"), onSort: (i, a) => sort(i, a).then((_) => setState(() {}))),
            DataColumn(label: const Text("Narození"), onSort: (i, a) => sort(i, a).then((_) => setState(() {}))),
          ],
          rows: people!.map((person) => DataRow(
            cells: [
              DataCell(Text(person.name)),
              DataCell(Text(person.birth?.toString() ?? "chybí"), placeholder: person.birth == null),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Future<void> sort(int columnIndex, bool ascending) async {
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
}