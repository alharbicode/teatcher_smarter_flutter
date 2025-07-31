
import 'dart:convert';


import 'package:flutter/material.dart';


import 'package:provider/provider.dart';


import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';


import 'package:teatcher_smarter/providers/word_provider.dart';


class WordScreen extends StatefulWidget {
  final int level; 
  const WordScreen({super.key, required this.level}); // المُنشئ مع مستوى مطلوب

  @override
  _WordScreenState createState() => _WordScreenState();
}


class _WordScreenState extends State<WordScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeWords(); 
  }


  Future<void> _initializeWords() async {
    final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    await wordsProvider.loadLocalData();
    if (wordsProvider.items.isEmpty) {
      await wordsProvider
          .fetchAndSyncData(); // جلب البيانات من الإنترنت إذا لم توجد محلياً
    }
  }

  void previousWord() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--; // تقليل المؤشر إذا لم نكن في البداية
      });
    }
  }

  void nextWord() {
    final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    final levelWords = wordsProvider.items
        .where((word) => word.level == widget.level)
        .toList(); // تصفية الكلمات حسب المستوى

    if (currentIndex < levelWords.length - 1) {
      setState(() {
        currentIndex++; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'تعلم الكلمات'), 
      body: Consumer<WordsProvider>(
        // مستهلك لمزود الكلمات
        builder: (context, wordsProvider, child) {
          final levelWords = wordsProvider.items
              .where((word) => word.level == widget.level)
              .toList(); // تصفية الكلمات حسب المستوى

          if (wordsProvider.isLoading) {
            return const Center(
                child:
                    CircularProgressIndicator()); // عرض مؤشر تحميل إذا كانت البيانات تُحمّل
          }

          if (levelWords.isEmpty) {
            return const Center(
                child: Text(
                    'لا توجد كلمات متاحة لهذا المستوى')); 
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(levelWords[currentIndex]
                            .image), 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Text(
                                  'خطأ في تحميل الصورة'));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // نص الكلمة
                  Text(
                    levelWords[currentIndex].text,
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back_ios),
                        label: const Text('السابق'),
                        onPressed: currentIndex > 0
                            ? previousWord
                            : null, // تعطيل الزر إذا كنا في البداية
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_ios),
                        label: const Text('التالي'),
                        onPressed: currentIndex < levelWords.length - 1
                            ? nextWord
                            : null, 
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // مؤشر التقدم (عدد الكلمات)
                  Text(
                    'الكلمة ${currentIndex + 1} من ${levelWords.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
