// lib/models/math_teaching_model.dart
import 'package:flutter/material.dart';

enum Operation { addition, subtraction, multiplication, division }

class MathTeachingModel with ChangeNotifier {
  MathExample? currentExample;
  int currentStepIndex = 0;

  // قائمة الأمثلة التعليمية
  final List<MathExample> examples = [
    // أمثلة الجمع والطرح السابقة
    MathExample(
      operation: Operation.addition,
      num1: 3,
      num2: 2,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 3.",
        "نضيف الرقم الأصغر 2 إلى الرقم الأكبر 3.",
        "الناتج النهائي هو 5."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 5,
      num2: 2,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 5.",
        "نطرح الرقم الأصغر 2 من الرقم الأكبر 5.",
        "الناتج النهائي هو 3."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 4,
      num2: 1,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 4.",
        "نضيف الرقم الأصغر 1 إلى الرقم الأكبر 4.",
        "الناتج النهائي هو 5."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 7,
      num2: 3,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 7.",
        "نطرح الرقم الأصغر 3 من الرقم الأكبر 7.",
        "الناتج النهائي هو 4."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 6,
      num2: 2,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 6.",
        "نضيف الرقم الأصغر 2 إلى الرقم الأكبر 6.",
        "الناتج النهائي هو 8."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 9,
      num2: 4,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 9.",
        "نطرح الرقم الأصغر 4 من الرقم الأكبر 9.",
        "الناتج النهائي هو 5."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 2,
      num2: 3,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 3.",
        "نضيف الرقم الأصغر 2 إلى الرقم الأكبر 3.",
        "الناتج النهائي هو 5."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 4,
      num2: 1,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 4.",
        "نطرح الرقم الأصغر 1 من الرقم الأكبر 4.",
        "الناتج النهائي هو 3."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 5,
      num2: 5,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 5.",
        "نضيف الرقم الأصغر 5 إلى الرقم الأكبر 5.",
        "الناتج النهائي هو 10."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 8,
      num2: 5,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 8.",
        "نطرح الرقم الأصغر 5 من الرقم الأكبر 8.",
        "الناتج النهائي هو 3."
      ],
    ),
    // أمثلة إضافية
    MathExample(
      operation: Operation.addition,
      num1: 7,
      num2: 4,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 7.",
        "نضيف الرقم الأصغر 4 إلى الرقم الأكبر 7.",
        "الناتج النهائي هو 11."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 10,
      num2: 3,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 10.",
        "نطرح الرقم الأصغر 3 من الرقم الأكبر 10.",
        "الناتج النهائي هو 7."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 12,
      num2: 5,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 12.",
        "نضيف الرقم الأصغر 5 إلى الرقم الأكبر 12.",
        "الناتج النهائي هو 17."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 15,
      num2: 6,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 15.",
        "نطرح الرقم الأصغر 6 من الرقم الأكبر 15.",
        "الناتج النهائي هو 9."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 9,
      num2: 8,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 9.",
        "نضيف الرقم الأصغر 8 إلى الرقم الأكبر 9.",
        "الناتج النهائي هو 17."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 14,
      num2: 7,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 14.",
        "نطرح الرقم الأصغر 7 من الرقم الأكبر 14.",
        "الناتج النهائي هو 7."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 11,
      num2: 9,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 11.",
        "نضيف الرقم الأصغر 9 إلى الرقم الأكبر 11.",
        "الناتج النهائي هو 20."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 13,
      num2: 5,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 13.",
        "نطرح الرقم الأصغر 5 من الرقم الأكبر 13.",
        "الناتج النهائي هو 8."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 20,
      num2: 10,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 20.",
        "نضيف الرقم الأصغر 10 إلى الرقم الأكبر 20.",
        "الناتج النهائي هو 30."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 18,
      num2: 9,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 18.",
        "نطرح الرقم الأصغر 9 من الرقم الأكبر 18.",
        "الناتج النهائي هو 9."
      ],
    ),
    MathExample(
      operation: Operation.addition,
      num1: 25,
      num2: 15,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 25.",
        "نضيف الرقم الأصغر 15 إلى الرقم الأكبر 25.",
        "الناتج النهائي هو 40."
      ],
    ),
    MathExample(
      operation: Operation.subtraction,
      num1: 30,
      num2: 12,
      steps: [
        "أولاً، نحدد الرقم الأكبر وهو 30.",
        "نطرح الرقم الأصغر 12 من الرقم الأكبر 30.",
        "الناتج النهائي هو 18."
      ],
    ),
    // أمثلة الضرب والقسمة المضافة
    MathExample(
      operation: Operation.multiplication,
      num1: 2,
      num2: 3,
      steps: [
        "أولاً، نعرف أن الضرب هو جمع متكرر.",
        "نضيف الرقم 2 ثلاث مرات: 2 + 2 + 2.",
        "الناتج النهائي هو 6."
      ],
    ),
    MathExample(
      operation: Operation.division,
      num1: 6,
      num2: 2,
      steps: [
        "أولاً، نعرف أن القسمة هي تقسيم الكمية إلى أجزاء متساوية.",
        "نقسم الرقم 6 على 2، أي نضع 6 في مجموعتين متساويتين.",
        "كل مجموعة تحتوي على 3."
      ],
    ),
    MathExample(
      operation: Operation.multiplication,
      num1: 4,
      num2: 5,
      steps: [
        "أولاً، نعرف أن الضرب هو جمع متكرر.",
        "نضيف الرقم 4 خمس مرات: 4 + 4 + 4 + 4 + 4.",
        "الناتج النهائي هو 20."
      ],
    ),
    MathExample(
      operation: Operation.division,
      num1: 12,
      num2: 3,
      steps: [
        "أولاً، نعرف أن القسمة هي تقسيم الكمية إلى أجزاء متساوية.",
        "نقسم الرقم 12 على 3، أي نضع 12 في ثلاث مجموعات متساوية.",
        "كل مجموعة تحتوي على 4."
      ],
    ),
    MathExample(
      operation: Operation.multiplication,
      num1: 5,
      num2: 2,
      steps: [
        "أولاً، نعرف أن الضرب هو جمع متكرر.",
        "نضيف الرقم 5 مرتين: 5 + 5.",
        "الناتج النهائي هو 10."
      ],
    ),
    MathExample(
      operation: Operation.division,
      num1: 9,
      num2: 3,
      steps: [
        "أولاً، نعرف أن القسمة هي تقسيم الكمية إلى أجزاء متساوية.",
        "نقسم الرقم 9 على 3، أي نضع 9 في ثلاث مجموعات متساوية.",
        "كل مجموعة تحتوي على 3."
      ],
    ),
    MathExample(
      operation: Operation.multiplication,
      num1: 3,
      num2: 4,
      steps: [
        "أولاً، نعرف أن الضرب هو جمع متكرر.",
        "نضيف الرقم 3 أربع مرات: 3 + 3 + 3 + 3.",
        "الناتج النهائي هو 12."
      ],
    ),
    MathExample(
      operation: Operation.division,
      num1: 8,
      num2: 2,
      steps: [
        "أولاً، نعرف أن القسمة هي تقسيم الكمية إلى أجزاء متساوية.",
        "نقسم الرقم 8 على 2، أي نضع 8 في مجموعتين متساويتين.",
        "كل مجموعة تحتوي على 4."
      ],
    ),
    MathExample(
      operation: Operation.multiplication,
      num1: 6,
      num2: 3,
      steps: [
        "أولاً، نعرف أن الضرب هو جمع متكرر.",
        "نضيف الرقم 6 ثلاث مرات: 6 + 6 + 6.",
        "الناتج النهائي هو 18."
      ],
    ),
    MathExample(
      operation: Operation.division,
      num1: 15,
      num2: 5,
      steps: [
        "أولاً، نعرف أن القسمة هي تقسيم الكمية إلى أجزاء متساوية.",
        "نقسم الرقم 15 على 5، أي نضع 15 في خمس مجموعات متساوية.",
        "كل مجموعة تحتوي على 3."
      ],
    ),
    MathExample(
      operation: Operation.multiplication,
      num1: 7,
      num2: 2,
      steps: [
        "أولاً، نعرف أن الضرب هو جمع متكرر.",
        "نضيف الرقم 7 مرتين: 7 + 7.",
        "الناتج النهائي هو 14."
      ],
    ),
    MathExample(
      operation: Operation.division,
      num1: 20,
      num2: 4,
      steps: [
        "أولاً، نعرف أن القسمة هي تقسيم الكمية إلى أجزاء متساوية.",
        "نقسم الرقم 20 على 4، أي نضع 20 في أربع مجموعات متساوية.",
        "كل مجموعة تحتوي على 5."
      ],
    ),
  ];

  void selectExample(MathExample example) {
    currentExample = example;
    currentStepIndex = 0;
    notifyListeners();
  }

  void nextStep() {
    if (currentExample != null &&
        currentStepIndex < currentExample!.steps.length - 1) {
      currentStepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentExample != null && currentStepIndex > 0) {
      currentStepIndex--;
      notifyListeners();
    }
  }

  void resetTeaching() {
    currentExample = null;
    currentStepIndex = 0;
    notifyListeners();
  }
}

class MathExample {
  final Operation operation;
  final int num1;
  final int num2;
  final List<String> steps;

  MathExample({
    required this.operation,
    required this.num1,
    required this.num2,
    required this.steps,
  });
}
