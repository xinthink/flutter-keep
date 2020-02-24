import 'package:collection_ext/iterables.dart';
import 'package:flutter/material.dart';

import 'package:flt_keep/styles.dart';

/// Note color picker in a horizontal list style.
class LinearColorPicker extends StatefulWidget {
  /// Current selected color.
  final Color color;

  /// Listener watching color change.
  final void Function(Color) listener;

  /// Create a [LinearColorPicker] instance, provides the current selected [color].
  const LinearColorPicker({Key key, this.color, this.listener}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LinearColorPickerState();
}

/// State of [LinearColorPicker].
class _LinearColorPickerState extends State<LinearColorPicker> {
  /// Temporarily stored only, parent widget should manage the correct color.
  Color _currColor;

  @override
  void didUpdateWidget(LinearColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currColor = widget.color;
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
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
            child: color == _currColor ? const Icon(Icons.check, color: kColorPickerBorderColor) : null,
          ),
          onTap: () => _onTap(color),
        ),
        SizedBox(width: i == kNoteColors.length - 1 ? 17 : 20),
      ]).asList(),
    ),
  );

  void _onTap(Color color) {
    if (color != _currColor) {
      setState(() {
        _currColor = color;
        widget.listener?.call(color);
      });
    }
  }
}
