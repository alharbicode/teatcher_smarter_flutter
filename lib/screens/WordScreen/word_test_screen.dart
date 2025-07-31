import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import 'package:teatcher_smarter/models_for_api/word_model.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';
import 'package:teatcher_smarter/providers/word_progress_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:math';

import 'package:teatcher_smarter/widgets/result_dialog.dart';
import 'package:teatcher_smarter/custom_widgets/general_custom_widgets.dart';

class WordTestScreen extends StatefulWidget {
  final int level;

  const WordTestScreen({super.key, required this.level});

  @override
  _WordTestScreenState createState() => _WordTestScreenState();
}

class _WordTestScreenState extends State<WordTestScreen> {
  late WordsProvider wordsProvider;
  late FlutterTts flutterTts;
  WordModel? currentWord;
  List<String> shuffledLetters = [];
  String assembledWord = '';
  bool isProcessing = false;
  bool isWordModified = false;
  bool isSpeaking = false;
  Set<String> selectedLetters = {};
  int score = 0;
  int totalQuestions = 0;
  double speechRate = 0.5; // معدل سرعة النطق الافتراضي
  int consecutiveCorrectAnswers = 0; // عدد الإجابات الصحيحة المتتالية
  bool isHintMode = false; // وضع المساعدة
  bool useLetterByLetterMode = false; // وضع النطق حرف بحرف

  // رسائل النجاح المتنوعة
  final List<String> correctMessages = [
    "أحسنت!",
    "ممتاز!",
    "رائع!",
    "عمل جيد!",
    "إجابة صحيحة!",
    "أنت رائع!",
    "واصل تقدمك!",
    "أداء ممتاز!",
  ];

  // رسائل المحاولة مرة أخرى
  final List<String> incorrectMessages = [
    "حاول مرة أخرى",
    "لا بأس، استمر في المحاولة",
    "أنت تستطيع فعلها!",
    "حاول مرة أخرى، أنت قريب",
  ];
  @override
  void initState() {
    super.initState(); // استدعاء دالة initState من الكلاس الأب
    wordsProvider = Provider.of<WordsProvider>(context,
        listen: false); // الحصول على كائن WordsProvider
    _initializeWords(); // تهيئة الكلمات
    _initializeFlutterTts(); // تهيئة محرك النطق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage(); // نطق رسالة الترحيب بعد اكتمال بناء الواجهة
    });
  }

  void _initializeWords() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await wordsProvider.loadLocalData(); // تحميل البيانات المحلية
      await wordsProvider.fetchAndSyncData(); // جلب ومزامنة البيانات من المصدر
      wordsProvider.filterByLevel(widget.level); // تصفية الكلمات حسب المستوى
      if (mounted) {
        // التأكد من أن الواجهة ما زالت مبنية
        setState(() {
          currentWord = wordsProvider.currentWord; // تعيين الكلمة الحالية
          if (currentWord != null) {
            _initializeShuffledLetters(
                currentWord!.text); // تهيئة الحروف المخلوطة
          }
        });
      }
    });
  }

  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts(); // إنشاء كائن FlutterTts
    await flutterTts.setLanguage("ar-SA"); // تعيين اللغة العربية
    await flutterTts.setPitch(1.0); // ضبط درجة الصوت
    await flutterTts.setSpeechRate(speechRate); // ضبط سرعة النطق
    flutterTts.awaitSpeakCompletion(true); // انتظار اكتمال النطق
    flutterTts.setCompletionHandler(() {
      // معالج عند اكتمال النطق
      setState(() {
        isSpeaking = false; // تحديث حالة النطق
      });
    });
  }

  Future<void> speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop(); // إيقاف النطق إذا كان جارياً
    }

    setState(() {
      isProcessing = true; // تحديث حالة المعالجة
      isSpeaking = true; // تحديث حالة النطق
    });
    await flutterTts.speak(text); // بدء النطق
    await flutterTts.awaitSpeakCompletion(true); // انتظار اكتمال النطق
    setState(() {
      isProcessing = false; // تحديث حالة المعالجة
      isSpeaking = false; // تحديث حالة النطق
    });
  }

// دالة لنطق الكلمة حرف بحرف
  Future<void> speakLetterByLetter(String word) async {
    if (word.isEmpty) return; // الخروج إذا كانت الكلمة فارغة

    setState(() {
      isProcessing = true; // تحديث حالة المعالجة
      isSpeaking = true; // تحديث حالة النطق
    });

    // نطق الكلمة كاملة أولاً
    await flutterTts.speak(word);
    await Future.delayed(const Duration(seconds: 1));

    // إعلان أنه سيتم نطق الحروف
    await flutterTts.speak("سأنطق الحروف");
    await Future.delayed(const Duration(seconds: 1));

    // نطق كل حرف على حدة
    for (int i = 0; i < word.length; i++) {
      await flutterTts.speak(word[i]); // نطق الحرف الحالي
      await Future.delayed(
          const Duration(milliseconds: 800)); // تأخير بين الحروف
    }

    // إعادة نطق الكلمة كاملة
    await Future.delayed(const Duration(milliseconds: 500));
    await flutterTts.speak("$word، هذه هي الكلمة كاملة");

    setState(() {
      isProcessing = false; // تحديث حالة المعالجة
      isSpeaking = false; // تحديث حالة النطق
    });
  }

  void _speakWelcomeMessage() {
    String levelName = ''; // اسم المستوى
    switch (widget.level) {
      // تحديد اسم المستوى حسب القيمة
      case 1:
        levelName = 'المبتدئ';
        break;
      case 2:
        levelName = 'المتوسط';
        break;
      case 3:
        levelName = 'المتقدم';
        break;
    }
    speak(
        'مرحباً بك في اختبار كتابة الكلمات في المستوى $levelName'); // نطق رسالة الترحيب
  }

  void _initializeShuffledLetters(String word) {
    if (word.isNotEmpty) {
      // إذا كانت الكلمة غير فارغة
      setState(() {
        shuffledLetters = List.from(word.split(''))
          ..shuffle(); // تقسيم الكلمة إلى حروف وخلطها
        assembledWord = ''; // تهيئة الكلمة المجمعة
        selectedLetters.clear(); // مسح الحروف المحددة
        isWordModified = false; // إعادة تعيين حالة التعديل
      });
    }
  }

  void _handleLetterTap(String letter) {
    setState(() {
      if (selectedLetters.contains(letter)) {
        // إذا كان الحرف محدداً بالفعل
        selectedLetters.remove(letter); // إزالة الحرف من المحددات
        int lastIndex =
            assembledWord.lastIndexOf(letter); // البحث عن آخر ظهور للحرف
        if (lastIndex != -1) {
          assembledWord = assembledWord.substring(0, lastIndex) +
              assembledWord
                  .substring(lastIndex + 1); // إزالة الحرف من الكلمة المجمعة
        }
      } else {
        selectedLetters.add(letter); // إضافة الحرف إلى المحددات
        assembledWord += letter; // إضافة الحرف إلى الكلمة المجمعة
      }
      isWordModified = assembledWord.isNotEmpty; // تحديث حالة التعديل
    });
  }

  void _checkAnswer() async {
    if (assembledWord.isEmpty) return; // الخروج إذا لم يتم تجميع كلمة

    setState(() {
      isProcessing = true; // تحديث حالة المعالجة
    });

    if (currentWord != null) {
      bool isCorrect =
          assembledWord == currentWord!.text; // التحقق من صحة الإجابة

      if (isCorrect) {
        // زيادة عداد الإجابات الصحيحة المتتالية
        setState(() {
          consecutiveCorrectAnswers++;
        });
      } else {
        setState(() {
          consecutiveCorrectAnswers = 0; // إعادة ضبط العداد عند الإجابة الخاطئة
        });
      }

      // عرض الـ Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResultDialog(
          isCorrect: isCorrect,
          message: isCorrect
              ? correctMessages[Random().nextInt(
                  correctMessages.length)] // رسالة عشوائية للجواب الصحيح
              : incorrectMessages[Random().nextInt(
                  incorrectMessages.length)], // رسالة عشوائية للجواب الخاطئ
          onClose: () {
            Navigator.of(context).pop(); // إغلاق الـ Dialog
            if (isCorrect) {
              wordsProvider.markWordAsCompleted(
                  currentWord!); // وضع علامة على الكلمة كمكتملة
              setState(() {
                score++; // زيادة النقاط
              });
              // الانتقال إلى الكلمة التالية تلقائياً عند الإجابة الصحيحة
              if (wordsProvider.hasNextWord()) {
                wordsProvider.nextWord(); // الانتقال للكلمة التالية
                setState(() {
                  currentWord =
                      wordsProvider.currentWord; // تحديث الكلمة الحالية
                  if (currentWord != null) {
                    _initializeShuffledLetters(
                        currentWord!.text); // تهيئة الحروف للكلمة الجديدة
                  }
                });

                // إخبار المستخدم بعدد الكلمات المتبقية
                if (wordsProvider.remainingWordsCount() <= 3) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    speak(
                        "بقي ${wordsProvider.remainingWordsCount()} كلمات فقط!"); // نطق عدد الكلمات المتبقية
                  });
                }
              } else {
                // إذا كانت آخر كلمة، نعرض نتيجة الاختبار
                _showTestResult(); // عرض نتيجة الاختبار
              }
            } else {
              setState(() {
                assembledWord = ''; // إعادة تعيين الكلمة المجمعة
                selectedLetters.clear(); // مسح الحروف المحددة
              });
            }
            totalQuestions++; // زيادة عدد الأسئلة الكلي
            setState(() {
              isProcessing = false; // تحديث حالة المعالجة
              isWordModified = false; // تحديث حالة التعديل
            });
          },
        ),
      );
    }
  }

  void _resetShuffledLetters() {
    if (currentWord != null) {
      // التحقق من وجود كلمة حالية
      _initializeShuffledLetters(
          currentWord!.text); // إعادة تهيئة الحروف المخلوطة للكلمة الحالية
    }
  }

  void _showTestResult() {
    // تحضير رسالة النتيجة النهائية والصوت المناسب
    String resultMessage = ''; // رسالة النتيجة النصية
    String soundMessage = ''; // رسالة النتيجة الصوتية

    double resultPercentage =
        (score / totalQuestions) * 100; // حساب النسبة المئوية للنتيجة

    if (resultPercentage >= 90) {
      // إذا كانت النسبة 90% أو أكثر
      resultMessage = 'ممتاز! نتيجة رائعة.'; // تعيين رسالة النص
      soundMessage =
          'ممتاز! لقد أحرزت $score نقطة من أصل $totalQuestions. أنت متفوق!'; // تعيين رسالة الصوت
    } else if (resultPercentage >= 75) {
      // إذا كانت النسبة بين 75-89%
      resultMessage = 'جيد جداً! استمر في التقدم.'; // تعيين رسالة النص
      soundMessage =
          'جيد جداً! لقد أحرزت $score نقطة من أصل $totalQuestions. واصل التقدم!'; // تعيين رسالة الصوت
    } else if (resultPercentage >= 50) {
      // إذا كانت النسبة بين 50-74%
      resultMessage = 'جيد! يمكنك التحسن أكثر.'; // تعيين رسالة النص
      soundMessage =
          'جيد! لقد أحرزت $score نقطة من أصل $totalQuestions. استمر في التدرب لتحسين مستواك.'; // تعيين رسالة الصوت
    } else {
      // إذا كانت النسبة أقل من 50%
      resultMessage = 'استمر في التدريب، أنت تستطيع!'; // تعيين رسالة النص
      soundMessage =
          'لقد أحرزت $score نقطة من أصل $totalQuestions. لا تستسلم! مع المزيد من التدريب ستتحسن.'; // تعيين رسالة الصوت
    }

    // تشغيل الصوت بعد ظهور النتيجة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      speak(soundMessage); // نطق رسالة النتيجة الصوتية
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'نتيجة الاختبار',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resultPercentage >= 75 ? Icons.emoji_events : Icons.star,
              color: resultPercentage >= 75 ? Colors.amber : Colors.blue,
              size: 70,
            ),
            const SizedBox(height: 16),
            Text(
              'لقد أكملت الاختبار!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'النتيجة: $score/$totalQuestions',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              resultMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: resultPercentage >= 75 ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartTest();
            },
            child: const Text('إعادة الاختبار'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('العودة للقائمة'),
          ),
        ],
      ),
    );
  }

  void _restartTest() {
    wordsProvider.filterByLevel(widget.level); // تصفية الكلمات حسب المستوى
    if (currentWord != null) {
      // إذا كانت هناك كلمة حالية
      _initializeShuffledLetters(
          currentWord!.text); // إعادة تهيئة الحروف المخلوطة
    }
    setState(() {
      // تحديث حالة الواجهة
      score = 0; // إعادة تعيين النقاط
      totalQuestions = 0; // إعادة تعيين عدد الأسئلة
      isProcessing = false; // إعادة تعيين حالة المعالجة
      isWordModified = false; // إعادة تعيين حالة التعديل
      assembledWord = ''; // مسح الكلمة المجمعة
      selectedLetters.clear(); // مسح الحروف المحددة
    });
  }

  Future<void> changeSpeechRate(double newRate) async {
    setState(() {
      speechRate = newRate; // تحديث سرعة النطق
    });
    await flutterTts.setSpeechRate(newRate); // تطبيق سرعة النطق الجديدة

    // إعطاء تنبيه صوتي بتغيير السرعة
    String speedMessage = newRate <= 0.3
        ? "تم ضبط سرعة النطق على بطيء" // إذا كانت السرعة بطيئة
        : newRate >= 0.7
            ? "تم ضبط سرعة النطق على سريع" // إذا كانت السرعة سريعة
            : "تم ضبط سرعة النطق على متوسط"; // إذا كانت السرعة متوسطة

    await speak(speedMessage); // نطق رسالة تغيير السرعة
  }

  Future<void> provideHint() async {
    if (currentWord == null) return; // الخروج إذا لم تكن هناك كلمة حالية

    setState(() {
      isHintMode = true; // تفعيل وضع المساعدة
    });

    // نطق الكلمة ببطء مع التركيز على كل حرف
    await speak("استمع جيداً للكلمة"); // رسالة توجيهية
    await Future.delayed(const Duration(milliseconds: 500)); // تأخير قصير

    String currentWordText = currentWord!.text; // الحصول على نص الكلمة الحالية

    // نطق الكلمة كاملة
    await speak(currentWordText); // نطق الكلمة
    await Future.delayed(const Duration(milliseconds: 500)); // تأخير قصير

    // نطق أول حرفين من الكلمة
    if (currentWordText.length >= 2) {
      // إذا كانت الكلمة مكونة من حرفين على الأقل
      String firstTwoLetters =
          currentWordText.substring(0, 2); // استخراج أول حرفين
      await speak("الكلمة تبدأ بـ $firstTwoLetters"); // نطق الحرفين الأولين
    }

    setState(() {
      isHintMode = false; // إنهاء وضع المساعدة
    });
  }

  Future<void> playSuccessSound() async {
    // زيادة عداد الإجابات الصحيحة المتتالية
    consecutiveCorrectAnswers++; // زيادة العداد

    // اختيار رسالة تحفيزية بناءً على عدد الإجابات الصحيحة المتتالية
    String motivationalMessage; // رسالة تحفيزية

    if (consecutiveCorrectAnswers >= 5) {
      // إذا كانت 5 إجابات صحيحة متتالية
      motivationalMessage = "رائع جدًا! أنت عبقري!";
    } else if (consecutiveCorrectAnswers >= 3) {
      // إذا كانت 3 إجابات صحيحة متتالية
      motivationalMessage = "ممتاز! استمر في العمل الجيد!";
    } else {
      // أقل من 3 إجابات صحيحة متتالية
      List<String> messages = [
        // قائمة بالرسائل التحفيزية
        "أحسنت!",
        "ممتاز!",
        "رائع!",
        "عمل جيد!",
        "إجابة صحيحة!"
      ];
      motivationalMessage =
          messages[score % messages.length]; // اختيار رسالة عشوائية
    }

    await speak(motivationalMessage); // نطق الرسالة التحفيزية
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WordsProvider, WordProgressProvider>(
      builder: (context, wordsProvider, progressProvider, child) {
        // تحديث currentWord عندما يتغير في Provider
        if (currentWord != wordsProvider.currentWord) {
          // إذا تغيرت الكلمة الحالية
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // التأكد من أن الواجهة ما زالت نشطة
              setState(() {
                // تحديث الحالة
                currentWord = wordsProvider.currentWord; // تحديث الكلمة الحالية
                if (currentWord != null) {
                  _initializeShuffledLetters(
                      currentWord!.text); // تهيئة الحروف الجديدة
                }
              });
            }
          });
        }

        if (currentWord == null) {
          // إذا لم تكن هناك كلمة حالية
          return const Scaffold(
            // عرض واجهة التحميل
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final wordProgress =
            progressProvider.getWordProgress(currentWord!.id); // تقدم الكلمة
        final attempts =
            progressProvider.getWordAttempts(currentWord!.id); // عدد المحاولات
        final successRate =
            progressProvider.getWordSuccessRate(currentWord!.id); // معدل النجاح
        final isMastered = progressProvider
            .isWordMastered(currentWord!.id); // هل تم إتقان الكلمة

        return Scaffold(
          appBar: CustomAppBar(
            title: 'اختبار الكلمات - المستوى ${widget.level + 1}',
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade100, Colors.white],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('المحاولات'),
                                  Text('$attempts'),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('نسبة النجاح'),
                                  Text(
                                      '${(successRate * 100).toStringAsFixed(1)}%'),
                                ],
                              ),
                              if (isMastered)
                                const Icon(Icons.star, color: Colors.amber),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'النتيجة: $score/$totalQuestions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      if (currentWord!.image.isNotEmpty)
                        Container(
                          height: 180,
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              base64.decode(currentWord!.image),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      AssembledWordWidget(
                        assembledWord: assembledWord,
                        textColor: Colors.black87,
                        fontSize: 32,
                        placeholder: '____',
                      ),
                      SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: shuffledLetters.map((letter) {
                          bool isSelected = selectedLetters.contains(letter);
                          return LetterWidget(
                            letter: letter,
                            isSelected: isSelected,
                            onTap: () => _handleLetterTap(letter),
                            selectedColor: Colors.grey.shade400,
                            defaultColor: Colors.blue,
                            fontSize: 24,
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20),

                      // أزرار التحكم في النطق والمساعدة
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildControlButton(
                                  icon: Icons.volume_up,
                                  label: 'نطق الكلمة',
                                  onPressed:
                                      !isProcessing && currentWord != null
                                          ? () {
                                              if (useLetterByLetterMode) {
                                                speakLetterByLetter(
                                                    currentWord!.text);
                                              } else {
                                                speak(currentWord!.text);
                                              }
                                            }
                                          : null,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 15),
                                _buildControlButton(
                                  icon: Icons.text_format,
                                  label: useLetterByLetterMode
                                      ? 'نطق كامل'
                                      : 'نطق حروف',
                                  onPressed:
                                      !isProcessing && currentWord != null
                                          ? () {
                                              setState(() {
                                                useLetterByLetterMode =
                                                    !useLetterByLetterMode;
                                              });
                                              if (useLetterByLetterMode) {
                                                speakLetterByLetter(
                                                    currentWord!.text);
                                              } else {
                                                speak(
                                                    "تم التبديل إلى وضع النطق الكامل");
                                              }
                                            }
                                          : null,
                                  color: useLetterByLetterMode
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 15),
                                _buildControlButton(
                                  icon: Icons.lightbulb_outline,
                                  label: 'تلميح',
                                  onPressed: !isProcessing &&
                                          !isHintMode &&
                                          currentWord != null
                                      ? provideHint
                                      : null,
                                  color: Colors.amber,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // خيارات سرعة النطق
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildControlButton(
                                  icon: Icons.speed,
                                  label: 'بطيء',
                                  onPressed: !isProcessing
                                      ? () => changeSpeechRate(0.3)
                                      : null,
                                  color: speechRate <= 0.3
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 15),
                                _buildControlButton(
                                  icon: Icons.speed,
                                  label: 'متوسط',
                                  onPressed: !isProcessing
                                      ? () => changeSpeechRate(0.5)
                                      : null,
                                  color: speechRate > 0.3 && speechRate < 0.7
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 15),
                                _buildControlButton(
                                  icon: Icons.speed,
                                  label: 'سريع',
                                  onPressed: !isProcessing
                                      ? () => changeSpeechRate(0.7)
                                      : null,
                                  color: speechRate >= 0.7
                                      ? Colors.teal
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      ListenButtonWidget(
                        isProcessing: isProcessing,
                        onPressed: () {
                          if (currentWord != null) {
                            speak(currentWord!.text);
                          }
                        },
                        buttonText: 'استمع',
                        icon: Icons.volume_up,
                        iconColor: Colors.blue,
                        textColor: Colors.blue,
                        buttonColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      SizedBox(height: 20),
                      CheckButtonWidget(
                        isProcessing: isProcessing,
                        isButtonEnabled: assembledWord.isNotEmpty,
                        onPressed: _checkAnswer,
                        buttonText: 'تحقق',
                        icon: Icons.check,
                        buttonColor: Colors.green,
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      SizedBox(height: 20),
                      NavigationButtonsWidget(
                        hasPrevious: wordsProvider.hasPreviousWord(),
                        hasNext: wordsProvider.hasNextWord() &&
                            currentWord != null &&
                            wordsProvider.isWordCompleted(currentWord!),
                        onPreviousPressed: () {
                          wordsProvider.previousWord();
                          setState(() {
                            currentWord = wordsProvider.currentWord;
                            if (currentWord != null) {
                              _initializeShuffledLetters(currentWord!.text);
                            }
                          });
                        },
                        onNextPressed: () {
                          wordsProvider.nextWord();
                          setState(() {
                            currentWord = wordsProvider.currentWord;
                            if (currentWord != null) {
                              _initializeShuffledLetters(currentWord!.text);
                            }
                          });
                        },
                        previousButtonText: 'السابق',
                        nextButtonText: 'التالي',
                        previousIcon: Icons.arrow_back_ios,
                        nextIcon: Icons.arrow_forward_ios,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildControlButton(
                            icon: Icons.lightbulb_outline,
                            label: 'مساعدة',
                            onPressed: !isProcessing && !isHintMode
                                ? provideHint
                                : null,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 20),
                          _buildControlButton(
                            icon: Icons.volume_down,
                            label: 'بطيء',
                            onPressed: !isProcessing
                                ? () => changeSpeechRate(0.3)
                                : null,
                            color: speechRate <= 0.3
                                ? Colors.teal
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 20),
                          _buildControlButton(
                            icon: Icons.volume_up,
                            label: 'عادي',
                            onPressed: !isProcessing
                                ? () => changeSpeechRate(0.5)
                                : null,
                            color: speechRate > 0.3 && speechRate < 0.7
                                ? Colors.teal
                                : Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final isDisabled = onPressed == null;

    return Container(
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isDisabled ? Colors.grey : color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
