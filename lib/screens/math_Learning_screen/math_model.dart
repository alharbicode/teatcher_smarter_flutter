
import 'package:flutter/material.dart';
import 'dart:math';


enum Operation { addition, subtraction, multiplication, division }

class MathModel with ChangeNotifier {
 
  int num1 = 0;  
  int num2 = 0; 
  Operation? currentOperation; // العملية الحسابية الحالية (يمكن أن تكون null)
  int correctAnswer = 0; 
  int userScore = 0; // نقاط المستخدم
  int correctAttempts = 0; 
  int incorrectAttempts = 0;

 
  void setOperation(Operation operation) {
    currentOperation = operation; 
    resetScore(); 
    notifyListeners(); // إعلام المستمعين بالتغييرات
  }

  // دالة لإعادة تعيين العملية الحالية (إلغاء تحديدها)
  void resetOperation() {
    currentOperation = null; // إزالة العملية الحالية
    resetScore(); 
    notifyListeners();
  }

  void resetScore() {
    userScore = 0; // إعادة النقاط إلى الصفر
    correctAttempts = 0; 
    incorrectAttempts = 0; 
  }

  // دالة لإنشاء مسألة حسابية جديدة
  void generateNewProblem() {
    if (currentOperation == null) return; // إذا لم تكن هناك عملية محددة، لا تفعل شيئًا

    Random random = Random(); 
    num1 = random.nextInt(10) + 1; 
    num2 = random.nextInt(10) + 1; 

    // ضمان أن المسألة صالحة للطرح (الرقم الأول أكبر أو يساوي الثاني)
    if (currentOperation == Operation.subtraction && num1 < num2) {
      int temp = num1; // تبديل الأرقام إذا لزم الأمر
      num1 = num2;
      num2 = temp;
    } 
    // ضمان أن المسألة صالحة للقسمة (القسمة بدون باقي)
    else if (currentOperation == Operation.division) {
      num2 = random.nextInt(9) + 1; // تجنب القسمة على الصفر (1-9)
      num1 = num2 * (random.nextInt(10) + 1); // جعل num1 مضاعفًا لـ num2
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
        correctAnswer = 0; // إذا لم تكن هناك عملية، الإجابة صفر
    }
  }

  
  bool checkAnswer(String userInput) {
    int? userAnswer = int.tryParse(userInput); // تحويل إدخال المستخدم إلى رقم
    if (userAnswer == correctAnswer) { 
      userScore += 2; // زيادة النقاط بمقدار 2
      correctAttempts++; 
      notifyListeners(); 
      return true; 
    } else { 
      incorrectAttempts++; 
      notifyListeners(); 
      return false; 
    }
  }

  String getOperationSymbol(Operation operation) {
    switch (operation) {
      case Operation.addition:
        return "+"; 
      case Operation.subtraction:
        return "-"; 
      case Operation.multiplication:
        return "×";
      case Operation.division:
        return "÷"; 
      default:
        return ""; 
    }
  }
}