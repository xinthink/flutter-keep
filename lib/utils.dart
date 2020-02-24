import 'dart:io';

import 'package:flutter/foundation.dart';

/// [Platform] is NOT supported on Web, make a workaround.
bool get isNotIOS => kIsWeb || Platform.operatingSystem != 'ios';

/// [Platform] is NOT supported on Web, make a workaround.
bool get isNotAndroid => kIsWeb || Platform.operatingSystem != 'android';
