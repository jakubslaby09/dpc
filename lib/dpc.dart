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
  // TODO: better exceptions and graceful handling
  Pedigree.parse(Map<String, dynamic> json, this.dir, this.repo)
    : version = json['version'],
    name = json['name'],
    people = (json['people'] as List<dynamic>).map((person) => Person.parse(person)).toList(),
    chronicle = (json['chronicle'] as List<dynamic>).map((chronicle) => Chronicle.parse(chronicle)).toList() {
      if (version > maxVersion) throw Exception("Unsupported pedigree version $version!");
      if (version < maxVersion) throw Exception("Outdated pedigree version $version.${version >= minUpgradableVersion ? " You need to upgrade it first." : ""}");
      people.asMap().forEach((index, person) {
        if (person.father != null && person.father! < 0) throw Exception("${person.name} has a father id smaller than 0");
        if (person.mother != null && person.mother! < 0) throw Exception("${person.name} has a mother id smaller than 0");
        if (person.id != index) throw Exception("${person.name} is in position $index in the list, which doesn't correspond to it's id (${person.id})");
        for (var id in person.children) {
          if(id >= 0 && id is double) throw Exception("Child id $id is not an integer. Only negative child ids can have a decimal part");
        }
      });
  }

  factory Pedigree.upgrade(Map<String, dynamic> json, String dir, Pointer<git_repository> repo) {
    if(json['version'] is! int || json['version'] < minUpgradableVersion || json['version'] > maxVersion) {
      throw Exception("Unsupported or invalid pedigree version: ${json['version']}");
    }
    final version = json['version'];

    assert(minUpgradableVersion == 3);
    if(version <= 3) {
      json['people'] = (json['people'] as List).map((person) {
        if(person['father'] == -1) (person as Map).remove("father");
        if(person['mother'] == -1) (person as Map).remove("mother");
        if(person['death'] == "") (person as Map).remove("death");
        if(person['birth'] == "") (person as Map).remove("birth");
        return person;
      }).toList();
    }
    assert(maxVersion == 4);
    json['version'] = maxVersion;
    return Pedigree.parse(json, dir, repo);
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
  Pointer<git_repository> repo;

  static const maxVersion = 4;
  static const minUpgradableVersion = 3;

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

  Future<void> save(BuildContext context, [bool createFile = false]) async {
    final index = File(p.join(dir, "index.dpc"));

    if(!await index.exists() && !createFile) {
      showException(context, "Nelze uložit Vaše úpravy do souboru s rodokmenem. Nesmazali jste ho?");
    }

    try {
      if(createFile) await index.create();
      await index.writeAsString(toJson());
    } on Exception catch (e, t) {
      if(createFile) throw Exception("Nelze vytvořit nový soubor s rodokmenem.");
      showException(context, "Nelze uložit Vaše úpravy do souboru s rodokmenem.", e, t);
    }
  }
}

class Person implements Child, HasOtherParent {
  Person.parse(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      image = json['image'],
      birth = json['birth'],
      death = json['death'],
      pedigreeLink = json['pedigreeLink'] != null ? PedigreeLink.parse(json['pedigreeLink']) : null,
      _father = json['father'],
      _mother = json['mother'],
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
  : children = [];

  Person.clone(Person person)
  : id = person.id,
  name = person.name,
  sex = person.sex,
  image = person.image,
  birth = person.birth,
  death = person.death,
  pedigreeLink = person.pedigreeLink?.clone(),
  _father = person.father,
  _mother = person.mother,
  children = [...person.children];

  @override
  int id;
  String name;
  late Sex sex;
  String? image;
  String? birth;
  String? death;
  PedigreeLink? pedigreeLink;
  int? _father;
  int? _mother;
  List<num> children;

  int? get mother => _mother;
  int? get father => _father;

  Future<FileImage?> imageProvider(String repoDir) async {
    if(image == null) {
      return null;
    }
    final file = File(p.join(repoDir, image));
    if(!await file.exists()) {
      return null;
    }
    return FileImage(file);
  }

  Iterable<Child> getChildren(Pedigree pedigree) {
    return children.map((childId) => Child(childId, pedigree));
  }

  void addChild(num id, Person? otherParent, Pedigree pedigree, [int? position]) {
    // TODO: make ui for already added child id
    // TODO: sort children by birth date

    position = min(children.length, position ?? children.length);
    children.remove(id);
    children.insert(position, id);

    if(otherParent != null) {
      otherParent.addChild(id, null, pedigree);
    }

    if(id < 0) return;
    assert(id is int, "positive ids should be checked in Pedigree.parse");
    final child = pedigree.people.elementAtOrNull(id as int);
    if(child != null) {
      // TODO: remove child from old parent
      switch (sex) {
        case Sex.male:
          child._father = this.id;
          // print("setting ${child.name}'s father to $name");
          break;
        case Sex.female:
          // print("setting ${child.name}'s mother to $name");
          child._mother = this.id;
          break;
      }
    }
  }

  void setParent(int? newId, Sex parentSex, Pedigree pedigree) {
    final int? oldParentId;
    switch (parentSex) {
      case Sex.male:
        oldParentId = _father;
        _father = newId;
        break;
      case Sex.female:
        oldParentId = _mother;
        _mother = newId;
    }

    if(oldParentId != null) {
      final oldParent = pedigree.people.elementAtOrNull(oldParentId);
      // TODO: display index errors
      if(oldParent == null) return;

      oldParent.children.remove(id);
    }

    if(newId != null) {
      final newParent = pedigree.people.elementAtOrNull(newId);
      // TODO: display index errors
      if(newParent == null) return;

      // TODO: check if the new parent's sex is the same as parentSex

      // TODO: fix ordering
      // TODO: display a warning if it's already there
      newParent.children.remove(id);
      newParent.children.add(id);
    }
  }

  void removeChild(num id, Pedigree pedigree) {
    children.remove(id);

    if(id < 0) return;
    assert(id is int, "positive ids should be checked in Pedigree.parse");
    final child = pedigree.people.elementAtOrNull(id as int);
    if(child == null) return;
    switch (sex) {
      case Sex.male:
        child._father = null;
        // print("setting ${child.name}'s father to null");
        break;
      case Sex.female:
        // print("setting ${child.name}'s mother to null");
        child._mother = null;
        break;
    }
  }

  @override
  Person? otherParent(Person parent, Pedigree pedigree) {
    // TODO: handle index errors gracefully
    switch (parent.sex) {
      case Sex.male:
        if(mother == null) return null;
        // print("other parent of $name is ${pedigree.people[mother!].name}");
        return pedigree.people[mother!];
      case Sex.female:
        if(father == null) return null;
        // print("other parent of $name is ${pedigree.people[father!].name}");
        return pedigree.people[father!];
    }
  }

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
  Chronicle.empty()
  : name = "",
    authors = [],
    files = [],
    mime = ChronicleMime.other;

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
  // TODO: remove it in dpc v5 since it doesn't make sence
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

abstract class Child {
  int get id;

  factory Child(num childId, Pedigree pedigree) {
    if(childId == -1) return const UnknownChild();
    if(childId.toInt() == -2) {
      if(childId == -2) {
        return const UnknownChildren();
      } else {
        return UnknownChildren(int.parse(childId.toString().split(".")[1]));
      }
    }

    assert(childId is int && childId >= 0, "special child ids should be checked in Pedigree.parse");
    return pedigree.people[childId as int];
  }
}

abstract class HasOtherParent {
  Person? otherParent(Person parent, Pedigree pedigree);
}

class UnknownChild implements Child {
  const UnknownChild();

  @override
  final int id = -1;
}

class UnknownChildren implements Child, HasOtherParent {
  const UnknownChildren([this.subId]);

  @override
  final int id = -2;
  final int? subId;
  // TODO: use something faster than double.parse
  num get wholeId => subId == null ? id : double.parse("$id.$subId");

  @override
  Person? otherParent(Person parent, Pedigree pedigree) {
    final otherParents = pedigree.people.where((person) => person.id != parent.id && person.children.contains(wholeId));
    if(otherParents.length != 1) return null;
    return otherParents.first;
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
