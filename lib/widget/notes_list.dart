import 'package:flutter/material.dart';
import 'package:flt_keep/model/note.dart';
import 'package:flt_keep/styles.dart';

import 'note_item.dart';

class NotesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    sliver: SliverFixedExtentList(
      itemExtent: 64.0,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => NoteItem(
          note: Note(
            id: '$index',
            content: 'This is note',
            color: kNoteColors.elementAt(index % kNoteColors.length),
          ),
        ),
      ),
    ),
  );
}
