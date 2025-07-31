// lib/models/math_model.dart
import 'package:flutter/material.dart';
import 'dart:math';

enum Operation { addition, subtraction, multiplication, division }

class MathModel with ChangeNotifier {
  int num1 = 0;
  int num2 = 0;
  Operation? currentOperation;
  int correctAnswer = 0;
  int userScore = 0;
  int correctAttempts = 0;
  int incorrectAttempts = 0;

  void setOperation(Operation operation) {
    currentOperation = operation;
    resetScore();
    notifyListeners();
  }

  void resetOperation() {
    currentOperation = null;
    resetScore();
    notifyListeners();
  }

  void resetScore() {
    userScore = 0;
    correctAttempts = 0;
    incorrectAttempts = 0;
  }

  void incrementScore() {
    userScore++;
    correctAttempts++;
    notifyListeners();
  }

  void decrementScore() {
    if (userScore > 0) {
      userScore--;
    }
    incorrectAttempts++;
    notifyListeners();
  }

  void generateNewProblem() {
    if (currentOperation == null) return;

    Random random = Random();
    num1 = random.nextInt(10) + 1; // أرقام من 1 إلى 10
    num2 = random.nextInt(10) + 1;

    // التأكد من صحة الأرقام للعمليات المختلفة
    if (currentOperation == Operation.subtraction && num1 < num2) {
      // تبديل الأرقام لضمان أن num1 أكبر أو يساوي num2
      int temp = num1;
      num1 = num2;
      num2 = temp;
    } else if (currentOperation == Operation.division) {
      // التأكد من أن num1 قابل للقسمة على num2 بدون باقي
      num2 = random.nextInt(9) + 1; // تأكد من أن num2 ليس صفراً
      num1 = num2 * (random.nextInt(10) + 1); // num1 هو مضاعف لـ num2
    }

    calculateAnswer();
    notifyListeners();
  }

  void calculateAnswer() {
    switch (currentOperation) {
      case Operation.addition:
        correctAnswer = num1 + num2;
        break;
      case Operation.subtraction:
        correctAnswer = num1 - num2;
        break;
      case Operation.multiplication:
        correctAnswer = num1 * num2;
        break;
      case Operation.division:
        correctAnswer = num1 ~/ num2;
        break;
      default:
        correctAnswer = 0;
    }
  }

  bool checkAnswer(String userInput) {
    int? userAnswer = int.tryParse(userInput);
    if (userAnswer == correctAnswer) {
      userScore += 2;
      correctAttempts++;
      notifyListeners();
      return true;
    } else {
      incorrectAttempts++;
      notifyListeners();
      return false;
    }
  }
}
