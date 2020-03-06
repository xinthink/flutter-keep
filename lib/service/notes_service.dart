import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection_ext/iterables.dart';
import 'package:flutter/material.dart';

import 'package:flt_keep/models.dart' show Note, NoteState;
import 'package:flt_keep/styles.dart';

/// An undoable action to a [Note].
@immutable
abstract class NoteCommand {
  final String id;
  final String uid;

  /// Whether this command should dismiss the current screen.
  final bool dismiss;

  /// Defines an undoable action to a note, provides the note [id], and current user [uid].
  const NoteCommand({
    @required this.id,
    @required this.uid,
    this.dismiss = false,
  });

  /// Returns `true` if this command is undoable.
  bool get isUndoable => true;

  /// Returns message about the result of the action.
  String get message => '';

  /// Executes this command.
  Future<void> execute();

  /// Undo this command.
  Future<void> revert();
}

/// A [NoteCommand] to update state of a [Note].
class NoteStateUpdateCommand extends NoteCommand {
  final NoteState from;
  final NoteState to;

  /// Create a [NoteCommand] to update state of a note [from] the current state [to] another.
  NoteStateUpdateCommand({
    @required String id,
    @required String uid,
    @required this.from,
    @required this.to,
    bool dismiss = false,
  }) : super(id: id, uid: uid, dismiss: dismiss);

  @override
  String get message {
    switch (to) {
      case NoteState.deleted:
        return 'Note moved to trash';
      case NoteState.archived:
        return 'Note archived';
      case NoteState.pinned:
        return from == NoteState.archived
          ? 'Note pinned and unarchived' // pin an archived note
          : '';
      default:
        switch (from) {
          case NoteState.archived:
            return 'Note unarchived';
          case NoteState.deleted:
            return 'Note restored';
          default:
            return '';
      }
    }
  }

  @override
  Future<void> execute() => updateNoteState(to, id, uid);

  @override
  Future<void> revert() => updateNoteState(from, id, uid);
}

/// Mixin helps handle a [NoteCommand].
mixin CommandHandler<T extends StatefulWidget> on State<T> {
  /// Processes the given [command].
  Future<void> processNoteCommand(ScaffoldState scaffoldState, NoteCommand command) async {
    if (command == null) {
      return;
    }
    await command.execute();
    final msg = command.message;
    if (mounted && msg?.isNotEmpty == true && command.isUndoable) {
      scaffoldState?.showSnackBar(SnackBar(
        content: Text(msg),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => command.revert(),
        ),
      ));
    }
  }
}

/// Add note related methods to [QuerySnapshot].
extension NoteQuery on QuerySnapshot {
  /// Transforms the query result into a list of notes.
  List<Note> toNotes() => documents
    .map((d) => d.toNote())
    .nonNull
    .asList();
}

/// Add note related methods to [QuerySnapshot].
extension NoteDocument on DocumentSnapshot {
  /// Transforms the query result into a list of notes.
  Note toNote() => exists
    ? Note(
      id: documentID,
      title: data['title'],
      content: data['content'],
      color: _parseColor(data['color']),
      state: NoteState.values[data['state'] ?? 0],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(data['modifiedAt'] ?? 0),
    )
    : null;

  Color _parseColor(num colorInt) => Color(colorInt ?? kNoteColors.first.value);
}

/// Add FireStore related methods to the [Note] model.
extension NoteStore on Note {
  /// Save this note in FireStore.
  ///
  /// If this's a new note, a FireStore document will be created automatically.
  Future<dynamic> saveToFireStore(String uid) async {
    final col = notesCollection(uid);
    return id == null
      ? col.add(toJson())
      : col.document(id).updateData(toJson());
  }

  /// Update this note to the given [state].
  Future<void> updateState(NoteState state, String uid) async => id == null
    ? updateWith(state: state) // new note
    : updateNoteState(state, id, uid);
}

/// Returns reference to the notes collection of the user [uid].
CollectionReference notesCollection(String uid) => Firestore.instance.collection('notes-$uid');

/// Returns reference to the given note [id] of the user [uid].
DocumentReference noteDocument(String id, String uid) => notesCollection(uid).document(id);

/// Update a note to the [state], using information in the [command].
Future<void> updateNoteState(NoteState state, String id, String uid) =>
  updateNote({'state': state?.index ?? 0}, id, uid);

/// Update a note [id] of user [uid] with properties [data].
Future<void> updateNote(Map<String, dynamic> data, String id, String uid) =>
  noteDocument(id, uid).updateData(data);
