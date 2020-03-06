import 'package:collection_ext/iterables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flt_keep/models.dart' show Note;
import 'package:flt_keep/styles.dart';

/// Note color picker in a horizontal list style.
class LinearColorPicker extends StatelessWidget {
  /// Returns color of the note, fallbacks to the default color.
  Color _currColor(Note note) => note?.color ?? kDefaultNoteColor;

  @override
  Widget build(BuildContext context) {
    Note note = Provider.of<Note>(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kNoteColors.flatMapIndexed((i, color) => [
          if (i == 0) const SizedBox(width: 17),
          InkWell(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: kColorPickerBorderColor),
              ),
              child: color == _currColor(note) ? const Icon(Icons.check, color: kColorPickerBorderColor) : null,
            ),
            onTap: () {
              if (color != _currColor(note)) {
                note.updateWith(color: color);
              }
            },
          ),
          SizedBox(width: i == kNoteColors.length - 1 ? 17 : 20),
        ]).asList(),
      ),
    );
  }
}
