// lib/providers/letter_provider.dart
import 'package:flutter/material.dart';
import '../models/letter_level.dart';
import '../models/arabic_letter.dart';

class LetterProvider with ChangeNotifier {
  List<LetterLevel> _levels = [];
  int _currentLevel = 0;
  int _currentLetterIndex = 0;

  LetterProvider() {
    _initializeLevels();
  }

  List<LetterLevel> get levels => _levels;
  int get currentLevel => _currentLevel;
  int get currentLetterIndex => _currentLetterIndex;
  ArabicLetter get currentLetter => _levels[_currentLevel].letters[_currentLetterIndex];

  void _initializeLevels() {
    _levels = [
      LetterLevel(
        levelNumber: 1,
        letters: [
          ArabicLetter(character: 'ا', name: 'ألف'),
          ArabicLetter(character: 'ب', name: 'باء'),
          ArabicLetter(character: 'ت', name: 'تاء'),
          ArabicLetter(character: 'ث', name: 'ثاء'),
          ArabicLetter(character: 'ج', name: 'جيم'),
          ArabicLetter(character: 'ح', name: 'حاء'),
          ArabicLetter(character: 'خ', name: 'خاء'),
        ],
      ),
      LetterLevel(
        levelNumber: 2,
        letters: [
          ArabicLetter(character: 'د', name: 'دال'),
          ArabicLetter(character: 'ذ', name: 'ذال'),
          ArabicLetter(character: 'ر', name: 'راء'),
          ArabicLetter(character: 'ز', name: 'زاء'),
          ArabicLetter(character: 'س', name: 'سين'),
          ArabicLetter(character: 'ش', name: 'شين'),
          ArabicLetter(character: 'ص', name: 'صاد'),
        ],
      ),
      LetterLevel(
        levelNumber: 3,
        letters: [
          ArabicLetter(character: 'ض', name: 'ضاد'),
          ArabicLetter(character: 'ط', name: 'طاء'),
          ArabicLetter(character: 'ظ', name: 'ظاء'),
          ArabicLetter(character: 'ع', name: 'عين'),
          ArabicLetter(character: 'غ', name: 'غين'),
          ArabicLetter(character: 'ف', name: 'فاء'),
          ArabicLetter(character: 'ق', name: 'قاف'),
        ],
      ),
      LetterLevel(
        levelNumber: 4,
        letters: [
          ArabicLetter(character: 'ك', name: 'كاف'),
          ArabicLetter(character: 'ل', name: 'لام'),
          ArabicLetter(character: 'م', name: 'ميم'),
          ArabicLetter(character: 'ن', name: 'نون'),
          ArabicLetter(character: 'هـ', name: 'هاء'),
          ArabicLetter(character: 'و', name: 'واو'),
          ArabicLetter(character: 'ي', name: 'ياء'),
        ],
      ),
    ];
    notifyListeners();
  }


  void updateLetterResult(bool isCorrect) {
    if (isCorrect) {
      currentLetter.updateStars();
      notifyListeners();
    
      _nextLetter();
    } else {
      currentLetter.attempts += 1;
      currentLetter.updateStars();
      notifyListeners();
    }
  }

  // الانتقال إلى الحرف التالي إذا تم نطق الحرف الحالي بشكل صحيح
  void _nextLetter() {
    if (_currentLetterIndex < _levels[_currentLevel].letters.length - 1) {
      _currentLetterIndex += 1;
      notifyListeners();
    } else if (_currentLevel < _levels.length - 1) {
      _currentLevel += 1;
      _currentLetterIndex = 0;
      notifyListeners();
    } else {
      // تم إكمال جميع الحروف والمستويات
      
    }
  }

  // إعادة تعيين مستوى محدد وحرف
  void resetCurrentLetter() {
    currentLetter.resetAttempts();
    notifyListeners();
  }
}
