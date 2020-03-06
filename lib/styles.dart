import 'package:flutter/material.dart';

/// font-weight definitions
class FontWeights {
  FontWeights._();

  static const thin = FontWeight.w100;
  static const extraLight = FontWeight.w200;
  static const light = FontWeight.w300;
  static const normal = FontWeight.normal;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.bold;
  static const extraBold = FontWeight.w800;
  static const black = FontWeight.w900;
}

const kBottomBarSize = 56.0;
const kIconTintLight = Color(0xFF5F6368);
const kIconTintCheckedLight = Color(0xFF202124);
const kLabelColorLight = Color(0xFF202124);
const kCheckedLabelBackgroudLight = Color(0x337E39FB);
// const kCheckedLabelBackgroudLight = Color(0x3FFFD23E);
const kHintTextColorLight = Color(0xFF61656A);
const kNoteTitleColorLight = Color(0xFF202124);
const kNoteTextColorLight = Color(0x99000000);
const kNoteDetailTextColorLight = Color(0xC2000000);
const kErrorColorLight = Color(0xFFD43131);
const kWarnColorLight = Color(0xFFFD9726);
const kBorderColorLight = Color(0xFFDADCE0);
const kColorPickerBorderColor = Color(0x21000000);
const kBottomAppBarColorLight = Color(0xF2FFFFFF);

const _kPurplePrimaryValue = 0xFF7E39FB;
const kAccentColorLight = MaterialColor(
  _kPurplePrimaryValue,
  <int, Color>{
    900: Color(0xFF0000c9),
    800: Color(0xFF3f00df),
    700: Color(0xFF2500d7),
    600: Color(0xFF6200ee),
    500: Color(_kPurplePrimaryValue),
    400: Color(0xFF5400e8),
    300: Color(0xFF995dff),
    200: Color(0xFFe3b8ff),
    100: Color(0xFFdab2ff),
    50: Color(0xFFfbd5ff),
  },
);

/// Available note background colors
const Iterable<Color> kNoteColors = [
  Colors.white,
  Color(0xFFF28C82),
  Color(0xFFFABD03),
  Color(0xFFFFF476),
  Color(0xFFCDFF90),
  Color(0xFFA7FEEB),
  Color(0xFFCBF0F8),
  Color(0xFFAFCBFA),
  Color(0xFFD7AEFC),
  Color(0xFFFDCFE9),
  Color(0xFFE6C9A9),
  Color(0xFFE9EAEE),
];
final kDefaultNoteColor = kNoteColors.first;

/// [TextStyle] for note title in a preview card
const kCardTitleLight = TextStyle(
  color: kNoteTitleColorLight,
  fontSize: 16,
  height: 19 / 16,
  fontWeight: FontWeights.medium,
);

/// [TextStyle] for note title in a preview card
const kNoteTitleLight = TextStyle(
  color: kNoteTitleColorLight,
  fontSize: 21,
  height: 19 / 16,
  fontWeight: FontWeights.medium,
);

/// [TextStyle] for text notes
const kNoteTextLight = TextStyle(
  color: kNoteTextColorLight,
  fontSize: 16,
  height: 1.3125,
);

/// [TextStyle] for text notes in detail view
const kNoteTextLargeLight = TextStyle(
  color: kNoteDetailTextColorLight,
  fontSize: 18,
  height: 1.3125,
);

/// [TextStyle] for checklist notes
const kChecklistTextLight = TextStyle(
  color: kNoteTextColorLight,
  fontSize: 14,
  height: 16 / 14,
);

/// [TextStyle] for checklist notes in detail view
const kChecklistTextLargeLight = TextStyle(
  color: kNoteDetailTextColorLight,
  fontSize: 18,
  height: 16 / 14,
);
