import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';

class Pedigree {
  Pedigree.parse(Map<String, dynamic> json, this.repo)
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

  Pedigree.empty(this.name, this.repo)
    : version = 3,
      people = [],
      chronicle = [];
  
  Pedigree.clone(Pedigree pedigree)
    : version = pedigree.version,
    name = pedigree.name,
    people = pedigree.people.map((person) => Person.clone(person)).toList(),
    chronicle = pedigree.chronicle.map((chronicle) => Chronicle.clone(chronicle)).toList(),
    repo = pedigree.repo;
    

  int version;
  String name;
  List<Person> people;
  List<Chronicle> chronicle;
  // TODO: free when closing file
  Pointer<Pointer<git_repository>> repo;

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

  PersonDiff compare(Person other) {
    return PersonDiff(
      id == other.id ? null : id,
      name == other.name ? null : name,
      sex == other.sex ? null : sex,
      birth == other.birth ? null : birth,
      death == other.death ? null : death,
      father == other.father ? null : father,
      mother == other.mother ? null : mother,
      [
        ...children.where((childId) => !other.children.contains(childId)).map((child) => (true, child)),
        ...other.children.where((childId) => !children.contains(childId)).map((child) => (false, child)),
      ],
    );
  }
}

class PersonDiff {
  PersonDiff(this.id, this.name, this.sex, this.birth, this.death, this.father, this.mother, this.children);

  int? id;
  String? name;
  Sex? sex;
  String? birth;
  String? death;
  int? father;
  int? mother;
  late List<(bool, double)> children;

  bool same() {
    return id == null &&
    name == null &&
    sex == null &&
    birth == null &&
    death == null &&
    father == null &&
    mother == null &&
    children.isEmpty;
  }
}

class Chronicle {
  Chronicle.parse(Map<String, dynamic> json)
    : name = json['name'],
      mime = mimeFromString(json['mime']),
      files = parseChronicleFiles(json['files'], json['file']),
      authors = parseIdList(json['authors'])!;

  Chronicle.clone(Chronicle chronicle)
  : name = chronicle.name,
  mime = chronicle.mime,
  files = [...chronicle.files],
  authors = [...chronicle.authors];

  bool compare(Chronicle other) {
    return name == other.name &&
    mime == other.mime &&
    // TODO: use firstWhere
    files.where((element) => other.files.contains(element)).isEmpty &&
    authors.where((element) => other.authors.contains(element)).isEmpty;
  }
  
  String name;
  ChronicleMime mime;
  List<String> files;
  List<double> authors;
}

List<double>? parseIdList(List<dynamic>? list) {
  return list?.map((value) => (value as num).toDouble()).toList();
}

List<String>? parseStringList(List<dynamic>? list) {
  return list?.map((value) => (value as String)).toList();
}

List<String> parseChronicleFiles(List<dynamic>? files, dynamic file) {
  if((file == null) == (files == null)) {
    throw Exception("Either `file` or `files` field should be set.");
  }

  if(file != null) {
    return [file];
  } else {
    return parseStringList(files)!;
  }
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

enum ChronicleMime {
  applicationPdf,
  textPlain,
  textMarkdown,
  other,
}
extension ChronicleMimeExtension on ChronicleMime {
  IconData get icon {
    return switch (this) {
      ChronicleMime.applicationPdf => Icons.picture_as_pdf_outlined,
      ChronicleMime.textPlain => Icons.text_snippet_outlined,
      ChronicleMime.textMarkdown => Icons.text_snippet_outlined,
      ChronicleMime.other => Icons.attachment,
    };
  }

  bool get openable {
    return switch (this) {
      ChronicleMime.applicationPdf => false,
      ChronicleMime.textPlain => true,
      ChronicleMime.textMarkdown => true,
      ChronicleMime.other => false,
    };
  }
}

ChronicleMime mimeFromString(String value) {
  try {
    return ChronicleMime.values.firstWhere((element) {
      return element.toString().split(".").last.toLowerCase() == value.replaceAll("/", "");
    });
  } catch (e) {
    return ChronicleMime.other;
  }
}