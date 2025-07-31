// lib/screens/problem_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/screens/math_Learning_screen/math_model.dart';

class ProblemScreen extends StatefulWidget {
  const ProblemScreen({super.key});

  @override
  _ProblemScreenState createState() => _ProblemScreenState();
}

class _ProblemScreenState extends State<ProblemScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mathModel = Provider.of<MathModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('حل المسألة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ما هو ناتج المسألة التالية؟',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              '${mathModel.num1} ${mathModel.getOperationSymbol} ${mathModel.num2} = ؟',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'أدخل الإجابة',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String userInput = _answerController.text.trim();
                if (userInput.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⚠️ يرجى إدخال الإجابة')),
                  );
                  return;
                }
                bool isCorrect = mathModel.checkAnswer(userInput);
                String message = isCorrect
                    ? 'أحسنت! الإجابة صحيحة.'
                    : 'إجابة خاطئة. حاول مرة أخرى.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
                if (isCorrect) {
                  mathModel.generateNewProblem();
                  _answerController.clear();
                }
              },
              child: Text('تحقق'),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // العودة إلى شاشة اختيار العمليات
              },
              icon: Icon(Icons.arrow_back),
              label: Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}
