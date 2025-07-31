import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = Colors.black 
      ..strokeWidth = 10.0 
      ..strokeCap = StrokeCap.round // نهايات الخط مستديرة
      ..strokeJoin = StrokeJoin.round; // تقاطعات الخطوط مستديرة
// حلقة لرسم خطوط بين النقاط المتتالية
    for (int i = 0; i < points.length - 1; i++) {
      // التأكد من أن النقطة الحالية والتالية ليست null
      if (points[i] != null && points[i + 1] != null) {
        // رسم خط بين النقطة الحالية والنقطة التالية
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override

// هنا نعيد true دائماً مما يعني إعادة الرسم عند أي تغيير
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}


class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override

  _DrawingScreenState createState() => _DrawingScreenState();
}

// تعريف حالة واجهة الرسم
class _DrawingScreenState extends State<DrawingScreen> {
  List<Offset?> points = []; 
  List? _outputs; 
  bool _loading = false; 
  late Interpreter _interpreter; 
  List<String> _labels = []; 
  static const int inputSize = 224; 
  int batchSize = 1; 
  int _currentLetterIndex = 0; 
  bool _success = false; 
  late FlutterTts flutterTts; 
  int _correctCount = 0; 
  int _attempts = 0; 
  List<bool> _completedLetters = []; 
  static const String _progressKey =
      'drawingScreenProgress'; 
  static const String _scoreKey = 'drawingScreenScore'; 
  static const String _completedLettersKey =
      'drawingScreenCompletedLetters'; 
  final List<String> _encouragementMessages = [
    "أحسنت! استمر في التقدم",
    "ممتاز! أنت تتعلم بسرعة",
    "رائع! انتقل إلى الحرف التالي",
    "جميل جداً! واصل التقدم",
    "ما شاء الله! أداء رائع",
    "أنت موهوب جداً!",
    "استمر هكذا، أنت تتحسن",
    "خط جميل! أحسنت",
    "رائع! يمكنك أن تكون خطاطاً ماهراً!",
    "إبداع متميز! واصل الكتابة الجميلة",
    "تحسن ملحوظ! أنت تتقن الكتابة بسرعة",
  ];

  final List<String> _instructionMessages = [
    "ارسم الحرف",
    "حاول رسم الحرف",
    "اكتب الحرف",
    "دعنا نتعلم كتابة حرف",
    "انظر إلى الحرف وحاول تقليده",
    "الآن سنتدرب على كتابة حرف",
  ];

  double _speechRate = 0.5; 
  static const String _speechRateKey =
      'drawingScreenSpeechRate'; 

  bool _isDrawing = false; 
  int _consecutiveCorrect = 0; 

  @override
  void initState() {
    super.initState(); 
    _loading = true; 
    _loadProgress(); 
    _loadSpeechRate();
    loadModel().then((value) {
    
      setState(() {
        _loading = false; 
        if (_labels.isNotEmpty) {
          // إذا كانت هناك تسميات محملة
          _speakInstructions(); 
          // إنشاء قائمة الحروف المكتملة (كلها false في البداية)
          _completedLetters = List.generate(_labels.length, (index) => false);
          _loadCompletedLetters();
        }
      });
    });
    initTts();
  }


  Future<void> _loadCompletedLetters() async {
    final prefs =
        await SharedPreferences.getInstance(); //ادا مشترك
    final completed =
        prefs.getStringList(_completedLettersKey); 
    if (completed != null) {
      // إذا كانت هناك بيانات محفوظة
      setState(() {
        // تحويل القائمة من نص ('true'/'false') إلى قائمة boolean
        _completedLetters = completed.map((e) => e == 'true').toList();
      });
    }
  }


  Future<void> _saveCompletedLetters() async {
    final prefs =
        await SharedPreferences.getInstance(); 
   
    final completedStrings =
        _completedLetters.map((e) => e.toString()).toList();
    prefs.setStringList(_completedLettersKey, completedStrings); // حفظ القائمة
  }


  Future<void> _loadProgress() async {
    final prefs =
        await SharedPreferences.getInstance(); 
    setState(() {
      _currentLetterIndex =
          prefs.getInt(_progressKey) ?? 0; // جلب مؤشر الحرف أو 0 افتراضياً
      _correctCount = prefs.getInt(_scoreKey) ??
          0; // جلب عدد الإجابات الصحيحة أو 0 افتراضياً
    });
  }


  Future<void> _saveProgress() async {
    final prefs =
        await SharedPreferences.getInstance(); 
    prefs.setInt(_progressKey, _currentLetterIndex); 
  }


  Future<void> _saveScore() async {
    final prefs =
        await SharedPreferences.getInstance(); 
    prefs.setInt(_scoreKey, _correctCount); 
  }


  void initTts() {
    flutterTts = FlutterTts(); 
    flutterTts.setLanguage("ar-SA"); 
    flutterTts.setSpeechRate(_speechRate); 
    flutterTts.setPitch(1.0); // تعيين طبقة الصوت (1.0 = عادية)
    flutterTts.setVolume(1.0); 
  }


  Future<void> _saveSpeechRate() async {
    final prefs =
        await SharedPreferences.getInstance(); 
    prefs.setDouble(_speechRateKey, _speechRate); 
  }


  Future<void> _loadSpeechRate() async {
    final prefs =
        await SharedPreferences.getInstance(); 
    setState(() {
      _speechRate = prefs.getDouble(_speechRateKey) ??
          0.5; // تحميل القيمة أو استخدام 0.5 كافتراضي
    });
  }


  void _changeSpeechRate(double rate) {
    setState(() {
      _speechRate = rate; // تحديث معدل السرعة في الحالة
    });
    flutterTts.setSpeechRate(rate); // تطبيق السرعة الجديدة على محول الكلام
    _saveSpeechRate(); 
  }


  Future<void> _speakInstructions() async {
    if (_labels.isEmpty) return; // إذا لم تكن هناك تسميات، الخروج

    final random = Random(); // إنشاء كائن عشوائي
    // اختيار رسالة تعليمية عشوائية من القائمة
    String instruction =
        _instructionMessages[random.nextInt(_instructionMessages.length)];

    await flutterTts.speak("$instruction ${_labels[_currentLetterIndex]}");
  }

  Future<void> _speakCurrentLetter() async {
    if (_labels.isNotEmpty) {
  
      await Future.delayed(
          const Duration(milliseconds: 500)); 
      await flutterTts.speak(_labels[_currentLetterIndex]); // نطق الحرف الحالي
    }
  }


  Future<void> _speakLetterDetails() async {
    
    if (_labels.isNotEmpty && _currentLetterIndex < _labels.length) {
      String currentLetter =// {ساله حاليه}
          _labels[_currentLetterIndex]; 
      String detailMessage =
          _getLetterDetailMessage(currentLetter); 

      await flutterTts.speak(detailMessage); 
    }
  }

  String _getLetterDetailMessage(String letter) {
    Map<String, String> letterDetails = {
      'أ': 'حرف الألف يرسم بخط عمودي مستقيم مع همزة فوقه',
      'ب': 'حرف الباء يرسم كنصف دائرة أفقية مع نقطة تحتها',
      'ت': 'حرف التاء يرسم كنصف دائرة أفقية مع نقطتين فوقها',
      'ث': 'حرف الثاء يرسم كنصف دائرة أفقية مع ثلاث نقاط فوقها',
      'ج': 'حرف الجيم يرسم كحاجب العين مع نقطة في بطنه',
      'ح': 'حرف الحاء يرسم كحاجب العين بدون نقطة',
      'خ': 'حرف الخاء يرسم كحاجب العين مع نقطة فوقه',
      'د': 'حرف الدال يرسم كخط مائل قصير ثم خط أفقي قصير',
      'ذ': 'حرف الذال يرسم كخط مائل قصير ثم خط أفقي قصير مع نقطة فوقه',
      'ر': 'حرف الراء يرسم كقوس منحني للأسفل',
      'ز': 'حرف الزاي يرسم كقوس منحني للأسفل مع نقطة فوقه',
      'س': 'حرف السين يرسم كثلاثة أسنان صغيرة متصلة ثم قوس كبير',
      'ش':
          'حرف الشين يرسم كثلاثة أسنان صغيرة متصلة ثم قوس كبير مع ثلاث نقاط فوقه',
      'ص': 'حرف الصاد يرسم كحاجب عين مغلقة ثم خط أفقي',
      'ض': 'حرف الضاد يرسم كحاجب عين مغلقة ثم خط أفقي مع نقطة فوقه',
      'ط': 'حرف الطاء يرسم كحاجب عين مغلقة ثم خط عمودي طويل',
      'ظ': 'حرف الظاء يرسم كحاجب عين مغلقة ثم خط عمودي طويل مع نقطة فوقه',
      'ع': 'حرف العين يرسم كعين مفتوحة صغيرة ثم عين مفتوحة كبيرة تحتها',
      'غ':
          'حرف الغين يرسم كعين مفتوحة صغيرة ثم عين مفتوحة كبيرة تحتها مع نقطة فوقها',
      'ف': 'حرف الفاء يرسم كدائرة صغيرة ثم خط أفقي ثم خط عمودي',
      'ق': 'حرف القاف يرسم كدائرة صغيرة ثم خط أفقي ثم خط عمودي مع نقطتين فوقه',
      'ك': 'حرف الكاف يرسم كخط عمودي طويل ثم خط أفقي ثم شكل كاف صغير بداخله',
      'ل': 'حرف اللام يرسم كخط عمودي طويل ثم نصف دائرة صغيرة لليسار',
      'م': 'حرف الميم يرسم كدائرة صغيرة ثم خط أفقي',
      'ن': 'حرف النون يرسم كقوس كبير مع نقطة فوقه',
      'ه': 'حرف الهاء يرسم كحلقتين متصلتين بخط أفقي بينهما',
      'و': 'حرف الواو يرسم كدائرة صغيرة ثم خط منحني للأسفل',
      'ي': 'حرف الياء يرسم كحرف الباء ولكن بنقطتين تحتها',
    };

    return letterDetails[letter] ?? 'ارسم حرف $letter بعناية واهتمام';
  }

// الحصول على رسالة تشجيع عشوائية من القائمة
  String _getRandomEncouragement() {
    final random = Random(); 
    return _encouragementMessages[
        random.nextInt(_encouragementMessages.length)]; 
  }


  Future<void> _speakMessage(String message) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); 
    await flutterTts.speak(message); 
  }


  Future<void> _playDrawSound() async {
    if (!_isDrawing) {
      
      _isDrawing = true; // تحديث حالة الرسم
      await flutterTts.speak("ابدأ الرسم الآن"); 
    }
  }


  Future<void> _playClearSound() async {
    await flutterTts.speak("تم مسح اللوحة"); 
    _isDrawing = false; 
  }


  Future<void> loadModel() async {
    try {
    
      _interpreter =
          await Interpreter.fromAsset('assets/model_unquant1.tflite');

      // تحميل تسميات النموذج (labels.txt)
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n'); // تقسيم التسميات إلى قائمة

      // الحصول على شكل المدخلات للنموذج
      var inputShape = _interpreter.getInputTensor(0).shape;
      batchSize = inputShape[0]; 
      print('Batch size from model: $batchSize'); // طباعة معلومات التصحيح
    } catch (e) {
      print('Error loading model: $e'); 
    }
  }


  Future<void> predictDrawing() async {
    if (_labels.isEmpty) {
      
      print('Error: Labels not loaded yet.');
      return;
    }
    setState(() {
      _loading = true; 
    });

    try {
      // إنشاء مسجل للرسم
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(300, 250); // تحديد حجم الصورة

     
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      DrawingPainter(points).paint(canvas, size);


      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());


      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return; // إذا فشل التحويل، إنهاء العملية


      final bytes = byteData.buffer.asUint8List();


      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return; // إذا فشل فك التشفير، إنهاء العملية

// تغيير حجم الصورة لتناسب حجم مدخلات النموذج (224x224 بكسل)
      img.Image resizedImage =
          img.copyResize(originalImage, width: inputSize, height: inputSize);

// إعداد مصفوفة المدخلات للنموذج (بتنسيق Float32)
      var inputArray = Float32List(batchSize * inputSize * inputSize * 3);

// معالجة كل بكسل في الصورة وتطبيع القيم
      for (var batch = 0; batch < batchSize; batch++) {
        var batchOffset = batch * inputSize * inputSize * 3;
        for (var y = 0; y < inputSize; y++) {
          for (var x = 0; x < inputSize; x++) {
            var pixel = resizedImage.getPixel(x, y); // الحصول على لون البكسل
            var pixelOffset = batchOffset + (y * inputSize + x) * 3;

            // تطبيع قيم RGB (تغيير النطاق من [0,255] إلى [-1,1])
            inputArray[pixelOffset] = (pixel.r.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 1] = (pixel.g.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 2] = (pixel.b.toDouble() - 127.5) / 127.5;
          }
        }
      }


      var output = List.generate(batchSize, (index) => List.filled(28, 0.0));
      _interpreter.run(
          inputArray.reshape([batchSize, inputSize, inputSize, 3]), output);

// معالجة نتائج التنبؤ
      var firstResult = output[0];
      var results = <Map<String, dynamic>>[];

// إنشاء قائمة بالنتائج مع التسميات والثقة
      for (var i = 0; i < firstResult.length; i++) {
        results.add(
            {"index": i, "label": _labels[i], "confidence": firstResult[i]});
      }

// ترتيب النتائج تنازلياً حسب مستوى الثقة
      results.sort((a, b) => b["confidence"].compareTo(a["confidence"]));


      var topResult = results[0];
      var isCorrectLetter = topResult["index"] == _currentLetterIndex;
      var confidence = topResult["confidence"];

      setState(() {
        _loading = false;
      });


      _attempts++;

// إذا كانت النتيجة صحيحة وثقة النموذج عالية
      if (confidence > 0.5 && isCorrectLetter) {
        _success = true; 
        _correctCount++; 
        _saveScore(); 

        String stars = '';
        if (_attempts == 1) {
          stars = '⭐⭐⭐';
        } else if (_attempts == 2) {
          stars = '⭐⭐';
        } else {
          stars = '⭐';
        }


        var message = _getRandomEncouragement();

// تخزين نتائج التنبؤ
        _outputs = [
          {
            "label": _labels[_currentLetterIndex], 
            "confidence": confidence, 
            "isCorrect": true, 
            "message": message, //
          }
        ];


        await _speakMessage(
            "$message! لقد رسمت حرف ${_labels[_currentLetterIndex]} بشكل صحيح");


        showDialog(
          context: context,
          barrierDismissible: false, // لا يمكن إغلاق النافذة بالضغط خارجها
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('أحسنت! $stars'), 
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                 
                    Lottie.asset(
                      'assets/correct_animation.json',
                      height: 120,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    // مربع نصي يوضح الحرف الصحيح
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9), // لون خلفية أخضر فاتح
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2ECC71).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'لقد رسمت حرف ${_labels[_currentLetterIndex]} بشكل صحيح',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('التالي'),
                  onPressed: () {
                    Navigator.of(context).pop(); // إغلاق النافذة الحالية
                    if (_currentLetterIndex < _labels.length - 1) {
                      // إذا لم نكن في الحرف الأخير
                      _completedLetters[_currentLetterIndex] = true;
                      _saveCompletedLetters();
                      _moveToNextLetter(); 
                    } else {
                      // إذا كنا في الحرف الأخير
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تهانينا! 🎉'),
                          content: Text(
                              'لقد أكملت جميع الحروف بنجاح! عدد الحروف الصحيحة: $_correctCount'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  // إعادة تعيين كل القيم للبدء من جديد
                                  _currentLetterIndex = 0;
                                  _correctCount = 0;
                                  _consecutiveCorrect = 0;
                                  _completedLetters = List.generate(
                                      _labels.length, (index) => false);
                                  _saveProgress();
                                  _saveCompletedLetters();
                                  _saveScore();
                                });
                              },
                              child: const Text('ابدأ من جديد'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      } else {
// إذا كانت الإجابة خاطئة
        _success = false;
        var incorrectMessage = "حاول مرة أخرى!";
        _outputs = [
          {
            "label": _labels[topResult["index"]], 
            "confidence": confidence, 
            "isCorrect": false, 
            "message": incorrectMessage, 
          }
        ];

        await _speakMessage(incorrectMessage);


        showDialog(
          context: context,
          barrierDismissible: true, // يسمح بإغلاق النافذة بالضغط خارجها
          builder: (BuildContext context) {
            return AlertDialog(
              title:
                  const Text('حاول مرة أخرى 💪'), 
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   
                    Lottie.asset(
                      'assets/incorrect_animation.json',
                      height: 100,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    // نص رسالة المحاولة مرة أخرى
                    Text(incorrectMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.orange, 
                        )),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('حسناً'),
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    setState(() {
                      points.clear(); 
                      _outputs = null; // مسح نتائج التنبؤ
                    });
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
// معالجة الأخطاء التي قد تحدث أثناء التنبؤ
      print('Error predicting drawing: $e');
      setState(() {
        _loading = false; 
      });
    }
  }


  void _moveToNextLetter() {
    setState(() {
      if (_currentLetterIndex < _labels.length - 1) {
      
        _currentLetterIndex++; // زيادة مؤشر الحرف الحالي
        _saveProgress(); 

       
        _consecutiveCorrect++;

        // عرض رسالة خاصة إذا كانت هناك عدة إجابات صحيحة متتالية
        if (_consecutiveCorrect >= 3) {
          _speakMessage("رائع! أنت تتحسن بسرعة كبيرة");
        } else {
          _speakInstructions(); 
        }
      } else {
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تهانينا! 🎉'), 
            content: Text(
                'لقد أكملت جميع الحروف بنجاح! عدد الحروف الصحيحة: $_correctCount'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); 
                  setState(() {
                    _currentLetterIndex = 0; // العودة للحرف الأول
                    _consecutiveCorrect = 0; // إعادة تعيين العداد
                    _speakInstructions(); 
                  });
                },
                child: const Text('ابدأ من جديد'),
              ),
            ],
          ),
        );
      }

      // إعادة تعيين الحالة للرسم الجديد
      points.clear(); 
      _outputs = null; // مسح النتائج
      _success = false; // إعادة تعيين حالة النجاح
      _attempts = 0; // إعادة تعيين عدد المحاولات
    });
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء للتطبيق
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة القلم في شريط العنوان
            Image.asset(
              'assets/pencil_icon.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 8), 
            const Text(
              'رسم الحروف', 
              style: TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold, // نص عريض
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade100, 
        centerTitle: true, 
        elevation: 0, 
      ),
      body: SafeArea(
        child: OrientationBuilder(
          // بناء الواجهة حسب اتجاه الشاشة
          builder: (context, orientation) {
            return Column(
              children: [
                const SizedBox(height: 20), 

                // منطقة عرض الحرف المستهدف
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // تدرج لوني للخلفية
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15), 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2), 
                            blurRadius: 8, // درجة ضبابية الظل
                            offset: const Offset(0, 3), // اتجاه الظل
                          )
                        ],
                      ),
                      child: Center(
                        child: _labels.isNotEmpty
                            ? Image.asset(
                                
                                'assets/image_letters/${_labels[_currentLetterIndex]}.png',
                                fit: BoxFit.contain,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  // إذا لم توجد صورة، عرض الحرف كنص
                                  return Text(
                                    _labels[_currentLetterIndex],
                                    style: TextStyle(
                                      fontSize: orientation ==
                                              Orientation.portrait
                                          ? screenWidth *
                                              0.2 // حجم الخط في الوضع الرأسي
                                          : screenWidth *
                                              0.15, // حجم الخط في الوضع الأفقي
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              )
                            : const SizedBox(), // إذا لم يتم تحميل التسميات بعد
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // منطقة الرسم الرئيسية
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    height: screenHeight * 0.4, 
                    margin: const EdgeInsets.symmetric(
                        horizontal: 20), // هوامش أفقية
                    decoration: BoxDecoration(
                      color: Colors.white, // خلفية بيضاء
                      borderRadius: BorderRadius.circular(20), 
                      border: Border.all(
                          color: Colors.grey.shade400), 
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20), 
                      child: GestureDetector(
                        
                        onPanStart: (details) {
                          setState(() {
                            points.add(details.localPosition); // بدء الرسم
                          });
                          _playDrawSound(); 
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            points.add(details.localPosition); // استمرار الرسم
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            points.add(null); // نهاية السكتة
                            _isDrawing = false; // تغيير حالة الرسم
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(points), 
                          size: Size.infinite, // حجم لا نهائي
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20), 

                // عناصر التحكم في سرعة النطق
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20), 
                  child: Column(
                    children: [
                      const Text('سرعة النطق:', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8), 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSpeedButton('بطيء', 0.3), 
                          _buildSpeedButton('متوسط', 0.5), 
                          _buildSpeedButton('سريع', 0.7), 
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

// أزرار التحكم - تم تنظيمها في صفوف لتجنب التداخل
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20), 
                  child: Column(
                    children: [
                    
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, 
                        children: [
                          // زر المسح
                          ElevatedButton.icon(
                            onPressed: points
                                    .isNotEmpty // تفعيل الزر فقط إذا كان هناك رسم
                                ? () {
                                    setState(() {
                                      points.clear(); 
                                      _outputs = null; 
                                      _isDrawing = false;
                                    });
                                    _playClearSound(); 
                                  }
                                : null, // تعطيل الزر إذا لم يكن هناك رسم
                            icon: const Icon(
                              Icons.refresh, 
                              color: Colors.white, 
                              size: 24, 
                            ),
                            label: const Text('مسح', 
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white)), 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                  0xFFF08080), 
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12), // حواف داخلية
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)), 
                            ),
                          ),

                          const SizedBox(width: 15), 

                      
                          ElevatedButton.icon(
                            onPressed: points.isNotEmpty
                                ? predictDrawing
                                : null, 
                            icon: const Icon(Icons.check, 
                                color: Colors.white,
                                size: 24),
                            label: const Text('تحقق', 
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                  0xFF90EE90), 
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Segunda fila de botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón de ayuda
                          ElevatedButton.icon(
                            onPressed: _speakLetterDetails,
                            icon: const Icon(Icons.help_outline,
                                color: Colors.white, size: 24),
                            label: const Text('المساعدة',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9370DB),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Botón de escuchar
                          ElevatedButton.icon(
                            onPressed: _speakCurrentLetter,
                            icon: const Icon(Icons.volume_up,
                                color: Colors.white, size: 24),
                            label: const Text('استمع',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3498DB),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  // بناء زر تحديد سرعة الكلام
  Widget _buildSpeedButton(String label, double rate) {
    bool isSelected = _speechRate == rate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: () => _changeSpeechRate(rate),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFF3498DB) : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isSelected ? 3 : 1,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // تنظيف الموارد
  @override
  void dispose() {
    _interpreter.close();
    flutterTts.stop();
    super.dispose();
  }
}
