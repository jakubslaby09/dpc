import 'package:dpc/main.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dpc.g.dart';

// in the case of changes, run: flutter pub run build_runner build --delete-conflicting-outputs
@JsonSerializable()
class Pedigree {
  Pedigree({
    required this.version,
    required this.name,
    required this.people,
    required this.chronicle,
  });

  int version;
  String name;
  List<Person> people;
  List<Chronicle> chronicle;

  factory Pedigree.parse(Map<String, dynamic> json) => _$PedigreeFromJson(json);

  // static Result<Pedigree, dynamic>  parse(dynamic value) {
  //   print(value);
  //     return Result(Pedigree(
  //       version: value.version,
  //       name: value.name,
  //     ));
  //   try {
  //   } catch (e) {
  //     return Result.error(e);
  //   }
  // }
}

@JsonSerializable()
class Person {
  Person({
    required this.id,
    required this.name,
    required this.sex,
    this.birth,
    this.death,
    required this.father,
    required this.mother,
    required this.children,
  });

  int id;
  String name;
  Sex sex;
  String? birth;
  String? death;
  int father;
  int mother;
  List<double> children;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}

@JsonSerializable()
class Chronicle {
  Chronicle({
    required this.name,
    required this.mime,
    required this.file,
    required this.files,
    required this.authors,
  });
  
  String name;
  String mime;
  String? file;
  List<String>? files;
  List<double> authors; 

  factory Chronicle.fromJson(Map<String, dynamic> json) => _$ChronicleFromJson(json);
}

enum Sex {
  @JsonValue("male") male,
  @JsonValue("female") female,
}