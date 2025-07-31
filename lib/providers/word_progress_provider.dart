import 'package:flutter/foundation.dart';
import 'package:teatcher_smarter/utils/database_operations.dart';

class WordProgressProvider with ChangeNotifier {
  final DatabaseOperations _db = DatabaseOperations();
  Map<int, Map<String, dynamic>> _wordProgress = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // تحميل تقدم جميع الكلمات
  Future<void> loadAllProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allProgress = await _db.getAllWordsProgress();
      _wordProgress = {
        for (var progress in allProgress)
          progress['word_id'] as int: progress,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  

  // تحديث تقدم كلمة
  Future<void> updateWordProgress({
    required int wordId,
    required bool isCorrect, required int level,
  }) async {
    // حساب ما إذا كانت الكلمة متقنة
    final currentProgress = _wordProgress[wordId];
    final currentAttempts = currentProgress?['attempts'] as int? ?? 0;
    final currentCorrect = currentProgress?['correct_attempts'] as int? ?? 0;

    final newAttempts = currentAttempts + 1;
    final newCorrect = currentCorrect + (isCorrect ? 1 : 0);

    // نعتبر الكلمة متقنة إذا كانت نسبة الإجابات الصحيحة أكثر من 80% بعد 5 محاولات على الأقل
    final isMastered = newAttempts >= 5 && (newCorrect / newAttempts) >= 0.8;

    await _db.saveWordProgress(
      wordId: wordId,
      isCorrect: isCorrect,
      isMastered: isMastered,
    );

    // حفظ آخر كلمة تم الوصول إليها في المستوى
    await _db.saveProgress(
      operation: 2, // استخدام العملية 2 للكلمات
      level: level,
      completedExamples: [],
      isCompleted: false,
      lastAccessedWordId: wordId,
    );

    // تحديث الحالة المحلية
    final progress = await _db.getWordProgress(wordId);
    if (progress != null) {
      _wordProgress[wordId] = progress;
      notifyListeners();
    }
  }

  // الحصول على آخر كلمة تم الوصول إليها في مستوى معين
  Future<int?> getLastAccessedWord(int level) async {
    final progress = await _db.getProgress(operation: 2, level: level); // استخدام العملية 2 للكلمات
    if (progress != null && progress.containsKey('last_accessed_word_id')) {
      return progress['last_accessed_word_id'] as int?;
    }
    return null;
  }

  // الحصول على تقدم كلمة معينة
  Map<String, dynamic>? getWordProgress(int wordId) {
    return _wordProgress[wordId];
  }

  // التحقق مما إذا كانت الكلمة متقنة
  bool isWordMastered(int wordId) {
    return _wordProgress[wordId]?['is_mastered'] == true;
  }

  // الحصول على مستوى الثقة في الكلمة
  double getWordConfidence(int wordId) {
    return _wordProgress[wordId]?['confidence_level'] as double? ?? 0.0;
  }

  // الحصول على عدد المحاولات للكلمة
  int getWordAttempts(int wordId) {
    return _wordProgress[wordId]?['attempts'] as int? ?? 0;
  }

  // الحصول على عدد المحاولات الصحيحة للكلمة
  int getWordCorrectAttempts(int wordId) {
    return _wordProgress[wordId]?['correct_attempts'] as int? ?? 0;
  }

  // الحصول على نسبة النجاح للكلمة
  double getWordSuccessRate(int wordId) {
    final attempts = getWordAttempts(wordId);
    if (attempts == 0) return 0.0;
    return getWordCorrectAttempts(wordId) / attempts;
  }

  // الحصول على تاريخ آخر تدريب
  DateTime? getLastPracticed(int wordId) {
    return _wordProgress[wordId]?['last_practiced'] as DateTime?;
  }

  // إعادة تعيين تقدم جميع الكلمات
  Future<void> resetAllProgress() async {
    await _db.resetWordProgress();
    _wordProgress.clear();
    notifyListeners();
  }
}