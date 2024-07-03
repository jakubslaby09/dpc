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
      if (version < maxVersion) throw OutdatedPedigreeException(version, json);
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
    if(json['version'] is! int || json['version'] > maxVersion) {
      throw Exception("Unsupported or invalid pedigree version: ${json['version']}");
    }
    if(json['version'] < minUpgradableVersion) {
      throw OutdatedPedigreeException(json['version'], json);
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
    if(version <= 4) {
      for(final Map chronicle in json['chronicle']) {
        chronicle.remove('mime');
        if(chronicle.keys.contains('file')) {
          chronicle['file'] = p.join("kronika", chronicle['file']);
        }
        if(chronicle.keys.contains('files')) {
          for (int pathIndex = 0; pathIndex < (chronicle['files'] as List).length; pathIndex++) {
            chronicle['files'][pathIndex] = p.join("kronika", chronicle['files'][pathIndex]); 
          }
        }
        if(chronicle['files'] == []) chronicle.remove("files");
      }
    }
    assert(maxVersion == 5);
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

  static const maxVersion = 5;
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

  void removePerson(int id) {
    assert(id < people.length, "Tried to remove a person which is not in the pedigree");
    assert(id > 0, "Tried to remove a person with a negative id");

    final person = people[id];
    if(person.father != null) {
      people[person.father!].children.remove(id);
    }
    if(person.mother != null) {
      people[person.mother!].children.remove(id);
    }
    for (final child in [...person.getChildren(this)]) {
      if(child is Person) {
        child.setParent(null, person.sex, this);
      }
    }

    if(id == people.length - 1) {
      people.removeLast();
    } else {
      people[id] = people.removeLast();
      final movedPerson = people[id];
      movedPerson.id = id;
      if(movedPerson.father != null) {
        final index = people[movedPerson.father!].children.indexWhere((childId) => childId == people.length);
        people[movedPerson.father!].children[index] = id;
      }
      if(movedPerson.mother != null) {
        final index = people[movedPerson.mother!].children.indexWhere((childId) => childId == people.length);
        people[movedPerson.mother!].children[index] = id;
      }
      for (final child in movedPerson.getChildren(this)) {
        if(child is Person) {
          child.setParent(id, person.sex, this);
        }
      }
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

  FileImage? imageProviderUnchecked(String repoDir) {
    if(image == null) {
      return null;
    }
    final file = File(p.join(repoDir, image));
    return FileImage(file);
  }
  Future<FileImage?> imageProvider(String repoDir) async {
    final provider = imageProviderUnchecked(repoDir);
    if(provider == null || !await provider.file.exists()) {
      return null;
    }
    return provider;
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

  @override
  String toString() {
    return "<$id: $name>";
  }
}

class Chronicle {
  Chronicle.empty()
  : name = "",
    authors = [],
    files = [];

  Chronicle.parse(Map<String, dynamic> json)
    : name = json['name'],
      files = parseChronicleFiles(json['files'], json['file']),
      authors = parseChronicleAuthors(json['authors'], json['author']);

  Chronicle.clone(Chronicle chronicle)
  : name = chronicle.name,
  files = [...chronicle.files],
  authors = [...chronicle.authors];

  bool compare(Chronicle other) {
    return name == other.name &&
    files.length == other.files.length &&
    authors.length == other.authors.length &&
    files.safeFirstWhere((element) => !other.files.contains(element)) == null &&
    authors.safeFirstWhere((element) => !other.authors.contains(element)) == null;
  }

  String name;
  List<String> files;
  List<num> authors;

  Map<String, dynamic> toJson() {
    Map<String, Object> result = {
      "name": name,
    };

    if(files.length == 1) {
      result["file"] = files[0];
    } else if(files.length > 1) {
      result["files"] = files;
    }
    
    if(authors.length == 1) {
      result["author"] = authors[0];
    } else if(authors.length > 1) {
      result["authors"] = authors;
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

List<num> parseChronicleAuthors(List<dynamic>? authors, dynamic author) {
  if(author != null && authors != null) {
    throw Exception("`author` and `authors` should not be set both at once.");
  }

  if(author != null) {
    return [author];
  } else {
    return parseIdList(authors) ?? [];
  }
}

List<String>? parseStringList(List<dynamic>? list) {
  return list?.map((value) => (value as String)).toList();
}

List<String> parseChronicleFiles(List<dynamic>? files, dynamic file) {
  if(file != null && files != null) {
    throw Exception("`file` and `files` should not be set both at once.");
  }

  if(file != null) {
    return [file];
  } else {
    return parseStringList(files) ?? [];
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

const fileTypes = {
  "md": ChronicleFileType(
    icon: Icons.text_snippet_outlined,
    openable: true,
  ),
  "txt": ChronicleFileType(
    icon: Icons.text_snippet_outlined,
    openable: true,
  ),
  "pdf": ChronicleFileType(
    icon: Icons.picture_as_pdf_outlined,
    openable: false,
  ),
};

class ChronicleFileType {
  const ChronicleFileType({
    required this.icon,
    required this.openable,
  });

  final IconData icon;
  final bool openable;
}

ChronicleFileType fileTypeFromPath(String path) {
  final ext = p.extension(path);
  final type = ext.isEmpty ? null : fileTypes[ext.substring(1)];
  return type ?? const ChronicleFileType(
    icon: Icons.attachment_outlined,
    openable: false,
  );
}

class OutdatedPedigreeException implements Exception {
  const OutdatedPedigreeException(this.version, this.values);

  final int version;
  final Map<String, dynamic> values;
  @override
  String toString() {
    return "Exception: Outdated pedigree version $version.${
      upgradable ? " You need to upgrade it first."
      : " Only versions ${Pedigree.minUpgradableVersion} and newer can be upgraded."
    }";
  }

  bool get upgradable {
    return version >= Pedigree.minUpgradableVersion;
  }
}