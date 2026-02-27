import 'package:flutter/material.dart';

Color alignmentAccent(ColorScheme scheme, String alignmentNormalized) {
  switch (alignmentNormalized) {
    case 'good':
      return scheme.tertiary; // brukar bli grön-ish i Material 3
    case 'bad':
      return scheme.error;
    default:
      return scheme.secondary; // neutral
  }
}