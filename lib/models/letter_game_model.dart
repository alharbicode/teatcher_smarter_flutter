// lib/models/letter_game_model.dart
import 'package:flutter/material.dart';

class LetterGameModel with ChangeNotifier {
  List<List<Letter>> levels = [
    // المستوى الأول
    [
      Letter('ا'),
      Letter('ب'),
      Letter('ت'),
      Letter('ث'),
      Letter('ج'),
      Letter('ح'),
      Letter('خ'),
    ],
    // المستوى الثاني
    [
      Letter('د'),
      Letter('ذ'),
      Letter('ر'),
      Letter('ز'),
      Letter('س'),
      Letter('ش'),
      Letter('ص'),
    ],
    // المستوى الثالث
    [
      Letter('ض'),
      Letter('ط'),
      Letter('ظ'),
      Letter('ع'),
      Letter('غ'),
      Letter('ف'),
      Letter('ق'),
    ],
    // المستوى الرابع
    [
      Letter('ك'),
      Letter('ل'),
      Letter('م'),
      Letter('ن'),
      Letter('ه'),
      Letter('و'),
      Letter('ي'),
    ],
  ];

  int currentLevel = 0;
  int currentLetterIndex = 0;

  Letter get currentLetter => levels[currentLevel][currentLetterIndex];

  bool get isLastLetterInLevel =>
      currentLetterIndex == levels[currentLevel].length - 1;

  bool get isLastLevel => currentLevel == levels.length - 1;

  void updateStars(int stars) {
    currentLetter.stars = stars;
    notifyListeners();
  }

  void moveToNextLetter() {
    if (currentLetterIndex < levels[currentLevel].length - 1) {
      currentLetterIndex++;
    } else {
      if (currentLevel < levels.length - 1) {
        currentLevel++;
        currentLetterIndex = 0;
      }
      // يمكنك إضافة نهاية اللعبة هنا أو إعادة البدء
    }
    notifyListeners();
  }

  void resetGame() {
    currentLevel = 0;
    currentLetterIndex = 0;
    for (var level in levels) {
      for (var letter in level) {
        letter.stars = 0;
      }
    }
    notifyListeners();
  }
}

class Letter {
  final String character;
  int stars;

  Letter(this.character, {this.stars = 0});
}
