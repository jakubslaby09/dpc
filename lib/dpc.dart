import 'package:flutter/material.dart';

class Pedigree {
  Pedigree.parse(Map<String, dynamic> json)
    : version = json['version'],
      name = json['name'],
      people = (json['people'] as List<dynamic>).map((person) => Person.parse(person)).toList(),
      chronicle = (json['chronicle'] as List<dynamic>).map((chronicle) => Chronicle.parse(chronicle)).toList() {
        if (version > maxVersion) throw Exception("Unsupported pedigree version $version!");
        if (version < maxVersion) throw UnimplementedError("Upgrading pedigree versions has yet to be implemented."); // TODO: Implement pedigree version upgrades
        people.asMap().forEach((index, person) {
          if (person.id != index) throw Exception("${person.id} != $index");
        });
  }

  Pedigree.empty(this.name)
    : version = 3,
      people = [],
      chronicle = [];
  
  Pedigree.clone(Pedigree pedigree)
    : version = pedigree.version,
    name = pedigree.name,
    people = pedigree.people.map((person) => Person.clone(person)).toList(),
    chronicle = pedigree.chronicle.map((chronicle) => Chronicle.clone(chronicle)).toList();
    

  int version;
  String name;
  List<Person> people;
  List<Chronicle> chronicle;

  static const maxVersion = 3;

  Pedigree clone() {
    return Pedigree.clone(this);
  }
}

class Person {
  Person.parse(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      birth = json['birth'],
      death = json['death'],
      father = json['father'],
      mother = json['mother'],
      children = parseIdList(json['children'])! {
    switch (json['sex']) {
      case 'male':
        sex = Sex.male;
        break;
      case 'female':
        sex = Sex.female;
        break;
      default:
        throw Exception("The `sex` parameter supports two parameters: `male`, `female`");
    }
  }

  Person.clone(Person person)
  : id = person.id,
  name = person.name,
  sex = person.sex,
  birth = person.birth,
  death = person.death,
  father = person.father,
  mother = person.mother,
  children = [...person.children];

  int id;
  String name;
  late Sex sex;
  String? birth;
  String? death;
  int father;
  int mother;
  List<double> children;
}

class Chronicle {
  Chronicle.parse(Map<String, dynamic> json)
    : name = json['name'],
      mime = json['mime'],
      file = json['file'],
      files = parseStringList(json['files']),
      authors = parseIdList(json['authors'])! {
    if ((file == null) == (files == null)) throw Exception("Either `file` or `files` field should be set.");
  }

  Chronicle.clone(Chronicle chronicle)
  : name = chronicle.name,
  mime = chronicle.mime,
  file = chronicle.file,
  files = [...chronicle.files ?? []],
  authors = [...chronicle.authors];
  
  String name;
  String mime;
  String? file;
  List<String>? files;
  List<double> authors;
}

enum Sex {
  male,
  female,
}

extension SexExtension on Sex? {
  String get string {
    return this == null ? "osoba" : this == Sex.male ? "muž" : "žena";
  }
  
  IconData get icon {
    return this == null ? Icons.face_outlined : this == Sex.male ? Icons.face_6_outlined : Icons.face_3_outlined;
  }
}

List<double>? parseIdList(List<dynamic>? list) {
  return list?.map((value) => (value as num).toDouble()).toList();
}

List<String>? parseStringList(List<dynamic>? list) {
  return list?.map((value) => (value as String)).toList();
}