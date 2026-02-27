import 'package:flutter/material.dart';

class ThemeState {
  const ThemeState({required this.mode});

  final ThemeMode mode;

  ThemeState copyWith({ThemeMode? mode}) => ThemeState(mode: mode ?? this.mode);
}