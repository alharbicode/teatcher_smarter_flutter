// lib/models/letter_model.dart
import 'package:flutter/material.dart';

class LetterModel1 with ChangeNotifier {
  List<String> arabicLetters = [
    'أ',
    'ب',
    'ت',
    'ث',
    'ج',
    'ح',
    'خ',
    'د',
    'ذ',
    'ر',
    'ز',
    'س',
    'ش',
    'ص',
    'ض',
    'ط',
    'ظ',
    'ع',
    'غ',
    'ف',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'ه',
    'و',
    'ي'
  ];

  Map<String, String> letterNames = {
    'أ': 'الف',
    'ب': 'باء',
    'ت': 'تاء',
    'ث': 'ثاء',
    'ج': 'جيم',
    'ح': 'حاء',
    'خ': 'خاء',
    'د': 'دال',
    'ذ': 'ذال',
    'ر': 'راء',
    'ز': 'زاي',
    'س': 'سين',
    'ش': 'شين',
    'ص': 'صاد',
    'ض': 'ضاد',
    'ط': 'طاء',
    'ظ': 'ظاء',
    'ع': 'عين',
    'غ': 'غين',
    'ف': 'فاء',
    'ق': 'قاف',
    'ك': 'كاف',
    'ل': 'لام',
    'م': 'ميم',
    'ن': 'نون',
    'ه': 'هاء',
    'و': 'واو',
    'ي': 'ياء',
  };

  int currentIndex = 0;

  String get currentLetter => arabicLetters[currentIndex];

  String get currentLetterName => letterNames[currentLetter]!;

  void nextLetter() {
    if (currentIndex < arabicLetters.length - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  void previousLetter() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }
}
