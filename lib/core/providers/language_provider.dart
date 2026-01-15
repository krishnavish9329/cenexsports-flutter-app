import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_service.dart';

/// Language provider to manage app locale
class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguageService.getSavedLanguage();
    state = Locale(savedLanguage);
  }

  Future<void> setLanguage(Locale locale) async {
    state = locale;
    await LanguageService.saveLanguage(locale.languageCode);
  }
}

/// Provider for language state
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});
