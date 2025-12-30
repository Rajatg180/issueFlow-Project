import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/theme_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final ThemeStorage storage;

  ThemeCubit({required this.storage}) : super(ThemeMode.dark);

  Future<void> load() async {
    final v = await storage.readThemeMode();
    if (v == "light") emit(ThemeMode.light);
    else if (v == "system") emit(ThemeMode.system);
    else emit(ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    final v = switch (mode) {
      ThemeMode.light => "light",
      ThemeMode.system => "system",
      _ => "dark",
    };
    await storage.saveThemeMode(v);
  }

  Future<void> toggleDarkLight() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }
}
