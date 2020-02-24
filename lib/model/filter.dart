import 'package:flutter/foundation.dart';

import 'note.dart';

/// Holds the current searching filter of notes.
class NoteFilter extends ChangeNotifier {
  NoteState _noteState;

  /// The state of note to search.
  NoteState get noteState => _noteState;
  set noteState(NoteState value) {
    if (value != null && value != _noteState) {
      _noteState = value;
      notifyListeners();
    }
  }

  /// Creates a [NoteFilter] object.
  NoteFilter([this._noteState = NoteState.unspecified]);
}
