import 'package:flutter/foundation.dart';
import 'package:teatcher_smarter/utils/database_operations.dart';

class SentenceProgressProvider with ChangeNotifier {
  final DatabaseOperations _db = DatabaseOperations();
  Map<int, Map<String, dynamic>> _sentenceProgress = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // تحميل تقدم جميع الجمل
  Future<void> loadAllProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allProgress = await _db.getAllSentencesProgress();
      _sentenceProgress = {
        for (var progress in allProgress)
          progress['sentence_id'] as int: progress,
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تحديث تقدم جملة وحفظ آخر موقع
  Future<void> updateSentenceProgress({
    required int sentenceId,
    required bool isCorrect,
    required int level,
  }) async {
    try {
      // تحديث تقدم الجملة نفسها
      final currentProgress = _sentenceProgress[sentenceId];
      final currentAttempts = currentProgress?['attempts'] as int? ?? 0;
      final currentCorrect = currentProgress?['correct_attempts'] as int? ?? 0;

      final newAttempts = currentAttempts + 1;
      final newCorrect = currentCorrect + (isCorrect ? 1 : 0);

      // نعتبر الجملة متقنة إذا كانت نسبة الإجابات الصحيحة أكثر من 80% بعد 5 محاولات على الأقل
      final isMastered = newAttempts >= 5 && (newCorrect / newAttempts) >= 0.8;

      await _db.saveSentenceProgress(
        sentenceId: sentenceId,
        isCorrect: isCorrect,
        isMastered: isMastered,
      );

      // حفظ آخر جملة تم الوصول إليها في المستوى
      await _db.saveProgress(
        operation: 1, // العملية 1 تُمثل تقدم الجمل
        level: level,
        completedExamples: [],
        isCompleted: false,
        lastAccessedWordId: sentenceId,
      );

      // تحديث الحالة المحلية
      final progress = await _db.getSentenceProgress(sentenceId);
      if (progress != null) {
        _sentenceProgress[sentenceId] = progress;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating sentence progress: $e');
    }
  }

  // حفظ آخر جملة تم الوصول إليها بدون تحديث التقدم
  Future<void> saveLastAccessedSentence(int sentenceId, int level) async {
    try {
      await _db.saveProgress(
        operation: 1,
        level: level,
        completedExamples: [],
        isCompleted: false,
        lastAccessedWordId: sentenceId,
      );
    } catch (e) {
      print('Error saving last accessed sentence: $e');
    }
  }

  // الحصول على آخر جملة تم الوصول إليها في مستوى محدد
  Future<int?> getLastAccessedSentence(int level) async {
    try {
      final progress = await _db.getProgress(operation: 1, level: level);
      if (progress != null && progress.containsKey('last_accessed_word_id')) {
        final lastId = progress['last_accessed_word_id'] as int?;
        if (lastId != null && lastId > 0) {
          return lastId;
        }
      }
      return null;
    } catch (e) {
      print('Error getting last accessed sentence: $e');
      return null;
    }
  }

  // الحصول على تقدم جملة معينة
  Map<String, dynamic>? getSentenceProgress(int sentenceId) {
    return _sentenceProgress[sentenceId];
  }

  // التحقق مما إذا كانت الجملة متقنة
  bool isSentenceMastered(int sentenceId) {
    return _sentenceProgress[sentenceId]?['is_mastered'] as bool? ?? false;
  }

  // الحصول على مستوى الثقة في الجملة
  double getSentenceConfidence(int sentenceId) {
    return _sentenceProgress[sentenceId]?['confidence_level'] as double? ?? 0.0;
  }

  // الحصول على عدد المحاولات للجملة
  int getSentenceAttempts(int sentenceId) {
    return _sentenceProgress[sentenceId]?['attempts'] as int? ?? 0;
  }

  // الحصول على عدد المحاولات الصحيحة للجملة
  int getSentenceCorrectAttempts(int sentenceId) {
    return _sentenceProgress[sentenceId]?['correct_attempts'] as int? ?? 0;
  }

  // الحصول على نسبة النجاح للجملة
  double getSentenceSuccessRate(int sentenceId) {
    final attempts = getSentenceAttempts(sentenceId);
    if (attempts == 0) return 0.0;
    return getSentenceCorrectAttempts(sentenceId) / attempts;
  }

  // الحصول على تاريخ آخر تدريب
  DateTime? getLastPracticed(int sentenceId) {
    return _sentenceProgress[sentenceId]?['last_practiced'] as DateTime?;
  }

  // إعادة تعيين تقدم جميع الجمل
  Future<void> resetAllProgress() async {
    await _db.resetSentenceProgress();
    _sentenceProgress.clear();
    notifyListeners();
  }

  // الحصول على قائمة الجمل المكتملة في مستوى معين
  Future<List<int>> getCompletedSentences(int level) async {
    try {
      final allProgress = await _db.getAllSentencesProgress();
      final completedSentences = <int>[];

      for (var progress in allProgress) {
        final sentenceId = progress['sentence_id'] as int;
        final attempts = progress['attempts'] as int? ?? 0;
        final correctAttempts = progress['correct_attempts'] as int? ?? 0;
        
        // نعتبر الجملة مكتملة إذا تمت محاولة واحدة صحيحة على الأقل
        if (correctAttempts > 0) {
          completedSentences.add(sentenceId);
        }
      }

      return completedSentences;
    } catch (e) {
      print('Error getting completed sentences: $e');
      return [];
    }
  }

  // التحقق مما إذا كانت الجملة مكتملة
  bool isSentenceCompleted(int sentenceId) {
    final progress = _sentenceProgress[sentenceId];
    if (progress == null) return false;
    
    final correctAttempts = progress['correct_attempts'] as int? ?? 0;
    return correctAttempts > 0;
  }
}
