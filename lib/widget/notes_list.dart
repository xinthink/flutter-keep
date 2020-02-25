import 'package:collection_ext/iterables.dart';
import 'package:flutter/material.dart';
import 'package:flt_keep/model/note.dart';

import 'note_item.dart';

/// ListView for notes
class NotesList extends StatelessWidget {
  final List<Note> notes;
  final void Function(Note) onTap;

  const NotesList({
    Key key,
    @required this.notes,
    this.onTap,
  }) : super(key: key);

  static NotesList create({
    Key key,
    @required List<Note> notes,
    void Function(Note) onTap,
  }) => NotesList(
    key: key,
    notes: notes,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    sliver: SliverList(
      delegate: SliverChildListDelegate(
        notes.flatMapIndexed((i, note) => <Widget>[
          InkWell(
            onTap: () => onTap?.call(note),
            child: NoteItem(note: note),
          ),
          if (i < notes.length - 1) const SizedBox(height: 10),
        ]).asList(),
      ),
    ),
  );
}
