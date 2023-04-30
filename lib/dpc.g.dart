// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dpc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pedigree _$PedigreeFromJson(Map<String, dynamic> json) => Pedigree(
      version: json['version'] as int,
      name: json['name'] as String,
      people: (json['people'] as List<dynamic>)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList(),
      chronicle: (json['chronicle'] as List<dynamic>)
          .map((e) => Chronicle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PedigreeToJson(Pedigree instance) => <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'people': instance.people,
      'chronicle': instance.chronicle,
    };

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
      id: json['id'] as int,
      name: json['name'] as String,
      sex: $enumDecode(_$SexEnumMap, json['sex']),
      birth: json['birth'] as String?,
      death: json['death'] as String?,
      father: json['father'] as int,
      mother: json['mother'] as int,
      children: (json['children'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sex': _$SexEnumMap[instance.sex]!,
      'birth': instance.birth,
      'death': instance.death,
      'father': instance.father,
      'mother': instance.mother,
      'children': instance.children,
    };

const _$SexEnumMap = {
  Sex.male: 'male',
  Sex.female: 'female',
};

Chronicle _$ChronicleFromJson(Map<String, dynamic> json) => Chronicle(
      name: json['name'] as String,
      mime: json['mime'] as String,
      file: json['file'] as String?,
      files:
          (json['files'] as List<dynamic>?)?.map((e) => e as String).toList(),
      authors: (json['authors'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );

Map<String, dynamic> _$ChronicleToJson(Chronicle instance) => <String, dynamic>{
      'name': instance.name,
      'mime': instance.mime,
      'file': instance.file,
      'files': instance.files,
      'authors': instance.authors,
    };
