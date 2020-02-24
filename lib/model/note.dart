import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:flt_keep/services.dart' show NoteQuery;

/// Data model of a note.
class Note extends ChangeNotifier {
  final String id;
  String title;
  String content;
  Color color;
  NoteState state;
  final DateTime createdAt;
  DateTime modifiedAt;

  /// Instantiates a [Note].
  Note({
    this.id,
    this.title,
    this.content,
    this.color,
    this.state,
    DateTime createdAt,
    DateTime modifiedAt,
  }) : this.createdAt = createdAt ?? DateTime.now(),
    this.modifiedAt = modifiedAt ?? DateTime.now();

  /// Transforms the Firestore query [snapshot] into a list of [Note] instances.
  static List<Note> fromQuery(QuerySnapshot snapshot) => snapshot != null ? snapshot.toNotes() : [];

  /// Whether this note is pinned
  bool get pinned => state == NoteState.pinned;

  /// Returns an numeric form of the state
  int get stateValue => (state ?? NoteState.unspecified).index;

  bool get isNotEmpty => title?.isNotEmpty == true || content?.isNotEmpty == true;

  /// Formatted last modified time
  String get strLastModified => DateFormat.MMMd().format(modifiedAt);

  /// Update this note with another one.
  ///
  /// If [updateTimestamp] is `true`, which is the default,
  /// `modifiedAt` will be updated to `DateTime.now()`, otherwise, the value of `modifiedAt`
  /// will also be copied from [other].
  void update(Note other, {bool updateTimestamp = true}) {
    title = other.title;
    content = other.content;
    color = other.color;
    state = other.state;

    if (updateTimestamp || other.modifiedAt == null) {
      modifiedAt = DateTime.now();
    } else {
      modifiedAt = other.modifiedAt;
    }
    notifyListeners();
  }

  /// Update this note with specified properties.
  ///
  /// If [updateTimestamp] is `true`, which is the default,
  /// `modifiedAt` will be updated to `DateTime.now()`.
  Note updateWith({
    String title,
    String content,
    Color color,
    NoteState state,
    bool updateTimestamp = true,
  }) {
    if (title != null) this.title = title;
    if (content != null) this.content = content;
    if (color != null) this.color = color;
    if (state != null) this.state = state;
    if (updateTimestamp) modifiedAt = DateTime.now();
    notifyListeners();
    return this;
  }

  /// Serializes this note into a JSON object.
  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'color': color?.value,
    'state': stateValue,
    'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    'modifiedAt': (modifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
  };

  /// Make a copy of this note.
  ///
  /// If [updateTimestamp] is `true`, the defaults is `false`,
  /// timestamps both of `createdAt` & `modifiedAt` will be updated to `DateTime.now()`,
  /// or otherwise be identical with this note.
  Note copy({bool updateTimestamp = false}) => Note(
    id: id,
    createdAt: (updateTimestamp || createdAt == null) ? DateTime.now() : createdAt,
  )..update(this, updateTimestamp: updateTimestamp);

  @override
  bool operator ==(other) => other is Note &&
    (other.id ?? '') == (id ?? '') &&
    (other.title ?? '') == (title ?? '') &&
    (other.content ?? '') == (content ?? '') &&
    other.stateValue == stateValue &&
    (other.color ?? 0) == (color ?? 0);

  @override
  int get hashCode => id?.hashCode ?? super.hashCode;
}

/// State enum for a note.
enum NoteState {
  unspecified,
  pinned,
  archived,
  deleted,
}

/// Add properties/methods to [NoteState]
extension NoteStateX on NoteState {
  /// Checks if it's allowed to create a new note in this state.
  bool get canCreate => this <= NoteState.pinned;

  /// Checks if a note in this state can edit (modify / copy).
  bool get canEdit => this < NoteState.deleted;

  bool operator <(NoteState other) => (this?.index ?? 0) < (other?.index ?? 0);
  bool operator <=(NoteState other) => (this?.index ?? 0) <= (other?.index ?? 0);

  /// Message describes the state transition.
  String get message {
    switch (this) {
      case NoteState.archived:
        return 'Note archived';
      case NoteState.deleted:
        return 'Note moved to trash';
      default:
        return '';
    }
  }

  /// Label of the result-set filtered via this state.
  String get filterName {
    switch (this) {
      case NoteState.archived:
        return 'Archive';
      case NoteState.deleted:
        return 'Trash';
      default:
        return '';
    }
  }

  /// Short message explains an empty result-set filtered via this state.
  String get emptyResultMessage {
    switch (this) {
      case NoteState.archived:
        return 'Archived notes appear here';
      case NoteState.deleted:
        return 'Notes in trash appear here';
      default:
        return 'Notes you add appear here';
    }
  }
}
