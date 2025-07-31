import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:teatcher_smarter/models_for_api/word_model.dart';
import 'package:teatcher_smarter/providers/word_progress_provider.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';
import 'dart:math';

import 'package:teatcher_smarter/widgets/result_dialog.dart';
import 'package:teatcher_smarter/custom_widgets/general_custom_widgets.dart';

class WordScreen extends StatefulWidget {
  final int level;

  const WordScreen({super.key, required this.level});

  @override
  _WordScreenState createState() => _WordScreenState();
}

class AssembledWordWidget extends StatelessWidget {
  final String assembledWord;
  final Color textColor;
  final double fontSize;
  final String placeholder;

  const AssembledWordWidget({
    super.key,
    required this.assembledWord,
    this.textColor = Colors.black,
    this.fontSize = 32,
    this.placeholder = '____',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        assembledWord.isEmpty ? placeholder : assembledWord,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class LetterWidget extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final Function() onTap;
  final Color selectedColor;
  final Color defaultColor;
  final double fontSize;

  const LetterWidget({
    super.key,
    required this.letter,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = Colors.grey,
    this.defaultColor = Colors.blue,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : defaultColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _WordScreenState extends State<WordScreen> {
  late WordsProvider wordsProvider;
  late WordProgressProvider wordProgressProvider;
  late FlutterTts flutterTts;
  WordModel? currentWord;
  List<Map<String, String>> shuffledLetters = [];
  String assembledWord = '';
  bool isProcessing = false;
  bool isWordModified = false;
  Set<Map<String, String>> selectedLettersSet = {};
  double speechRate = 0.5; 
  bool useLetterByLetterMode = false; 
  bool isHintMode = false; 
  int consecutiveCorrectAnswers = 0; 

  List<String> correctMessages = [
    "أحسنتَ!",
    "رائع!",
    "أنت الأفضل!",
    "عمل ممتاز!",
    "ممتاز!"
  ];

  List<String> incorrectMessages = [
    "لا تقلق، حاول مرة أخرى.",
    "لا بأس عليك، استمر في المحاولة.",
    "حاول مجددًا، أنت قادر!",
    "لا تيأس، جرب مرة أخرى.",
    "أنت على الطريق الصحيح!"
  ];

  @override
  void initState() {
    super.initState();
    wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    wordProgressProvider =
        Provider.of<WordProgressProvider>(context, listen: false);
    _initializeFlutterTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage();
      _initializeWords();
    });
  }

  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(speechRate);
    flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });
    await flutterTts.speak(text);
    await flutterTts.awaitSpeakCompletion(true);
    setState(() {
      isProcessing = false;
    });
  }

  
  Future<void> speakLetterByLetter(String word) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    // نطق الكلمة كاملة أولاً
    await flutterTts.speak("الكلمة هي $word");
    await flutterTts.awaitSpeakCompletion(true);

   
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak("استمع إلى الحروف");
    await flutterTts.awaitSpeakCompletion(true);

    // نطق كل حرف بشكل منفصل
    for (int i = 0; i < word.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      await flutterTts.speak("حرف ${word[i]}");
      await flutterTts.awaitSpeakCompletion(true);
    }

    
    await Future.delayed(const Duration(milliseconds: 500));
    await flutterTts.speak("الكلمة كاملة هي $word");
    await flutterTts.awaitSpeakCompletion(true);

    setState(() {
      isProcessing = false;
    });
  }


  Future<void> changeSpeechRate(double newRate) async {
    setState(() {
      speechRate = newRate;
    });
    await flutterTts.setSpeechRate(newRate);

 
    String speedMessage = newRate <= 0.3
        ? "تم ضبط سرعة النطق على بطيء"
        : newRate >= 0.7
            ? "تم ضبط سرعة النطق على سريع"
            : "تم ضبط سرعة النطق على متوسط";

    await speak(speedMessage);
  }

 
  Future<void> provideHint() async {
    if (currentWord == null) return;

    setState(() {
      isHintMode = true;
    });

  
    await speak("سأعطيك تلميحًا عن الكلمة");
    await Future.delayed(const Duration(milliseconds: 500));

    String currentWordText = currentWord!.text;

  
    if (currentWordText.isNotEmpty) {
      await speak("الكلمة تبدأ بحرف ${currentWordText[0]}");
    }

  
    await Future.delayed(const Duration(milliseconds: 700));
    await speak("عدد حروف الكلمة هو ${currentWordText.length}");

    setState(() {
      isHintMode = false;
    });
  }


  Future<void> playSuccessMotivation() async {
   
    consecutiveCorrectAnswers++;

    // اختيار رسالة تحفيزية بناءً على عدد الإجابات الصحيحة المتتالية
    String motivationalMessage;

    
    if (consecutiveCorrectAnswers >= 5) {
      motivationalMessage = "رائع جدًا! أنت عبقري في تركيب الكلمات!";
    }
    
    else if (consecutiveCorrectAnswers >= 3) {
      motivationalMessage = "ممتاز! أنت تتقدم بشكل رائع!";
    }
 
    else {
   
      List<String> messages = [
        "أحسنت!",
        "ممتاز! استمر هكذا!",
        "رائع! إجابة صحيحة!",
        "عمل جيد جدًا!",
        "أنت رائع في تركيب الكلمات!"
      ];
      // اختيار رسالة عشوائية من القائمة
      motivationalMessage = messages[Random().nextInt(messages.length)];
    }

 
    await speak(motivationalMessage);
  }

// دالة لنطق رسالة الترحيب بالمستوى
  void _speakWelcomeMessage() {
    String levelName = '';

    switch (widget.level) {
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
        'مرحباً بك في تركيب الكلمات في المستوى $levelName. اضغط على الحروف لتكوين الكلمة الصحيحة.');
  }


  Future<void> _initializeWords() async {

    WidgetsBinding.instance.addPostFrameCallback((_) async {
    
      await wordsProvider.loadLocalData();
      // مزامنة البيانات مع السيرفر
      await wordsProvider.fetchAndSyncData();
      // تصفية الكلمات حسب المستوى
      wordsProvider.filterByLevel(widget.level);

      // الحصول على آخر كلمة تم الوصول إليها
      final lastWordIndex =
          await wordProgressProvider.getLastAccessedWord(widget.level);
      if (lastWordIndex != null) {
      
        wordsProvider.setCurrentWordIndex(lastWordIndex);
      }

      // إذا كانت الواجهة نشطة
      if (mounted) {

        setState(() {
          currentWord = wordsProvider.currentWord;
          if (currentWord != null) {
          
            _initializeShuffledLetters(currentWord!.text);
            // نطق الكلمة حرفاً حرفاً أو كاملة
            if (useLetterByLetterMode) {
              speakLetterByLetter(currentWord!.text);
            } else {
              speak("قم بتركيب كلمة ${currentWord!.text}");
            }
          }
        });
      }
    });
  }


  void _initializeShuffledLetters(String word) {
    String trimmedWord = word.trim();
    if (trimmedWord.isNotEmpty) {
      setState(() {
        // تقسيم الكلمة إلى حروف وخلطها
        shuffledLetters = trimmedWord
            .split('')
            .map((letter) => {'letter': letter})
            .toList()
          ..shuffle();
       
        selectedLettersSet.clear();
        // مسح الكلمة المجمعة
        assembledWord = '';
      });
    }
  }

  void _toggleLetter(Map<String, String> letterMap) {
    setState(() {
      String letter = letterMap['letter']!;
      // إذا كان الحرف محدداً بالفعل
      if (selectedLettersSet.contains(letterMap)) {
        // إزالته من الحروف المحددة
        selectedLettersSet.remove(letterMap);
        // إزالته من الكلمة المجمعة
        int index = assembledWord.lastIndexOf(letter);
        if (index != -1) {
          assembledWord = assembledWord.substring(0, index) +
              assembledWord.substring(index + 1);
        }
      } else {
      
        selectedLettersSet.add(letterMap);
    
        assembledWord += letter;
      }
      // تحديث حالة تعديل الكلمة
      isWordModified = assembledWord.isNotEmpty;
    });
  }


  Future<void> _checkAnswer() async {
    if (assembledWord.isEmpty) return;

    setState(() {
      isProcessing = true;
    });

    if (currentWord != null) {
      String 
              trimmedAssembledWord = assembledWord.trim();
      // التحقق من مطابقة الكلمة المجمعة مع الكلمة الصحيحة
      bool isCorrect = trimmedAssembledWord == currentWord!.text.trim();

      if (isCorrect) {
       
        await wordProgressProvider.updateWordProgress(
          wordId: currentWord!.id,
          isCorrect: true,
          level: widget.level,
        );
      } else {
        // إعادة ضبط العداد عند الإجابة الخاطئة
        consecutiveCorrectAnswers = 0;
      }

      // عرض نافذة النتيجة
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ResultDialog(
          isCorrect: isCorrect,
          message: isCorrect
              ? correctMessages[Random().nextInt(correctMessages.length)]
              : incorrectMessages[Random().nextInt(incorrectMessages.length)],
          onClose: () {
            Navigator.of(context).pop();
            if (isCorrect) {
              // تمييز الكلمة كمكتملة
              wordsProvider.markWordAsCompleted(currentWord!);
              if (wordsProvider.hasNextWord()) {
          
                nextWord();
                // إخبار المستخدم بعدد الكلمات المتبقية إذا كانت قليلة
                if (wordsProvider.remainingWordsCount() <= 3) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    speak(
                        "بقي لديك ${wordsProvider.remainingWordsCount()} كلمات فقط!");
                  });
                }
              }
            } else {
              // إعادة تهيئة الحروف إذا كانت الإجابة خاطئة
              setState(() {
                assembledWord = '';
                selectedLettersSet.clear();
                _initializeShuffledLetters(currentWord!.text);
              });
            }
            setState(() {
              isProcessing = false;
              isWordModified = false;
            });
          },
        ),
      );
    }
  }


  void nextWord() async {
    if (currentWord != null) {
 
      await wordProgressProvider.updateWordProgress(
        wordId: currentWord!.id,
        isCorrect: false,
        level: widget.level,
      );

     
      wordsProvider.nextWord();
      setState(() {
        currentWord = wordsProvider.currentWord;
        if (currentWord != null) {
        
          _initializeShuffledLetters(currentWord!.text);
          // نطق الكلمة الجديدة
          if (useLetterByLetterMode) {
            speakLetterByLetter(currentWord!.text);
          } else {
            speak("قم بتركيب كلمة ${currentWord!.text}");
          }
        }
      });
    }
  }


  void previousWord() async {
    if (currentWord != null) {

      await wordProgressProvider.updateWordProgress(
        wordId: currentWord!.id,
        isCorrect: false,
        level: widget.level,
      );
   
      wordsProvider.previousWord();
      setState(() {
        currentWord = wordsProvider.currentWord;
        if (currentWord != null) {
      
          _initializeShuffledLetters(currentWord!.text);
        
          if (useLetterByLetterMode) {
            speakLetterByLetter(currentWord!.text);
          } else {
            speak("قم بتركيب كلمة ${currentWord!.text}");
          }
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<WordsProvider>(
      builder: (context, wordsProvider, child) {
        // إذا تغيرت الكلمة الحالية
        if (currentWord != wordsProvider.currentWord) {
          // تنفيذ الكود بعد اكتمال بناء الواجهة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                currentWord = wordsProvider.currentWord;
                if (currentWord != null) {
             
                  _initializeShuffledLetters(currentWord!.text);
                }
              });
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('تعلم الكلمات - المستوى ${widget.level}'),
            centerTitle: true,
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
                      InstructionTextWidget(
                        title: 'قم بتركيب الكلمة',
                        sentenceText: currentWord?.text ?? '',
                        titleColor: Colors.blue.shade900,
                        sentenceColor: Colors.grey.shade600,
                        titleFontSize: 20,
                        sentenceFontSize: 24,
                      ),
                      SizedBox(height: 16),
                      if (currentWord?.image.isNotEmpty ?? false)
                        Container(
                          height: 180,
                          width: double.infinity,
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
                      SizedBox(height: 20),
                      AssembledWordWidget(
                        assembledWord: assembledWord,
                        textColor: Colors.black87,
                        fontSize: 32,
                        placeholder: '____',
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
                                          ? () => speak(currentWord!.text)
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: shuffledLetters.map((letterMap) {
                          bool isSelected =
                              selectedLettersSet.contains(letterMap);
                          return LetterWidget(
                            letter: letterMap['letter']!,
                            isSelected: isSelected,
                            onTap: () => _toggleLetter(letterMap),
                            selectedColor: Colors.grey.shade400,
                            defaultColor: Colors.blue,
                            fontSize: 24,
                          );
                        }).toList(),
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
                        onPreviousPressed: previousWord,
                        onNextPressed: nextWord,
                        previousButtonText: 'السابق',
                        nextButtonText: 'التالي',
                        previousIcon: Icons.arrow_back_ios,
                        nextIcon: Icons.arrow_forward_ios,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 10),
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

  // دالة مساعدة لإنشاء أزرار التحكم
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final isDisabled = onPressed == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isDisabled ? Colors.grey.shade400 : color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey.shade400 : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
