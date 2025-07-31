// lib/models/level_ar.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teatcher_smarter/utils/database_operations.dart';

enum GameStatus { notStarted, inProgress, mastered }

class Letter {
  final String character;
  final String name;
  int stars;
  int attempts;
  GameStatus status;

  Letter({
    required this.character,
    required this.name,
    this.stars = 0,
    this.attempts = 0,
    this.status = GameStatus.notStarted,
  });

  // تحويل الكائن إلى خريطة لتخزينه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'character': character,
      'name': name,
      'stars': stars,
      'attempts': attempts,
      'status': status.index, // تخزين القيمة العددية للحالة
    };
  }

  // إنشاء كائن `Letter` من خريطة مسترجعة من قاعدة البيانات
  factory Letter.fromMap(Map<String, dynamic> map) {
    return Letter(
      character: map['character'],
      name: map['name'],
      stars: map['stars'],
      attempts: map['attempts'],
      status:
          GameStatus.values[map['status']], // استرجاع الحالة من القيمة العددية
    );
  }
}

class Level {
  final int levelNumber;
  final List<Letter> letters;

  Level({
    required this.levelNumber,
    required this.letters,
  });
}

class LetterModel with ChangeNotifier {
  List<Level> _levels = [];
  int _currentLevel = 0;
  int _currentLetterIndex = 0;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  final DatabaseOperations _dbHelper =
      DatabaseOperations(); // إنشاء كائن DatabaseHelper

  LetterModel() {
    _initializeLevels();
    loadData(); // تحميل البيانات من قاعدة البيانات عند إنشاء النموذج
  }

  List<Level> get levels => _levels;
  int get currentLevel => _currentLevel;
  int get currentLetterIndex => _currentLetterIndex;
  Letter get currentLetter =>
      _levels[_currentLevel].letters[_currentLetterIndex];

  void _initializeLevels() {
    // تقسيم الحروف العربية إلى ٤ مستويات، كل مستوى يحتوي على ٧ حروف
    _levels = [
      Level(
        levelNumber: 1,
        letters: [
          Letter(character: 'أ', name: 'الف'),
          Letter(character: 'ب', name: 'باء'),
          Letter(character: 'ت', name: 'تاء'),
          Letter(character: 'ث', name: 'ثاء'),
          Letter(character: 'ج', name: 'جيم'),
          Letter(character: 'ح', name: 'حاء'),
          Letter(character: 'خ', name: 'خاء'),
        ],
      ),
      Level(
        levelNumber: 2,
        letters: [
          Letter(character: 'د', name: 'دال'),
          Letter(character: 'ذ', name: 'ذال'),
          Letter(character: 'ر', name: 'راء'),
          Letter(character: 'ز', name: 'زاي'),
          Letter(character: 'س', name: 'سين'),
          Letter(character: 'ش', name: 'شين'),
          Letter(character: 'ص', name: 'صاد'),
        ],
      ),
      Level(
        levelNumber: 3,
        letters: [
          Letter(character: 'ض', name: 'ضاد'),
          Letter(character: 'ط', name: 'طاء'),
          Letter(character: 'ظ', name: 'ظاء'),
          Letter(character: 'ع', name: 'عين'),
          Letter(character: 'غ', name: 'غين'),
          Letter(character: 'ف', name: 'فاء'),
          Letter(character: 'ق', name: 'قاف'),
        ],
      ),
      Level(
        levelNumber: 4,
        letters: [
          Letter(character: 'ك', name: 'كاف'),
          Letter(character: 'ل', name: 'لام'),
          Letter(character: 'م', name: 'ميم'),
          Letter(character: 'ن', name: 'نون'),
          Letter(character: 'ه', name: 'هاء'),
          Letter(character: 'و', name: 'واو'),
          Letter(character: 'ي', name: 'ياء'),
        ],
      ),
    ];
  }

  Future<void> saveProgress() async {
    // حفظ تقدم الحروف في قاعدة البيانات
    for (var level in _levels) {
      for (var letter in level.letters) {
        await _dbHelper.insertLetter(letter);
      }
    }

    // حفظ المستوى الحالي ومؤشر الحرف الحالي في SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', _currentLevel);
    await prefs.setInt('currentLetterIndex', _currentLetterIndex);
  }

  Future<void> loadData() async {
    // استرجاع تقدم الحروف من قاعدة البيانات
    List<Letter> lettersFromDB = await _dbHelper.getLetters();

    // تحديث الحروف في المستويات بناءً على البيانات المسترجعة
    for (var letter in lettersFromDB) {
      for (var level in _levels) {
        for (var i = 0; i < level.letters.length; i++) {
          if (level.letters[i].character == letter.character) {
            level.letters[i] = letter;
          }
        }
      }
    }

    // استرجاع المستوى الحالي ومؤشر الحرف الحالي من SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLevel = prefs.getInt('currentLevel') ?? 0;
    _currentLetterIndex = prefs.getInt('currentLetterIndex') ?? 0;

    notifyListeners();
  }

  // تعديل دالة updateLetterStatus لحفظ التحديثات في قاعدة البيانات
  void updateLetterStatus(Letter letter, bool isCorrect) {
    if (isCorrect) {
      letter.attempts++;
      if (letter.attempts <= 2) {
        letter.stars = 3;
      } else if (letter.attempts == 3) {
        letter.stars = 2;
      } else if (letter.attempts >= 4) {
        letter.stars = 1;
      }
      letter.status = GameStatus.mastered;
      print('حرف ${letter.character} تم تحديث النجوم إلى ${letter.stars}');
    } else {
      letter.attempts++;
      if (letter.attempts >= 5) {
        letter.stars = 1;
        letter.status = GameStatus.mastered;
        print('حرف ${letter.character} تم تحديث النجوم إلى ${letter.stars}');
      }
    }

    _dbHelper.updateLetter(letter); // تحديث الحرف في قاعدة البيانات
    notifyListeners();
  }

  bool canProceed() {
    return currentLetter.status == GameStatus.mastered;
  }

  void proceedToNextLetter() {
    if (canProceed()) {
      if (_currentLetterIndex < _levels[_currentLevel].letters.length - 1) {
        _currentLetterIndex++;
      } else {
        if (_currentLevel < _levels.length - 1) {
          _currentLevel++;
          _currentLetterIndex = 0;
        } else {
          // تم إتمام جميع المستويات
          _isCompleted = true;
        }
      }

      saveProgress(); // حفظ التقدم بعد تحديث المؤشرات

      notifyListeners();
    }
  }
}
