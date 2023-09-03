import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:dpc/main.dart';
import 'package:dpc/pages/log.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:git2dart_binaries/git2dart_binaries.dart';
import 'package:flutter/services.dart' show rootBundle;

class Pedigree {
  Pedigree.parse(Map<String, dynamic> json, this.dir, this.repo)
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

  Pedigree.empty(this.name, this.dir, this.repo)
    : version = maxVersion,
    people = [],
    chronicle = [];
  
  Pedigree.clone(Pedigree pedigree)
    : version = pedigree.version,
    name = pedigree.name,
    people = pedigree.people.map((person) => Person.clone(person)).toList(),
    chronicle = pedigree.chronicle.map((chronicle) => Chronicle.clone(chronicle)).toList(),
    dir = pedigree.dir,
    repo = pedigree.repo;
    

  int version;
  String name;
  List<Person> people;
  List<Chronicle> chronicle;
  String dir;
  // TODO: free when closing file
  Pointer<Pointer<git_repository>> repo;

  static const maxVersion = 4;

  Pedigree clone() {
    return Pedigree.clone(this);
  }

  String toJson() {
    const encoder = JsonEncoder.withIndent("  ");
    return encoder.convert({
      "version": version,
      "name": name,
      "people": people.map((person) => person.toJson()).toList(),
      "chronicle": chronicle.map((chronicle) => chronicle.toJson()).toList(),
    });
  }

  Future<void> save(BuildContext context) async {
    final index = File(p.join(dir, "index.dpc"));

    if(!await index.exists()) {
      showException(context, "Nelze uložit Vaše úpravy do souboru s rodokmenem. Nesmazali jste ho?");
    }

    try {
      await index.writeAsString(toJson());
    } on Exception catch (e) {
      showException(context, "Nelze uložit Vaše úpravy do souboru s rodokmenem.", e);
    }
  }
}

class Person {
  Person.parse(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      image = json['image'],
      birth = json['birth'],
      death = json['death'],
      pedigreeLink = json['pedigreeLink'] != null ? PedigreeLink.parse(json['pedigreeLink']) : null,
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

  Person.empty(this.id, this.sex, this.name)
  : father = -1,
  mother = -1,
  children = [];

  Person.clone(Person person)
  : id = person.id,
  name = person.name,
  sex = person.sex,
  image = person.image,
  birth = person.birth,
  death = person.death,
  pedigreeLink = person.pedigreeLink?.clone(),
  father = person.father,
  mother = person.mother,
  children = [...person.children];

  int id;
  String name;
  late Sex sex;
  String? image;
  String? birth;
  String? death;
  PedigreeLink? pedigreeLink;
  int father;
  int mother;
  List<num> children;

  bool compare(Person other) {
    return id == other.id &&
    name == other.name &&
    sex == other.sex &&
    birth == other.birth &&
    death == other.death &&
    father == other.father &&
    mother == other.mother &&
    children.length == other.children.length &&
    children.safeFirstWhere((childId) => !other.children.contains(childId)) == null;
  }
  
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      "id": id,
      "name": name,
      "sex": sex.name,
      "image": image,
      "birth": birth,
      "death": death,
      "pedigreeLink": pedigreeLink?.toJson(),
      "father": father,
      "mother": mother,
      "children": children/* .map((id) => id % 1 == 0 ? id.toInt() : id).toList() */,
    };

    result.removeWhere((_, value) => value == null);

    return result;
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
    files.length == other.files.length &&
    authors.length == other.authors.length &&
    files.safeFirstWhere((element) => !other.files.contains(element)) == null &&
    authors.safeFirstWhere((element) => !other.authors.contains(element)) == null;
  }
  
  String name;
  ChronicleMime mime;
  List<String> files;
  List<num> authors;
  
  Map<String, dynamic> toJson() {
    Map<String, Object> result = {
      "name": name,
      "mime": mime.toMimeString,
      "authors": authors,
    };

    if(files.length == 1) {
      result["file"] = files[0];
    } else {
      result["files"] = files;
    }

    return result;
  }

  @override
  String toString() {
    return "[Chronicle: $name]";
  }
}

List<num>? parseIdList(List<dynamic>? list) {
  return list?.map((value) => value as num).toList();
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

  static Sex random() {
    return Sex.values[Random().nextInt(Sex.values.length)];
  }

  Future<String> randomName() async {
    List<String> names;
    switch (this) {
      case Sex.male:
        names = (await rootBundle.loadString("assets/randomNames/males.txt")).split("\n");
        break;
      case Sex.female:
        names = (await rootBundle.loadString("assets/randomNames/females.txt")).split("\n");
        break;
      case null:
        names = (await rootBundle.loadString("assets/randomNames/males.txt")).split("\n");
        names.addAll((await rootBundle.loadString("assets/randomNames/females.txt")).split("\n"));
        break;
    }

    const rate = 2.8;
    final first = sampleFromExponentialDistribution(Random().nextDouble(), names, rate);
    final last = sampleFromExponentialDistribution(Random().nextDouble(), names, rate);
    return "$first $last";
  }
}

T sampleFromExponentialDistribution<T>(double x, List<T> values, [double rate = 1]) {
  final index = (pow(e, -rate * x) * values.length).floor();
  print(index);
  return values[index];
}

class PedigreeLink {
  PedigreeLink(this.name, this.date);

  PedigreeLink.parse(Map<String, dynamic> json)
    : date = json["date"],
    name = json["name"];

  String? name;
  String? date;

  PedigreeLink clone() {
    return PedigreeLink(name, date);
  }

  Map<String, String?> toJson() {
    Map<String, String?> result = {
      "name": name,
      "date": date,
    };

    result.removeWhere((_, value) => value == null);

    return result;
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

  String get toMimeString {
    final capital = name.indexOf(RegExp(r"[A-Z]"));
    if(capital == -1) {
      return "other/other";
    }
    return name.replaceRange(capital, capital + 1, "/${name[capital].toLowerCase()}");
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