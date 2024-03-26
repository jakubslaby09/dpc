import 'package:flutter_quill/quill_delta.dart';

class AttributeParser {
  const AttributeParser({this.flank = false, this.block = false, this.hardBreaks = true, required this.apply});

  final bool flank;
  final bool block;
  final bool hardBreaks;
  final String Function(String text, dynamic value, Map<String, dynamic> attributes) apply;
}

Map<String, AttributeParser> inlineParsers = {
  "bold": AttributeParser(
    flank: true,
    apply: (value, _, __) => "**$value**",
  ),
  "italic": AttributeParser(
    flank: true,
    apply: (value, _, __) => "_${value}_",
  ),
  "link": AttributeParser(
    apply: (value, link, __) => "[$value]($link)",
  ),
  "code": AttributeParser(
    apply: (value, _, __) => "`$value`",
  ),
  "header": AttributeParser(
    block: true,
    hardBreaks: false,
    // ignore: prefer_interpolation_to_compose_strings
    apply: (value, count, _) => "#" * (count is int ? count : 0) + " " + value,
  ),
  "list": AttributeParser(
    block: true,
    apply: (value, count, attributes) => 
      "  " * (attributes["indent"] is int ? attributes["indent"] : 0) + (value == "ordered" ? "1. " : "* ") + value,
  ),
  "blockquote": AttributeParser(
    block: true,
    apply: (value, _, __) => "> $value",
  ),
  "code-block": AttributeParser(
    block: true,
    apply: (value, _, __) => "```\n$value\n```  ",
  ),
};

const hardBreak = r" \";

String quillToMarkdownString(Delta delta) {
  final List<String> outputLines = [];
  bool lastHardBreak = false;

  for (var operationId = 0; operationId < delta.operations.length; operationId++) {
    final operation = delta.operations[operationId];
    if(!operation.isInsert) throw Exception("Only inserts are supported");
    String operationValue = encode(operation.value);
    // print("new operation ${operation.attributes}: `${operationValue.padRight(10).substring(0, 10).replaceAll("\n", r"[\n]")}`");
    bool wholeLine = false;
    bool trimmedNewline = false;
    bool hardBreaks = true;
    operation.attributes?.forEach((key, value) {
      final parser = inlineParsers[key];
      if(parser == null) return;
      if(!parser.hardBreaks) {
        hardBreaks = false;
      }
      if(parser.block && !wholeLine) {
        if(operationValue.endsWith("\n")) {
          operationValue = operationValue.substring(0, operationValue.length - 1);
          trimmedNewline = true;
        }
        operationValue = (pop(outputLines) ?? "") + operationValue;
        wholeLine = true;
      }
      if(parser.flank) {
        final (start, trimmed, end) = trim(operationValue);
        if(trimmed.isEmpty) return;
        operationValue = start + parser.apply(trimmed, value, operation.attributes ?? {}) + end;
      } else {
        operationValue = parser.apply(operationValue, value, operation.attributes ?? {});
      }
      if(trimmedNewline) {
        operationValue += "\n";
      }
    });
    List<String> operationLines = operationValue.split("\n");
    if(hardBreaks) {
      operationLines = trimmedMap(operationLines, (line) => line + hardBreak);
      /* operationLines = trimmedMap(operationLines, (line) {
        print("[${outputLines.length}] adding a hard break to ...`${line.substring(max(0, line.length - 10))}`");
        return line + hardBreak;
      }); */
    }
    // print(outputLines);
    // print("+ $operationLines");
    // print("$hardBreaks, last: $lastHardBreak: ${operation.attributes}");
    if(wholeLine) {
      outputLines.addAll(operationLines);
    } else if(operationLines.isNotEmpty) {
      if(outputLines.isEmpty) {
        outputLines.add(operationLines.first);
      } else {
        outputLines.last += operationLines.first;
        if(hardBreaks && lastHardBreak && outputLines.length > 1 && operationLines.length > 1) {
          outputLines[outputLines.length - 2] += hardBreak;
        }/*  else {
          outputLines[outputLines.length - 2] += "@";
        } */
      }
      outputLines.addAll(operationLines.sublist(1));
    }

    if(hardBreaks || operationLines.length > 1) {
      lastHardBreak = hardBreaks;
    }
  }

  // ignore: prefer_interpolation_to_compose_strings
  return outputLines.join("\n") + "\n";
}

String encode(String input) {
  return input.replaceAll("*", r"\*");
}

(String, String, String) trim(String value) {
  final originalLength = value.length;
  value = value.trimLeft();
  final start = " " * (originalLength - value.length);
  value = value.trimRight();
  final end = " " * (originalLength - start.length - value.length);
  return (start, value, end);
}

T? pop<T>(List<T> list) {
  if(list.isEmpty) return null;
  final item = list.last;
  list.removeLast();
  return item;
}

List<String> trimmedMap(List<String> elements, String Function(String) to) {
  if(elements.length < 3) {
    // print("skipping ${elements.length} lines");
    return [...elements];
  }
  final trimmed = elements.sublist(0, elements.length - 2);
  /* print("skipping `${elements.elementAt(elements.length - 2).padRight(10).substring(0, 10)}`");
  print("skipping `${elements.last.padRight(10).substring(0, 10)}`"); */
  return [
    ...trimmed.map(to),
    elements.elementAt(elements.length - 2),
    elements.last,
  ];
}