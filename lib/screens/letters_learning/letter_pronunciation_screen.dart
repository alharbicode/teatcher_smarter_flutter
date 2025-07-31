import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/letter_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Letterpronunciationscreen extends StatefulWidget {
  const Letterpronunciationscreen({super.key});

  @override
  _LetterpronunciationscreenState createState() =>
      _LetterpronunciationscreenState();
}

class _LetterpronunciationscreenState extends State<Letterpronunciationscreen> {
  late FlutterTts flutterTts;
  late stt.SpeechToText speech;
  bool isListening = false;
  String resultText = '';
  double speechRate = 0.5;
  int consecutiveCorrectAnswers = 0; // عدد الإجابات الصحيحة المتتالية
  bool isProcessing = false; 

  
  static const String _currentLetterIndexKey = 'current_letter_index';


  static const String _easyPronunciationModeKey = 'easy_pronunciation_mode';

  List<String> correctMessages = [
    "أحسنت، النطق صحيح!",
    "رائع! لقد نطقت الحرف بشكل صحيح.",
    "ممتاز! استمر هكذا.",
    "إجابة صحيحة! أنت تتحسن.",
    "أحسنت! أداء ممتاز."
  ];


  List<String> incorrectMessages = [
    "النطق غير صحيح، حاول مرة أخرى.",
    "لم يكن صحيحاً، لكن استمر في المحاولة!",
    "حاول مرة أخرى، أنت تستطيع!",
    "لا تقلق، يمكنك المحاولة مرة أخرى.",
    "قريب، حاول مرة أخرى بتركيز أكثر."
  ];


  bool showPronunciationTip = false;


  String currentCorrectPronunciation = '';

  // مستوى الصعوبة في تقييم النطق (قيمة تتراوح بين 0.5 و 0.9)
  double pronunciationThreshold = 0.7;


  bool easyPronunciationMode = false;


  int listeningDuration = 5;

  int remainingTime = 0;
  // مؤقت للعد التنازلي
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    speech = stt.SpeechToText();
    _initializeTts();


    _loadSavedProgress();

 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تأخير قصير لضمان تحميل الواجهة بشكل كامل
      Future.delayed(Duration(milliseconds: 500), () {
      
        _autoPlayCurrentLetter();
      });
    });
  }

  @override
  void dispose() {

    countdownTimer?.cancel();
    super.dispose();
  }

 
  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

  
      int? savedIndex = prefs.getInt(_currentLetterIndexKey);
      if (savedIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final letterModel = Provider.of<LetterModel1>(context, listen: false);
          // تحديث مؤشر الحرف في النموذج
          letterModel.currentIndex = savedIndex;
        });
      }

  
      bool? savedEasyMode = prefs.getBool(_easyPronunciationModeKey);
      if (savedEasyMode != null) {
        setState(() {
          easyPronunciationMode = savedEasyMode;
        });
      }
    } catch (e) {
      print('خطأ في استعادة التقدم: $e');
    }
  }


  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // الحصول على الحرف الحالي من النموذج
      final letterModel = Provider.of<LetterModel1>(context, listen: false);

      // حفظ مؤشر الحرف الحالي
      await prefs.setInt(_currentLetterIndexKey, letterModel.currentIndex);

      
      await prefs.setBool(_easyPronunciationModeKey, easyPronunciationMode);

      print('تم حفظ التقدم بنجاح. الحرف الحالي: ${letterModel.currentIndex}');
    } catch (e) {
      print('خطأ في حفظ التقدم: $e');
    }
  }


  void _autoPlayCurrentLetter() {
    if (isProcessing) return;

    final letterModel = Provider.of<LetterModel1>(context, listen: false);
    String currentLetter = letterModel.currentLetter;
    String currentLetterName = letterModel.currentLetterName;

    speakLetterWithPhonetics(currentLetter, currentLetterName);
  }

 
  void _moveToNextLetterAndPlay() {
    final letterModel = Provider.of<LetterModel1>(context, listen: false);

    // التحقق من أن هناك حرف تالي
    if (letterModel.currentIndex < letterModel.arabicLetters.length - 1) {
   
      letterModel.nextLetter();


      _saveProgress();

      Future.delayed(Duration(milliseconds: 800), () {
        _autoPlayCurrentLetter();
      });
    } else {

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('🎉 أحسنت!'),
          content: Text('لقد أكملت جميع الحروف بنجاح! هل تريد البدء من جديد؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('العودة'),
            ),
            TextButton(
              onPressed: () {
                // إعادة تعيين المؤشر إلى الحرف الأول
                letterModel.currentIndex = 0;
                Navigator.of(context).pop();

               
                _saveProgress();

                // تشغيل صوت الحرف الأول
                _autoPlayCurrentLetter();
              },
              child: Text('بدء من جديد'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _initializeTts() async {
    String language = "ar-YE";
    await flutterTts.setLanguage(language);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(speechRate);
  }

  Future<void> speakText(String text) async {
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

 
  Future<void> changeSpeechRate(double rate) async {
    setState(() {
      speechRate = rate;
    });

    await flutterTts.setSpeechRate(rate);

   
    String speedMessage;
    if (rate <= 0.3) {
      speedMessage = "سرعة نطق بطيئة";
    } else if (rate >= 0.7) {
      speedMessage = "سرعة نطق سريعة";
    } else {
      speedMessage = "سرعة نطق متوسطة";
    }

    await speakText(speedMessage);
  }

  Future<void> speakLetterWithPhonetics(
      String letter, String letterName) async {
    if (isProcessing) return;

    
    if (!await _checkInternetConnection()) {
      _showNoInternetDialog();
      return;
    }

    setState(() {
      isProcessing = true;
    });

    // نطق الحرف
    await flutterTts.speak(letter);
    await Future.delayed(const Duration(milliseconds: 800));

    // نطق اسم الحرف
    await flutterTts.speak("حرف $letterName");
    await Future.delayed(const Duration(milliseconds: 800));

  
    if (showPronunciationTip) {
      String phonetics = getPhoneticTip(letter);
      if (phonetics.isNotEmpty) {
        await flutterTts.speak(phonetics);
      }
    }

    setState(() {
      isProcessing = false;
    });
  }


  String getPhoneticTip(String letter) {
    Map<String, String> phoneticTips = {
      'أ': 'ينطق من الحنجرة مع فتح الفم',
      'ب': 'ينطق بإطباق الشفتين ثم فتحهما',
      'ت': 'ينطق بوضع طرف اللسان على أصول الثنايا العليا',
      'ث': 'ينطق بوضع طرف اللسان بين الأسنان',
      'ج': 'ينطق بوضع وسط اللسان مع سقف الحنك الصلب',
      'ح': 'ينطق بتضييق الحلق مع إخراج الهواء',
      'خ': 'ينطق من الحلق مع رفع مؤخرة اللسان',

    };

    return phoneticTips[letter] ?? '';
  }

  void startListening(String correctPronunciation) async {
    // تخزين النطق الصحيح للاستخدام في الدوال الأخرى
    currentCorrectPronunciation = correctPronunciation;

    // التحقق مما إذا كان النظام يستمع حالياً وإيقافه إذا كان كذلك
    if (speech.isListening) {
      await speech.stop();
      setState(() => isListening = false);
      countdownTimer?.cancel();
    }

    try {
      // تهيئة نظام التعرف على الكلام مع معالجات للأحداث
      bool available = await speech.initialize(
        onStatus: (val) {
       
          print('Speech recognition status: $val');
          // إذا توقف النظام عن الاستماع، تحديث الواجهة وإلغاء المؤقت
          if (val == 'notListening') {
            setState(() => isListening = false);
            countdownTimer?.cancel();
          }
        },
        onError: (val) {
      
          print('Speech recognition error: ${val.errorMsg}');
          setState(() => isListening = false);
          countdownTimer?.cancel();

          // تحديد رسالة الخطأ المناسبة بناءً على نوع الخطأ
          String errorMessage;
          if (val.errorMsg.contains('network')) {
            errorMessage =
                'تعذر الاتصال بالشبكة. تأكد من وجود اتصال بالإنترنت.';
          } else if (val.errorMsg.contains('permission')) {
            errorMessage = 'تحتاج للسماح باستخدام الميكروفون.';
          } else {
            errorMessage = 'حدث خطأ. يرجى المحاولة مرة أخرى.';
          }

          // عرض رسالة الخطأ في حوار
          _showRecognitionErrorDialog(errorMessage);
        },
      );

      // إذا كان النظام متاحاً للاستماع
      if (available) {
        // تحديث حالة الواجهة للبدء في الاستماع
        setState(() {
          isListening = true;
          resultText = '';
          remainingTime = listeningDuration;
          isProcessing = true;
        });

        // تشغيل تنبيه صوتي للإشارة إلى بدء الاستماع
        await flutterTts.speak("جاري الاستماع");

        // الانتظار قليلاً لإنهاء التنبيه الصوتي
        await Future.delayed(Duration(milliseconds: 800));

   
        setState(() {
          isProcessing = false;
        });

    
        countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            if (remainingTime > 0) {
              remainingTime--;
            } else {
              timer.cancel();
              if (speech.isListening) {
                speech.stop();
                setState(() => isListening = false);

                // إذا لم يتم التعرف على أي كلام، عرض رسالة
                if (resultText.isEmpty) {
                  _showNoSpeechDetectedDialog();
                }
              }
            }
          });
        });

        speech.listen(
          onResult: (val) {
            setState(() {
              resultText = val.recognizedWords;
            });

            // إذا كانت النتيجة النهائية للتعرف على الكلام
            if (val.finalResult) {
              speech.stop();
              countdownTimer?.cancel();

              setState(() => isListening = false);

              // التحقق من وجود نص معترف به ومقارنته بالنطق الصحيح
              if (resultText.isEmpty) {
                _showNoSpeechDetectedDialog();
              } else {
                comparePronunciation(correctPronunciation);
              }
            }
          },
          localeId: 'ar-YE', 
          listenFor: Duration(seconds: listeningDuration), // مدة الاستماع
          pauseFor:
              Duration(seconds: 2), // مدة التوقف قبل اعتبار الكلام منتهياً
        );
      } else {
     
        _showRecognitionErrorDialog(
            'لم نتمكن من تهيئة ميزة التعرف على الكلام. تأكد من اتصالك بالإنترنت.');
      }
    } catch (e) {

      print('Exception during speech recognition: $e');
      setState(() => isListening = false);
      countdownTimer?.cancel();
      _showRecognitionErrorDialog(
          'حدث خطأ غير متوقع. يرجى إعادة المحاولة لاحقاً.');
    }
  }


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
            Text(errorMessage), // رسالة الخطأ الرئيسية
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

  void comparePronunciation(String correctPronunciation) async {
    // تقوم بتطبيع النص المدخل (إزالة المسافات الزائدة وتحويله لحروف صغيرة)
    String normalizedResult = resultText.trim().toLowerCase();
    
    String normalizedCorrect = correctPronunciation.trim().toLowerCase();
    // حساب نسبة التشابه بين النطقين
    double similarity =
        StringSimilarity.compareTwoStrings(normalizedResult, normalizedCorrect);

    print(
        'النطق المتوقع: $normalizedCorrect، النطق الفعلي: $normalizedResult، نسبة التشابه: $similarity');

    // ضبط عتبة القبول بناءً على وضع التسهيل
    double threshold = easyPronunciationMode
        ? pronunciationThreshold - 0.2 // تخفيض العتبة في الوضع السهل
        : pronunciationThreshold; 

    // تحديد ما إذا كانت الإجابة صحيحة وإعداد رسالة التغذية الراجعة
    bool isCorrect = similarity > threshold;
    String feedbackMessage;

    
    if (isCorrect) {
      consecutiveCorrectAnswers++;
      // اختيار رسالة تشجيع عشوائية
      feedbackMessage = (correctMessages..shuffle()).first;

    
      if (consecutiveCorrectAnswers >= 3) {
        feedbackMessage +=
            " لديك ${consecutiveCorrectAnswers} إجابات صحيحة متتالية!";
      }
    } else {
     
      if (similarity > threshold - 0.2) {
        feedbackMessage =
            "قريب جداً من النطق الصحيح! حاول مرة أخرى مع التركيز على مخرج الحرف.";
        // نطق الملاحظة للمستخدم
        await speakText(feedbackMessage);

        // إعطاء فرصة أخرى فورية دون عقوبة
        startListening(correctPronunciation);
        return; // الخروج من الدالة هنا لتجنب التنفيذ المتبقي
      }

      // إعادة تعيين العداد عند الخطأ
      consecutiveCorrectAnswers = 0;
      // اختيار رسالة تصحيح عشوائية
      feedbackMessage = (incorrectMessages..shuffle()).first;
    }

    
    await speakText(feedbackMessage);

   
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isCorrect ? '✅ النطق صحيح' : '❌ النطق غير صحيح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // عرض الرسالة الرئيسية
            Text(
              feedbackMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
           
            Text(
              isCorrect
                  ? "رائع! لقد نطقت الحرف بشكل صحيح."
                  : "لا تقلق، استمع إلى الحرف مرة أخرى وحاول مجدداً.",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),

            // إضافة خيار تفعيل الوضع السهل فقط عند الخطأ
            if (!isCorrect)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // خانة اختيار الوضع السهل
                  Checkbox(
                    value: easyPronunciationMode,
                    onChanged: (value) {
                     
                      Navigator.of(context).pop();
                      setState(() {
                        easyPronunciationMode = value ?? false;
                      });

                 
                      _saveProgress();

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(easyPronunciationMode
                              ? '✓ تم تفعيل الوضع السهل'
                              : '✕ تم إلغاء الوضع السهل'),
                          content: Text(easyPronunciationMode
                              ? 'سيكون التقييم الآن أكثر مرونة مع اختلافات النطق.'
                              : 'سيتم استخدام التقييم العادي للنطق.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('حسناً'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 5),
                  Text(
                    'تفعيل وضع المساعدة في النطق',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
          ],
        ),
        // أزرار الحوار
        actions: [
          if (!isCorrect)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startListening(correctPronunciation);
              },
              child: Text('حاول مرة أخرى'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

        
              if (isCorrect) {
                _moveToNextLetterAndPlay();
              }
            },
            child: Text('حسناً'),
          ),
        ],
      ),
    );

    // إعادة تعيين حقل النص بعد الانتهاء
    setState(() {
      resultText = '';
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
   
      final result = await InternetAddress.lookup('google.com');
      // إذا وجدنا عنوان IP يعتبر الاتصال متاحاً
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
  
      return false;
    }
  }


  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.signal_wifi_off, color: Colors.red),
            SizedBox(width: 10),
            Text('لا يوجد اتصال بالإنترنت'), // ع
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'تعذر نطق الحرف بسبب عدم وجود اتصال بالإنترنت.'), // ر
            SizedBox(height: 10),
            Text(
              'يتطلب نطق الحروف اتصالاً بالإنترنت، يرجى التحقق من اتصالك والمحاولة مرة أخرى.',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[600]), 
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على بيانات الحرف الحالي من Provider
    final letterModel = Provider.of<LetterModel1>(context);

    // حساب أبعاد الشاشة لتكيف الواجهة
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double fontSize = screenWidth * 0.2; // حجم الخط يتناسب مع عرض الشاشة

    return Scaffold(
      appBar: AppBar( //
        title: Text('نطق الأحرف', style: TextStyle(color: Colors.orange)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.orange),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward, color: Colors.orange),
            onPressed: () {
              Navigator.pop(context); 
            },
          ),
        ],
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
                    letterModel.currentLetter,
                    style: TextStyle(
                      fontSize: fontSize + 60, // حجم كبير للحرف
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

        
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
                        showPronunciationTip = value; // تحديث حالة التبديل
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),

              // عرض نصائح النطق عند التفعيل
              if (showPronunciationTip)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        getPhoneticTip(letterModel.currentLetter).isNotEmpty
                            ? getPhoneticTip(letterModel.currentLetter)
                            : 'لا توجد نصائح محددة لهذا الحرف',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: screenHeight * 0.03),

          
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

              SizedBox(height: screenHeight * 0.03),

              // زر الاستماع للحرف
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
                            speakLetterWithPhonetics(
                              letterModel.currentLetter,
                              letterModel.currentLetterName,
                            );
                          },
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.white24,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                       
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

                          Text(
                            isProcessing ? 'جاري النطق...' : 'استمع للحرف',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          // مؤشر حالة
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

              // زر تسجيل النطق
              Stack(
                alignment: Alignment.center,
                children: [
                  // تأثيرات بصرية عند التسجيل
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
                          : Colors.blue.withOpacity(0.1),
                    ),
                  ),

                  // الزر الرئيسي
                  Container(
                    width: screenWidth * 0.28,
                    height: screenWidth * 0.28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isListening
                            ? [Colors.red.shade400, Colors.red.shade700]
                            : [Colors.blue.shade400, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isListening
                              ? Colors.red.withOpacity(0.5)
                              : Colors.blue.withOpacity(0.5),
                          offset: Offset(0, 4),
                          blurRadius: 8.0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: CircleBorder(),
                      child: InkWell(
                        onTap: isProcessing || isListening
                            ? null
                            : () async {
                                // طلب إذن الميكروفون
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
                                startListening(letterModel.currentLetterName);
                              },
                        customBorder: CircleBorder(),
                        splashColor: Colors.white24,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // أيقونة الميكروفون المتحركة
                            AnimatedCrossFade(
                              firstChild: Icon(
                                Icons.mic,
                                size: 40,
                                color: Colors.white,
                              ),
                              secondChild: Icon(
                                Icons.mic_none,
                                size: 40,
                                color: Colors.white,
                              ),
                              crossFadeState: isListening
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: Duration(milliseconds: 300),
                            ),
                            SizedBox(height: 8),

             
                            Text(
                              isListening
                                  ? remainingTime > 0
                                      ? '$remainingTime ثانية متبقية'
                                      : 'جاري الاستماع...'
                                  : 'انطق الحرف',
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

                  // موجات صوتية متحركة عند التسجيل
                  if (isListening)
                    ...List.generate(3, (index) {
                      return Positioned(
                        child: AnimatedOpacity(
                          opacity: isListening ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 500),
                          child: Container(
                            width: screenWidth * (0.38 + index * 0.06),
                            height: screenWidth * (0.38 + index * 0.06),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    Colors.red.withOpacity(0.5 - index * 0.1),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  // مؤشر الوقت المتبقي
                  if (isListening)
                    Positioned(
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$remainingTime',
                          style: TextStyle(
                            color:
                                remainingTime <= 2 ? Colors.red : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: screenHeight * 0.03),

              // أزرار التنقل بين الأحرف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      letterModel.nextLetter();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.08,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios, color: Colors.black),
                        Text(
                          "التالي",
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      letterModel.previousLetter(); 
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.08,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "السابق",
                          style: TextStyle(color: Colors.black),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// دالة مساعدة لإنشاء أزرار سرعة النطق
  Widget _buildSpeedButton(String label, double rate, bool isActive) {
    return ElevatedButton(
      onPressed: isProcessing ? null : () => changeSpeechRate(rate),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.orange : Colors.grey.shade300,
        foregroundColor: isActive ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}
