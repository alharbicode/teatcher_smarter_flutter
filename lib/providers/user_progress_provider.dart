import 'package:flutter/foundation.dart';
import 'package:teatcher_smarter/utils/database_operations.dart';

class UserProgressProvider with ChangeNotifier {
  final DatabaseOperations _db = DatabaseOperations();
  final Map<String, Map<String, dynamic>> _progress = {};

  // تحميل تقدم المستخدم للمستوى المحدد
  Future<void> loadProgress(int level) async {
    final operations = await _db.getCompletedOperations(level);

    for (var operation in [0, 1, 2, 3]) {
      // جميع العمليات
      final progress = await _db.getProgress(
        operation: operation,
        level: level,
      );

      if (progress != null) {
        _progress['$operation-$level'] = progress;
      }
    }

    notifyListeners();
  }

  Future<void> saveProgress({
    required int operation,
    required int level,
    required int exampleId,
    bool isCompleted = false,
  }) async {
    final key = '$operation-$level';
    final currentProgress = _progress[key] ??
        {
          'operation': operation,
          'level': level,
          'completed_examples': <int>[],
          'is_completed': false,
        };

    final completedExamples =
        List<int>.from(currentProgress['completed_examples'] as List);
    if (!completedExamples.contains(exampleId)) {
      completedExamples.add(exampleId);
    }

    await _db.saveProgress(
      operation: operation,
      level: level,
      completedExamples: completedExamples,
      isCompleted: isCompleted,
      lastAccessedWordId: null, // تمرير null لـ lastAccessedWordId
    );
    _progress[key] = {
      ...currentProgress,
      'completed_examples': completedExamples,
      'is_completed': isCompleted,
    };

    notifyListeners();
  }

  // التحقق مما إذا كان المثال قد تم إكماله
  bool isExampleCompleted(int operation, int level, int exampleId) {
    final key = '$operation-$level';
    final progress = _progress[key];
    if (progress == null) return false;

    final completedExamples = progress['completed_examples'] as List;
    return completedExamples.contains(exampleId);
  }

  // التحقق مما إذا كانت العملية مكتملة في المستوى المحدد
  bool isOperationCompleted(int operation, int level) {
    final key = '$operation-$level';
    final progress = _progress[key];
    return progress != null && progress['is_completed'] as bool;
  }

  // الحصول على عدد الأمثلة المكتملة للعملية في المستوى المحدد
  int getCompletedExamplesCount(int operation, int level) {
    final key = '$operation-$level';
    final progress = _progress[key];
    if (progress == null) return 0;

    final completedExamples = progress['completed_examples'] as List;
    return completedExamples.length;
  }

  // إعادة تعيين تقدم المستخدم
  Future<void> resetProgress() async {
    await _db.clearProgress();
    _progress.clear();
    notifyListeners();
  }
}
