import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import '../../models/number_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  @override
  _NumberScreenState createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
  late FlutterTts flutterTts;
  late stt.SpeechToText speech;
  bool isProcessing = false;
  double speechRate = 0.5;

  // Variables para el reconocimiento de voz
  bool isListening = false;
  String resultText = '';
  int remainingTime = 0;
  Timer? countdownTimer;
  String currentCorrectPronunciation = '';

  // Duración de la escucha en segundos
  final int listeningDuration = 10;

  // Contador de respuestas consecutivas correctas
  int consecutiveCorrectAnswers = 0;

  // Mostrar/ocultar consejos de pronunciación
  bool showPronunciationTip = true;

  // تشغيل الصوت تلقائيًا
  bool autoPlayEnabled = true;

  // تشغيل نصائح النطق بالصوت تلقائيًا
  bool autoPlayTips = false;

  // تفعيل الملاحظات الصوتية
  bool audioFeedbackEnabled = true;

  // ثابت لتخزين مفتاح الرقم الحالي في التخزين المشترك
  static const String _currentNumberIndexKey = 'current_number_index';

  // ثابت لتخزين مفتاح وضع تسهيل النطق في التخزين المشترك
  static const String _easyPronunciationModeKey =
      'easy_pronunciation_mode_number';

  // الملاحظات التحفيزية للإجابات الصحيحة
  List<String> correctMessages = [
    "أحسنت، النطق صحيح!",
    "رائع! لقد نطقت الرقم بشكل صحيح.",
    "ممتاز! استمر هكذا.",
    "إجابة صحيحة! أنت تتحسن.",
    "أحسنت! أداء ممتاز."
  ];

  // الملاحظات التحفيزية للإجابات الخاطئة
  List<String> incorrectMessages = [
    "النطق غير صحيح، حاول مرة أخرى.",
    "لم يكن صحيحاً، لكن استمر في المحاولة!",
    "حاول مرة أخرى، أنت تستطيع!",
    "لا تقلق، يمكنك المحاولة مرة أخرى.",
    "قريب، حاول مرة أخرى بتركيز أكثر."
  ];

  // مستوى الصعوبة في تقييم النطق (قيمة تتراوح بين 0.5 و 0.9)
  double pronunciationThreshold = 0.7;

  // خيار لتفعيل الوضع السهل للمستخدمين الذين يعانون من صعوبات في النطق
  bool easyPronunciationMode = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    speech = stt.SpeechToText();
    _initializeTts();

    // Inicializar variables para el reconocimiento de voz
    isListening = false;
    isProcessing = false;
    remainingTime = listeningDuration;
    resultText = '';
    consecutiveCorrectAnswers = 0;

    // استعادة التقدم المحفوظ
    _loadSavedProgress();

    // إضافة مستمع للحفظ التلقائي عند الخروج من الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تأخير قصير لضمان تحميل الواجهة بشكل كامل
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          // التشغيل التلقائي للرقم الحالي
          if (autoPlayEnabled) {
            _autoPlayCurrentNumber();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    // إلغاء المؤقتات
    countdownTimer?.cancel();
    super.dispose();
  }

  // استعادة التقدم المحفوظ
  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // استعادة مؤشر الرقم الحالي
      int? savedIndex = prefs.getInt(_currentNumberIndexKey);
      if (savedIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final numberModel = Provider.of<NumberModel>(context, listen: false);
          // تحديث مؤشر الرقم في النموذج
          numberModel.currentIndex = savedIndex;
        });
      }

      // استعادة وضع تسهيل النطق
      bool? savedEasyMode = prefs.getBool(_easyPronunciationModeKey);
      if (savedEasyMode != null) {
        setState(() {
          easyPronunciationMode = savedEasyMode;
        });
      }

      // استعادة إعدادات التشغيل التلقائي
      bool? savedAutoPlay = prefs.getBool('auto_play_number');
      if (savedAutoPlay != null) {
        setState(() {
          autoPlayEnabled = savedAutoPlay;
        });
      }

      bool? savedAutoPlayTips = prefs.getBool('auto_play_tips');
      if (savedAutoPlayTips != null) {
        setState(() {
          autoPlayTips = savedAutoPlayTips;
        });
      }

      bool? savedAudioFeedback = prefs.getBool('audio_feedback_enabled');
      if (savedAudioFeedback != null) {
        setState(() {
          audioFeedbackEnabled = savedAudioFeedback;
        });
      }
    } catch (e) {
      print('خطأ في استعادة التقدم: $e');
    }
  }

  // حفظ التقدم الحالي
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على الرقم الحالي من النموذج
      final numberModel = Provider.of<NumberModel>(context, listen: false);

      // حفظ مؤشر الرقم الحالي
      await prefs.setInt(_currentNumberIndexKey, numberModel.currentIndex);

      // حفظ وضع تسهيل النطق
      await prefs.setBool(_easyPronunciationModeKey, easyPronunciationMode);

      // حفظ إعدادات التشغيل التلقائي
      await prefs.setBool('auto_play_number', autoPlayEnabled);
      await prefs.setBool('auto_play_tips', autoPlayTips);

      await prefs.setBool('audio_feedback_enabled', audioFeedbackEnabled);

      print('تم حفظ التقدم بنجاح. الرقم الحالي: ${numberModel.currentIndex}');
    } catch (e) {
      print('خطأ في حفظ التقدم: $e');
    }
  }

  // تشغيل صوت الرقم الحالي تلقائياً
  void _autoPlayCurrentNumber() {
    if (isProcessing) return;

    final numberModel = Provider.of<NumberModel>(context, listen: false);
    speakNumberWithDetails(
        numberModel.currentNumber.toString(), numberModel.currentNumberName);

    // إذا كان تشغيل النصائح تلقائيًا مفعلاً
    if (autoPlayTips && showPronunciationTip) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted && !isProcessing) {
          speakPronunciationTip(numberModel.currentNumber.toString());
        }
      });
    }
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(speechRate);
  }

  // تشغيل صوت الرقم مع التفاصيل
  Future<void> speakNumberWithDetails(String number, String numberName) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await flutterTts.setSpeechRate(speechRate);
      await flutterTts.speak(numberName);

      // استخدام مؤقت لتتبع وقت النطق وتحديث الحالة
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isProcessing = false;
          });
        }
      });
    } catch (e) {
      print('خطأ في النطق: $e');
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  // الحصول على نصائح النطق للرقم
  String getNumberPronunciationTip(String number) {
    switch (number) {
      case '0':
        return "صفر: ينطق (صِفْر) مع مد خفيف لحرف الفاء. تأكد من إظهار السكون في نهاية الكلمة.";
      case '1':
        return "واحد: ينطق (وَاحِد) مع التركيز على حرف الحاء. انطق حرف الحاء من وسط الحلق وتأكد من إظهار الكسرة تحت الحاء.";
      case '2':
        return "اثنان: ينطق (اِثْنَان) مع التشديد على حرف الثاء. تأكد من وضع طرف اللسان بين الأسنان العليا والسفلى عند نطق حرف الثاء.";
      case '3':
        return "ثلاثة: ينطق (ثَلَاثَة) مع التركيز على نطق حرف الثاء بشكل صحيح. تذكر أن تمد حرف الألف قليلاً بعد اللام.";
      case '4':
        return "أربعة: ينطق (أَرْبَعَة) مع التركيز على إظهار حرف الراء بوضوح. تأكد من إظهار السكون على الراء والفتحة على الباء.";
      case '5':
        return "خمسة: ينطق (خَمْسَة) مع نطق حرف الخاء من الحلق. تأكد من إظهار السكون على الميم وعدم خلط الخاء بحرف الكاف أو الحاء.";
      case '6':
        return "ستة: ينطق (سِتَّة) مع تشديد حرف التاء. لاحظ أن هناك كسرة تحت السين وفتحة فوق التاء المشددة.";
      case '7':
        return "سبعة: ينطق (سَبْعَة) مع التركيز على حرف العين. تأكد من نطق حرف العين بوضوح من وسط الحلق مع إظهار السكون على الباء.";
      case '8':
        return "ثمانية: ينطق (ثَمَانِيَة) مع التركيز على نطق حرف الثاء بشكل صحيح. لاحظ أنها كلمة طويلة وتحتاج إلى مد الألف بعد الميم والياء بعد النون.";
      case '9':
        return "تسعة: ينطق (تِسْعَة) مع التركيز على حرف العين في نهاية الكلمة. تأكد من نطق حرف السين بوضوح مع إظهار السكون عليها.";

      default:
        if (int.parse(number) > 20 && int.parse(number) < 100) {
          // للأعداد بين 21 و 99
          int ones = int.parse(number) % 10;
          int tens = (int.parse(number) ~/ 10) * 10;

          if (ones > 0) {
            // إذا كان العدد مركبًا مثل 21، 35، إلخ
            String onesName = getArabicNumberName(ones.toString());
            String tensName = getArabicNumberName(tens.toString());
            return "$onesName و$tensName: ينطق بوضوح مع فاصل قصير بين العدد الأول وواو العطف. تأكد من إظهار حركات الإعراب الصحيحة لكل جزء.";
          } else {
            // إذا كان العدد عقدًا مثل 20، 30، إلخ
            return getNumberPronunciationTip(tens.toString());
          }
        } else if (int.parse(number) > 100) {
          return "عند نطق الأعداد الكبيرة، قم بتقسيم العدد إلى مجموعات وانطق كل مجموعة بشكل منفصل مع الانتباه إلى ربط المجموعات بواو العطف عند الضرورة.";
        }

        return "لنطق هذا الرقم، قسّمه إلى أجزاء واضحة وانطق كل جزء بالتدريج مع التركيز على مخارج الحروف وحركات التشكيل.";
    }
  }

  // الحصول على اسم العدد بالعربية
  String getArabicNumberName(String number) {
    switch (number) {
      case '0':
        return "صفر";
      case '1':
        return "واحد";
      case '2':
        return "اثنان";
      case '3':
        return "ثلاثة";
      case '4':
        return "أربعة";
      case '5':
        return "خمسة";
      case '6':
        return "ستة";
      case '7':
        return "سبعة";
      case '8':
        return "ثمانية";
      case '9':
        return "تسعة";

      default:
        return "العدد $number";
    }
  }

  // تشغيل نصائح النطق بالصوت
  Future<void> speakPronunciationTip(String number) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // تعيين سرعة مناسبة للنصائح
      await flutterTts.setSpeechRate(0.4);

      // نطق نصيحة النطق
      String tip = getNumberPronunciationTip(number);
      await flutterTts.speak(tip);

      // إعادة ضبط سرعة النطق الأصلية بعد الانتهاء
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            isProcessing = false;
          });
          _initializeTts();
        }
      });
    } catch (e) {
      print('خطأ في نطق النصيحة: $e');
      setState(() {
        isProcessing = false;
      });
    }
  }

  // بدء الاستماع
  void startListening(String correctPronunciation) async {
    if (speech.isListening) {
      await speech.stop();
      setState(() => isListening = false);
    }

    bool available = await speech.initialize(
      onStatus: (status) {
        print('Status: $status');
        if (status == 'done' && isListening) {
          setState(() {
            isListening = false;
            if (countdownTimer != null) {
              countdownTimer!.cancel();
              countdownTimer = null;
            }
          });
        }
      },
      onError: (error) {
        print('Error: $error');
        setState(() {
          isListening = false;
          if (countdownTimer != null) {
            countdownTimer!.cancel();
            countdownTimer = null;
          }
        });

        // عرض رسالة الخطأ
        String errorMessage = 'حدث خطأ أثناء التعرف على الكلام. حاول مرة أخرى.';
        _showRecognitionErrorDialog(errorMessage);
      },
    );

    if (available) {
      setState(() {
        isListening = true;
        resultText = '';
        remainingTime = listeningDuration;
        currentCorrectPronunciation = correctPronunciation;
      });

      await speech.listen(
        onResult: (result) {
          setState(() {
            resultText = result.recognizedWords;
            if (result.finalResult) {
              isListening = false;
              comparePronunciation(correctPronunciation);
              if (countdownTimer != null) {
                countdownTimer!.cancel();
                countdownTimer = null;
              }
            }
          });
        },
        listenFor: Duration(seconds: listeningDuration),
        localeId: "ar_SA",
        cancelOnError: true,
      );

      // ابدأ عداد تنازلي
      countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            remainingTime--;
            if (remainingTime <= 0) {
              timer.cancel();
              countdownTimer = null;
              if (isListening) {
                speech.stop();
                isListening = false;
                // إذا لم يتم التعرف على أي نص، قارن مع نص فارغ
                if (resultText.isEmpty) {
                  _showNoSpeechDetectedDialog();
                } else {
                  comparePronunciation(correctPronunciation);
                }
              }
            }
          });
        }
      });
    } else {
      print('لم يتم تهيئة الخدمة بنجاح.');
      _showRecognitionErrorDialog(
          'لم نتمكن من تهيئة خدمة التعرف على الكلام. تأكد من اتصالك بالإنترنت.');
    }
  }

  // Comparar la pronunciación con la respuesta correcta
  void comparePronunciation(String correctPronunciation) async {
    String normalizedResult = resultText.trim().toLowerCase();
    String normalizedCorrect = correctPronunciation.trim().toLowerCase();

    bool isCorrect = false;

    // Comprobar si la respuesta es correcta
    if (normalizedResult == normalizedCorrect) {
      isCorrect = true;
    } else if (normalizedResult.contains(normalizedCorrect)) {
      isCorrect = true;
    } else if (normalizedCorrect.contains(normalizedResult)) {
      isCorrect = true;
    }

    // Si la respuesta es correcta
    if (isCorrect) {
      consecutiveCorrectAnswers++;

      // Seleccionar un mensaje aleatorio
      final random = Random();
      String message = correctMessages[random.nextInt(correctMessages.length)];

      // Mensaje especial para respuestas consecutivas correctas
      if (consecutiveCorrectAnswers >= 3) {
        message =
            "رائع جداً! لقد أجبت بشكل صحيح $consecutiveCorrectAnswers مرات متتالية!";
      }

      // Reproducir sonido de éxito
      if (audioFeedbackEnabled) {
        playSuccessSound();
      }

      // Mostrar diálogo de éxito
      _showSuccessDialog(message);

      // Reproducir mensaje motivacional después de mostrar el diálogo
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted && audioFeedbackEnabled) {
          speakMotivationalMessage(message);
        }
      });

      // Guardar el progreso
      _saveProgress();
    } else {
      // Reiniciar el contador de respuestas consecutivas correctas
      consecutiveCorrectAnswers = 0;

      // Seleccionar un mensaje aleatorio
      final random = Random();
      String message =
          incorrectMessages[random.nextInt(incorrectMessages.length)];

      // Reproducir sonido de "inténtalo de nuevo"
      if (audioFeedbackEnabled) {
        playTryAgainSound();
      }

      // Mostrar diálogo de error
      _showErrorDialog(message, correctPronunciation);

      // Reproducir mensaje después de mostrar el diálogo
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted && audioFeedbackEnabled) {
          speakMotivationalMessage(message);
        }
      });
    }
  }

  // Mostrar diálogo de éxito
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.shade100,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text(
              'إجابة صحيحة!',
              style: TextStyle(color: Colors.green.shade800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            // Añadir un indicador visual para el audio
            if (audioFeedbackEnabled)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: Colors.green.shade800, size: 18),
                  SizedBox(width: 5),
                  Text(
                    'جاري النطق...',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('استمرار'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Mostrar diálogo de error
  void _showErrorDialog(String message, String correctPronunciation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text(
              'حاول مرة أخرى',
              style: TextStyle(color: Colors.red.shade800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'النطق الصحيح هو: $correctPronunciation',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            // Añadir un indicador visual para el audio
            if (audioFeedbackEnabled)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: Colors.red.shade800, size: 18),
                  SizedBox(width: 5),
                  Text(
                    'جاري النطق...',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              speakNumberWithDetails(
                Provider.of<NumberModel>(context, listen: false)
                    .currentNumber
                    .toString(),
                correctPronunciation,
              );
            },
            child: Text('استمع للنطق الصحيح',
                style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // Widget para construir botones de velocidad
  Widget _buildSpeedButton(String label, double rate,
      [bool isSelected = false]) {
    return GestureDetector(
      onTap: () {
        setState(() {
          speechRate = rate;
        });
        _initializeTts();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade800 : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // تشغيل رسالة تحفيزية بالصوت
  Future<void> speakMotivationalMessage(String message) async {
    if (!audioFeedbackEnabled) return;

    try {
      // حفظ السرعة الحالية
      double currentRate = speechRate;

      // ضبط سرعة مناسبة للرسائل التحفيزية
      await flutterTts.setSpeechRate(0.45);

      // نطق الرسالة
      await flutterTts.speak(message);

      // إعادة السرعة السابقة
      await flutterTts.setSpeechRate(currentRate);
    } catch (e) {
      print('خطأ في نطق الرسالة التحفيزية: $e');
    }
  }

  // تشغيل صوت النجاح
  Future<void> playSuccessSound() async {
    if (!audioFeedbackEnabled) return;

    try {
      // يمكن استخدام صوت قصير أو كلمة تحفيزية
      await flutterTts.speak("أحسنت!");
    } catch (e) {
      print('خطأ في تشغيل صوت النجاح: $e');
    }
  }

  // تشغيل صوت التشجيع للمحاولة مرة أخرى
  Future<void> playTryAgainSound() async {
    if (!audioFeedbackEnabled) return;

    try {
      // صوت تشجيعي قصير
      await flutterTts.speak("حاول مرة أخرى!");
    } catch (e) {
      print('خطأ في تشغيل صوت التشجيع: $e');
    }
  }

  // عرض ديالوج خطأ في التعرف على الكلام
  void _showRecognitionErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic_off, color: Colors.red),
            SizedBox(width: 10),
            Text('تعذر التعرف على الكلام'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage),
            SizedBox(height: 10),
            Text(
              'تأكد من أن الميكروفون يعمل بشكل صحيح وأنك تتحدث بوضوح.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startListening(currentCorrectPronunciation);
            },
            child: Text('إعادة المحاولة', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // عرض ديالوج عندما لا يتم اكتشاف صوت
  void _showNoSpeechDetectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic_none, color: Colors.orange),
            SizedBox(width: 10),
            Text('لم نسمع أي شيء'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('لم نتمكن من سماع صوتك. يرجى التحدث بصوت أعلى قليلاً.'),
            SizedBox(height: 10),
            Text(
              'تأكد من أن الميكروفون يعمل بشكل صحيح وأنك في مكان هادئ.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startListening(currentCorrectPronunciation);
            },
            child: Text('إعادة المحاولة', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberModel = Provider.of<NumberModel>(context);

    // الحصول على عرض وارتفاع الشاشة
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double fontSize = screenWidth * 0.06;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'نطق الأرقام',
        onBackPressed: () {
          // حفظ التقدم قبل الخروج
          _saveProgress();
          Navigator.pop(context);
        },
        icon_theme: Colors.orange,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.02),
                child: Container(
                  width: screenWidth * 0.8,
                  alignment: Alignment.center,
                  child: Text(
                    numberModel.currentNumber.toString(),
                    style: TextStyle(
                      fontSize: fontSize + 60,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // إضافة زر لإظهار نصائح النطق
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'نصائح النطق:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: showPronunciationTip,
                    onChanged: (value) {
                      setState(() {
                        showPronunciationTip = value;
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),

              // نصائح النطق (تظهر فقط عند تفعيل الخيار)
              if (showPronunciationTip)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            getNumberPronunciationTip(
                                numberModel.currentNumber.toString()),
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // زر تشغيل نصائح النطق بالصوت
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: isProcessing
                                ? null
                                : () {
                                    speakPronunciationTip(
                                        numberModel.currentNumber.toString());
                                  },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isProcessing
                                    ? Colors.grey.shade400
                                    : Colors.orange.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isProcessing
                                        ? Icons.graphic_eq
                                        : Icons.volume_up,
                                    color: Colors.white,
                                    size: isProcessing ? 30 : 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    isProcessing
                                        ? 'جاري النطق...'
                                        : 'استمع للنصيحة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.03),

              // أزرار ضبط سرعة النطق
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSpeedButton('بطيء', 0.3, speechRate <= 0.3),
                  SizedBox(width: 10),
                  _buildSpeedButton(
                      'متوسط', 0.5, speechRate > 0.3 && speechRate < 0.7),
                  SizedBox(width: 10),
                  _buildSpeedButton('سريع', 0.7, speechRate >= 0.7),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // خيارات التشغيل التلقائي
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'نطق الرقم تلقائيًا:',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      Switch(
                        value: autoPlayEnabled,
                        onChanged: (value) {
                          setState(() {
                            autoPlayEnabled = value;
                          });
                          _saveProgress();
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                  Column(
                    children: [
                      Text(
                        'نطق النصائح تلقائيًا:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Switch(
                        value: autoPlayTips,
                        onChanged: (value) {
                          setState(() {
                            autoPlayTips = value;
                          });
                          _saveProgress();
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                  Column(
                    children: [
                      Text(
                        'التعليقات الصوتية:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Switch(
                        value: audioFeedbackEnabled,
                        onChanged: (value) {
                          setState(() {
                            audioFeedbackEnabled = value;
                          });
                          _saveProgress();
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.03),

              // زر الاستماع للرقم - تصميم محسن
              Container(
                width: screenWidth * 0.7,
                height: screenHeight * 0.08,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isProcessing
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isProcessing
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.blue.withOpacity(0.5),
                      offset: Offset(0, 4),
                      blurRadius: 5.0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isProcessing
                        ? null
                        : () async {
                            speakNumberWithDetails(
                              numberModel.currentNumber.toString(),
                              numberModel.currentNumberName,
                            );
                          },
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.white24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // أيقونة متحركة عند النطق
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: isProcessing ? 48 : 40,
                            height: isProcessing ? 48 : 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isProcessing
                                    ? Icons.graphic_eq
                                    : Icons.volume_up,
                                color: Colors.white,
                                size: isProcessing ? 30 : 24,
                              ),
                            ),
                          ),

                          // نص الزر
                          Text(
                            isProcessing ? 'جاري النطق...' : 'استمع للرقم',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          // مؤشر بصري للحالة
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isProcessing
                                  ? Colors.orange
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // زر التسجيل - تصميم محسن
              Stack(
                alignment: Alignment.center,
                children: [
                  // الدائرة الخارجية المتحركة
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width:
                        isListening ? screenWidth * 0.36 : screenWidth * 0.32,
                    height:
                        isListening ? screenWidth * 0.36 : screenWidth * 0.32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? Colors.red.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.1),
                    ),
                  ),

                  // الدائرة الداخلية للزر
                  GestureDetector(
                    onTap: () async {
                      var status = await Permission.microphone.status;
                      if (!status.isGranted) {
                        await Permission.microphone.request();
                        status = await Permission.microphone.status;
                        if (!status.isGranted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '⚠️ يتطلب التطبيق إذن الوصول إلى الميكروفون')),
                          );
                          return;
                        }
                      }
                      startListening(numberModel.currentNumberName);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width:
                          isListening ? screenWidth * 0.26 : screenWidth * 0.24,
                      height:
                          isListening ? screenWidth * 0.26 : screenWidth * 0.24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isListening
                              ? [Colors.red.shade400, Colors.red.shade700]
                              : [
                                  Colors.orange.shade300,
                                  Colors.orange.shade600
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isListening
                                ? Colors.red.withOpacity(0.5)
                                : Colors.orange.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // أيقونة الميكروفون مع تأثير متحرك
                          Icon(
                            isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: isListening ? 40 : 36,
                          ),
                          // عرض العد التنازلي إذا كان الاستماع نشطاً
                          isListening
                              ? Text(
                                  '$remainingTime',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  'انطق الرقم',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // عرض النص المنطوق
              if (resultText.isNotEmpty && isListening)
                Container(
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),

              SizedBox(height: screenHeight * 0.05),

              // تنسيق أزرار التنقل بين الأرقام
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // زر التالي
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          offset: Offset(0, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          numberModel.nextNumber();
                          // Actualizar el progreso
                          _saveProgress();
                          // Reproducir automáticamente el siguiente número
                          Future.delayed(Duration(milliseconds: 500), () {
                            if (autoPlayEnabled) {
                              _autoPlayCurrentNumber();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.015,
                            horizontal: screenWidth * 0.08,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back_ios, size: 16),
                              SizedBox(width: 5),
                              Text(
                                "التالي",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: screenWidth * 0.05),

                  // زر السابق
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          offset: Offset(0, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          numberModel.previousNumber();
                          // Actualizar el progreso
                          _saveProgress();
                          // Reproducir automáticamente el número anterior
                          Future.delayed(Duration(milliseconds: 500), () {
                            if (autoPlayEnabled) {
                              _autoPlayCurrentNumber();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.015,
                            horizontal: screenWidth * 0.08,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "السابق",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Widget para mostrar el estado de escucha
              if (isListening)
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            color: Colors.blue,
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'جاري الاستماع...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'الوقت المتبقي: $remainingTime ثانية',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: remainingTime / listeningDuration,
                        backgroundColor: Colors.blue.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      if (resultText.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 15),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'ما سمعناه:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                resultText,
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
