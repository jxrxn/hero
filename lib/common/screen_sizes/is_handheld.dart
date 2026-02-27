import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

bool isHandheld(BuildContext context) {
  final size = MediaQuery.of(context).size;

  // Web: räkna som handheld om smal skärm
  if (kIsWeb) return size.shortestSide < 600;

  // Desktopplattformar: alltid desktop
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return false;
  }

  // iOS/Android: använd skärmstorlek
  return size.shortestSide < 600;
}