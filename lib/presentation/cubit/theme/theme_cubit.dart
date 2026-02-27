import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._prefs) : super(const ThemeState(mode: ThemeMode.system));

  final SharedPreferences _prefs;

  static const _key = 'theme_mode'; // 'system' | 'light' | 'dark'

  Future<void> hydrate() async {
    final raw = _prefs.getString(_key);
    emit(ThemeState(mode: _parse(raw)));
  }

  Future<void> setMode(ThemeMode mode) async {
    await _prefs.setString(_key, _serialize(mode));
    emit(ThemeState(mode: mode));
  }

  static ThemeMode _parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}