import 'package:flutter/material.dart';

import 'package:flt_keep/models.dart' show Note;

import 'note_item.dart';

/// Grid view of [Note]s.
class NotesGrid extends StatelessWidget {
  final List<Note> notes;
  final void Function(Note) onTap;

  const NotesGrid({
    Key key,
    @required this.notes,
    this.onTap,
  }) : super(key: key);

  static NotesGrid create({
    Key key,
    @required List<Note> notes,
    void Function(Note) onTap,
  }) => NotesGrid(
    key: key,
    notes: notes,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    sliver: SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 1 / 1.2,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) => _noteItem(context, notes[index]),
        childCount: notes.length,
      ),
    ),
  );

  Widget _noteItem(BuildContext context, Note note) => InkWell(
    onTap: () => onTap?.call(note),
    child: NoteItem(note: note),
  );
}
