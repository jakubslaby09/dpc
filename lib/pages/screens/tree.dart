import 'dart:math';

import 'package:dpc/dpc.dart';
import 'package:dpc/main.dart';
import 'package:dpc/widgets/avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TreeScreen extends StatelessWidget {
  const TreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.1,
      constrained: false,
      child: TreeWidget(
        pedigree: App.pedigree!,
        children: App.pedigree!.people.map((person) => PersonTreeItem(
          person: person,
          repoDir: App.pedigree!.dir,
        )).toList(),
      ),
    );
  }
}

class TreeWidget extends MultiChildRenderObjectWidget {
  TreeWidget({
    super.key,
    Paint? paint,
    Size? itemSize,
    required List<PersonTreeItem> super.children,
    required this.pedigree,
  })
  : itemSize = itemSize ?? const Size.square(150),
    paint = paint ?? Paint()..color = Colors.black..strokeWidth = 2;
  final Paint paint;
  final Size itemSize;
  final Pedigree pedigree;
  Tree? cachedTree;
  // @override
  // List<PersonTreeItem> get children => super.children.whereType<PersonTreeItem>().toList();

  @override
  RenderTree createRenderObject(BuildContext context) {
    return RenderTree(pedigree, cachedTree, paint, itemSize);
  }
}

class PersonTreeItem extends StatelessWidget {
  const PersonTreeItem({super.key, required this.person, required this.repoDir});
  final Person person;
  final String repoDir;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PersonAvatar(person: person, repoDir: repoDir),
        Text(person.name, textAlign: TextAlign.center),
      ],
    );
  }
}

class TreeItemParentData extends ContainerBoxParentData<RenderBox> {
  TreeItemParentData();
}

class RenderTree extends RenderBox with ContainerRenderObjectMixin<RenderBox, TreeItemParentData>, RenderBoxContainerDefaultsMixin<RenderBox, TreeItemParentData> {
  RenderTree(this.pedigree, this.cachedTree, this.linePaint, this.itemSize);
  // final List<PersonTreeItem> people;
  final Paint linePaint;
  final Size itemSize;
  final Pedigree pedigree;
  Tree? cachedTree;
  // @override
  // RenderObject? firstChild;

  @override
  void performLayout() {
    cachedTree ??= makeTree(pedigree, 0);
    final biggestRow = cachedTree!.fold<int>(0, (prev, row) => max(row.length, prev));
    size = constraints.tighten(
      width: biggestRow * itemSize.width,
      height: cachedTree!.length * itemSize.height,
    ).biggest;
    print("tree size: $biggestRow/${cachedTree!.length}");
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(BoxConstraints.tight(itemSize));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    cachedTree ??= makeTree(pedigree, 0);
    // print(cachedTree);
    final List<RenderBox> boxes = [];
    for (RenderBox? box = firstChild; box != null; box = childAfter(box)) {
      boxes.add(box);
    }
    for (final (rowIndex, row) in cachedTree!.indexed) {
      for(final (columnIndex, (_, lines, _)) in row.indexed) {
        for(final (x, y) in lines) {
          // print("drawing $line");
          if(x == columnIndex || y == rowIndex) {
            context.canvas.drawLine(
              offset + Offset(itemSize.width * (columnIndex + 0.5), itemSize.height * (rowIndex + 0.45)),
              offset + Offset(itemSize.width * (x + 0.5), itemSize.height * (y + 0.45)),
              linePaint,
            );
          } else {
            final double turnHeight = rowIndex + (y - rowIndex) * 0.5;
            context.canvas.drawLine(
              offset + Offset(itemSize.width * (columnIndex + 0.5), itemSize.height * (rowIndex + 0.45)),
              offset + Offset(itemSize.width * (columnIndex + 0.5), itemSize.height * (turnHeight + 0.45)),
              linePaint,
            );
            context.canvas.drawLine(
              offset + Offset(itemSize.width * (columnIndex + 0.5), itemSize.height * (turnHeight + 0.45)),
              offset + Offset(itemSize.width * (x + 0.5), itemSize.height * (turnHeight + 0.45)),
              linePaint,
            );
            context.canvas.drawLine(
              offset + Offset(itemSize.width * (x + 0.5), itemSize.height * (turnHeight + 0.45)),
              offset + Offset(itemSize.width * (x + 0.5), itemSize.height * (y + 0.45)),
              linePaint,
            );
          }
        }
      }
    }
    for (final (rowIndex, row) in cachedTree!.indexed) {
      for(final (columnIndex, (person, _, dbg)) in row.indexed) {
        final personOffset = offset + Offset(itemSize.width * columnIndex, itemSize.height * rowIndex);
        if(person != null) {
          context.paintChild(
            boxes[person.id],
            personOffset,
          );
        }
        if(kDebugMode) {
          final text = TextPainter(
            text: TextSpan(text: "${person?.id}: $dbg", style: const TextStyle(color: Colors.purple)),
          );
          text.textDirection = TextDirection.ltr;
          text.layout(maxWidth: itemSize.width);
          text.paint(context.canvas, personOffset);
        }
      }
    }
  }

  paintPerson(RenderBox child, PaintingContext context, Offset offset) {
    context.paintChild(child, offset - Offset(itemSize.width, itemSize.height) / 2);
  }

  @override
  void setupParentData(covariant RenderObject child) {
    child.parentData = TreeItemParentData();
  }
}

typedef Tree = List<List<(Person?, List<(double, double)>, String)>>;

Tree makeTree(Pedigree pedigree, int initialId) {
  Person root = pedigree.people[initialId].rootGrandParent(pedigree, Sex.male);
  Tree res = [[(root, [], "root node")]];
  print("starting with $res");
  for(int generationIndex = 1; generationIndex < pedigree.people.length; generationIndex++) {
    if(res.lastOrNull?.isEmpty ?? false) {
      print("last generation is empty, breaking");
      assert(res.removeLast().isEmpty);
      break;
    }
    print("writing $generationIndex. generation:");
    assert(res.length == generationIndex);
    res.add([]);
    final List<(Person?, List<(double, double)>, String)> fullParentGeneration = [];
    for (final (parent, parentLines, dbg) in res[generationIndex - 1]) {
      print("  adding $parent:");
      fullParentGeneration.add((parent, parentLines, dbg));
      if(parent == null) {
        continue;
      }
      final siblings = parent.getChildrenByPartners(pedigree);
      // siblings.sort((a, b) => b.$2.length - a.$2.length);
      for (final (otherParentIndex, (otherParent, siblings)) in siblings.indexed) {
        print("    adding $parent's partner $otherParent with ${siblings.length} children:");
        fullParentGeneration.add((otherParent, [(fullParentGeneration.length - otherParentIndex - 1, generationIndex - 1)], "partner"));
        final siblingsWithPartners = siblings.map<(Child, List<(Person?, List<Child>)>)>(
          (e) => e is! Person ? (e, []) : (e, e.getChildrenByPartners(pedigree))
        ).toList();
        final List<Child?> sortedSiblings = [];
        for (int i = 0; siblingsWithPartners.isNotEmpty; i++) {
          final (sibling, partners) = siblingsWithPartners.reduce((a, b) {
            final drifts = (countDrift(a.$2), countDrift(b.$2));
            if(drifts.$1 == drifts.$2) {
              return a.$2.isEmpty ? b : a;
            } else {
              return drifts.$1 > drifts.$2 ? a : b;
            }
          });
          int drift = countDrift(partners);
          print("      next most drifting ($drift): $sibling");
          siblingsWithPartners.remove((sibling, partners));
          sortedSiblings.add(sibling);
          tucking: for (; drift > 0; drift--) {
            final sibling = siblingsWithPartners.safeFirstWhere((sibling) => sibling.$2.isEmpty);
            if(sibling == null) break tucking;
            print("      drift: $drift, tucking: $sibling");
            siblingsWithPartners.remove(sibling);
            sortedSiblings.add(sibling.$1);
          }
          if(drift > 0) {
            // TODO: fill with spaces to the top while not breaking lines
            print("      left with drift: $drift");
            sortedSiblings.addAll(Iterable.generate(drift).map((e) => null));
          }
/*           if(drift > 0) {
            print("      left with drift: $drift, filling with spaces");
            fullParentGeneration.addAll(Iterable.generate(drift).map((_) => (null, [], "drift of $sibling")));
            sortedSiblings.addAll(Iterable.generate(drift).map((e) => null));
            for(final (i, row) in [...res.safeSublist(0, generationIndex - 1), fullParentGeneration].indexed) {
              if(sortedSiblings.length + 1 > row.length) continue;
              /* row.sublist(sortedSiblings.length + 1).forEach((element) => {
                for(int i = 0; i < element.$2.length; i++) {
                  if(element.$2[i].$1 > sortedSiblings.length + 1) element.$2[i] = (element.$2[i].$1 + drift, element.$2[i].$2)
                }
              }); */
              row.insertAll(sortedSiblings.length + 1, Iterable.generate(drift, (_) => (null, [], "drift of $sibling")));
            }
          } */
        }
        res[generationIndex].addAll(sortedSiblings.map((e) => (
          e != null && e.id >= 0 ? pedigree.people[e.id] : null,
          [if(e != null && e.id >= 0) (fullParentGeneration.length - (otherParentIndex == 0 ? 1.5 : 1.2), generationIndex - 1)],
          e is Person ? "child of ${parent.id}, ${parent.otherParent(parent, pedigree)?.id}" : "${e.runtimeType}, ${e is HasOtherParent ? (e as HasOtherParent).otherParent(parent, pedigree)?.id : ""}",
        )));
        /* final parentsWidth = otherParentIndex == 0 ? 2 : 1;
        print("    parents' width: $parentsWidth");
        if(siblings.length < parentsWidth && res[generationIndex].length > fullParentGeneration.length) {
          print("    filling space under parents with ${parentsWidth - siblings.length} items");
          res[generationIndex].insertAll(fullParentGeneration.length, Iterable.generate(parentsWidth - siblings.length, (_) => (null, [], "space for ${parent.id} & ${otherParent?.id}")));
        } else if(siblings.length < parentsWidth) {
          print("    filling space between parents with ${siblings.length - parentsWidth} items");
          fullParentGeneration.addAll(Iterable.generate(siblings.length - parentsWidth, (_) => (null, [], "space for children of ${parent.id} & ${otherParent?.id}")));
          // fullParentGeneration.addAll(Iterable.generate(siblings.length - parentsWidth, (_) => (null, [])));
        } */
      }
    }
    res[generationIndex - 1] = fullParentGeneration;
    print("${generationIndex - 1}. generation: ${res[generationIndex - 1]}");
  }
  return res;
}

int countDrift(List<(Person?, List<Child>)> partners) {
  if(partners.isEmpty) return -1;
  return partners.last.$2.length - 1 - partners.length;
}