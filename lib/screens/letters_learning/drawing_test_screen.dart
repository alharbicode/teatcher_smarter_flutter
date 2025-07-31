import 'package:flutter/material.dart';
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

  DrawingPainter(this.points); // مُنشئ الفئة

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint() 
      ..color = Colors.black 
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round // نهايات الخط مستديرة
      ..strokeJoin = StrokeJoin.round; 

    // رسم الخطوط بين النقاط
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  // إعادة الرسم عند التغيير
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class DrawingTestScreen extends StatefulWidget {
  const DrawingTestScreen({super.key});

  @override
  _DrawingTestScreenState createState() => _DrawingTestScreenState();
}

// حالة واجهة اختبار الرسم
class _DrawingTestScreenState extends State<DrawingTestScreen> {
  List<Offset?> points = []; 
  List? _outputs; 
  bool _loading = false; 
  late Interpreter _interpreter; 
  List<String> _labels = []; 
  static const int inputSize = 224; 
  int batchSize = 1; 
  int _currentLetterIndex = 0; 
  bool _success = false; 
  int _correctCount = 0;
  int _consecutiveCorrect = 0; 
  int _attempts = 0; 
  List<bool> _completedLetters = []; 
  bool _isDrawing = false; 
  late FlutterTts flutterTts; 

 
  double _speechRate = 0.5;

  List<String> _correctMessages = [
    "أحسنت! رسمك للحرف ممتاز",
    "رائع! لقد رسمت الحرف بشكل صحيح",
    "ممتاز! استمر هكذا",
    "إجابة صحيحة! أنت تتحسن",
    "أحسنت! أداء رائع"
  ];

  List<String> _incorrectMessages = [
    "حاول مرة أخرى، أنت قريب من الإجابة الصحيحة",
    "لم يكن صحيحًا، لكن استمر في المحاولة!",
    "حاول مرة أخرى، أنت تستطيع!",
    "لا تقلق، يمكنك المحاولة مرة أخرى",
    "قريب جدًا، ركز أكثر على شكل الحرف"
  ];

  // مفاتيح لحفظ الإعدادات
  static const String _progressKey = 'currentLetterIndex';
  static const String _scoreKey = 'correctCount';
  static const String _completedLettersKey = 'completedLetters';
  static const String _speechRateKey = 'drawing_speech_rate';

  @override
  void initState() {
    super.initState();
    _loading = true; // بدء حالة التحميل
    initTts();
    _loadCompletedLetters(); 
    _loadProgress(); 
    _loadScore();


    loadModel().then((_) {
      setState(() {
        _loading = false;
        if (_labels.isNotEmpty) {
          
          if (_completedLetters.isEmpty) {
            _completedLetters = List.generate(_labels.length, (index) => false);
          }
        }
      });

      // بمجرد تحميل النموذج والبيانات، نتحقق ما إذا كان الحرف الحالي متاح، وننطقه
      if (_labels.isNotEmpty && _currentLetterIndex < _labels.length) {
        // تأخير بسيط لضمان استعداد واجهة المستخدم
        Future.delayed(const Duration(milliseconds: 500), () {
          _speakCurrentLetter();
        });
      }
    });
  }

 
  Future<void> _loadCompletedLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedLettersKey);
    if (completed != null) {
      setState(() {
        _completedLetters = completed.map((e) => e == 'true').toList();
      });
    }
  }

  Future<void> _saveCompletedLetters() async {
    final prefs = await SharedPreferences.getInstance();
    final completedStrings =
        _completedLetters.map((e) => e.toString()).toList();
    prefs.setStringList(_completedLettersKey, completedStrings);
  }


  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLetterIndex = prefs.getInt(_progressKey) ?? 0;
      _correctCount = prefs.getInt(_scoreKey) ?? 0;
    });
  }

  
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_progressKey, _currentLetterIndex);
  }


  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_scoreKey, _correctCount);
  }


  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedScore = prefs.getInt(_scoreKey);
    if (savedScore != null) {
      setState(() {
        _correctCount = savedScore;
      });
    }
  }

  void initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("ar-SA"); 
    flutterTts.setSpeechRate(_speechRate); 
    flutterTts.setPitch(1.0); 
    flutterTts.setVolume(1.0); 

    _loadSpeechRate(); // تحميل سرعة النطق المحفوظة
  }

  Future<void> _saveSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_speechRateKey, _speechRate);
  }


  Future<void> _loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    double? savedRate = prefs.getDouble(_speechRateKey);
    if (savedRate != null) {
      setState(() {
        _speechRate = savedRate;
        flutterTts.setSpeechRate(_speechRate);
      });
    }
  }

 
  Future<void> _changeSpeechRate(double rate) async {
    setState(() {
      _speechRate = rate;
    });
    await flutterTts.setSpeechRate(rate);
    _saveSpeechRate();
  }


  Future<void> _speakCurrentLetter() async {
    if (_labels.isNotEmpty && _currentLetterIndex < _labels.length) {
      await Future.delayed(const Duration(milliseconds: 300));

     
      String instructionMessage = "ارسم حرف ${_labels[_currentLetterIndex]}";
      await flutterTts.speak(instructionMessage);
    }
  }

//متبيقة
  Future<void> _speakRemainingLetters() async {
    if (_labels.isNotEmpty) {
      int remaining = _labels.length - (_currentLetterIndex + 1);

      if (remaining > 0) {
        String remainingMessage = "بقي لديك $remaining حروف";
        if (remaining == 1) {
          remainingMessage = "بقي لديك حرف واحد فقط";
        } else if (remaining == 2) {
          remainingMessage = "بقي لديك حرفان فقط";
        }

        await _speakMessage(remainingMessage);
      }
    }
  }


  Future<void> _speakLetterDetails() async {
    if (_labels.isNotEmpty && _currentLetterIndex < _labels.length) {
      String currentLetter = _labels[_currentLetterIndex];
      String detailMessage = _getLetterDetailMessage(currentLetter);

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
      'ه': 'حرف الهاء يرسم كحلقتين متصلتين بخط أفقي بينهما', // تم التعديل هنا
      'و': 'حرف الواو يرسم كدائرة صغيرة ثم خط منحني للأسفل',
      'ي': 'حرف الياء يرسم كحرف الباء ولكن بنقطتين تحتها',
      // 'ء': 'حرف الهمزة يرسم كشكل عين صغيرة مقلوبة',
      // 'ة': 'حرف التاء المربوطة يرسم كحرف الهاء ولكن بنقطتين فوقها',
      // 'ى': 'حرف الألف اللينة يرسم كحرف الياء بدون نقاط في آخره'
    };
    return letterDetails[letter] ?? 'ارسم حرف $letter بعناية واهتمام';
  }

// نطق رسالة معينة
  Future<void> _speakMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak(message);
  }


  Future<void> _playDrawSound() async {
   
    if (!_isDrawing) {
      _isDrawing = true;
      await _speakMessage("ابدأ الرسم الآن");
    }
  }


  Future<void> _playClearSound() async {
    await _speakMessage("تم مسح اللوحة");
    // إعادة تعيين حالة الرسم عند المسح
    _isDrawing = false;
  }

 

  void _moveToPreviousLetter() {
    if (_currentLetterIndex > 0 && _completedLetters[_currentLetterIndex - 1]) {
      setState(() {
        _currentLetterIndex--;
        _saveProgress();
        points.clear();
        _outputs = null;
        _success = false;
        _attempts = 0;
        if (_labels.isNotEmpty) {
          _speakCurrentLetter();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكنك الرجوع إلى حرف لم يتم حله بعد!'),
        ),
      );
    }
  }


  void _moveToNextLetter({bool fromCompletion = false}) {
    if (_currentLetterIndex < _labels.length - 1 &&
        (fromCompletion || _completedLetters[_currentLetterIndex + 1])) {
      setState(() {
        _currentLetterIndex++;
        _attempts = 0;
        _outputs = null;
        points.clear();
        _saveProgress();
      });

      // قم بنطق الحرف الجديد
      _speakCurrentLetter();

   
      if (_labels.length - (_currentLetterIndex + 1) < 4) {
        Future.delayed(const Duration(seconds: 2), () {
          _speakRemainingLetters();
        });
      }
    } else if (_currentLetterIndex == _labels.length - 1 ||
        !_completedLetters.contains(false)) {
      // حساب نسبة الإجابات الصحيحة كمؤشر للأداء
      double successRate = _correctCount / _labels.length;

      
      String motivationalMessage = '';
      if (successRate >= 1.0) {
        motivationalMessage =
            'رائع! لقد أتممت جميع الحروف بنجاح! أنت نجم حقيقي! 🌟';
      } else if (successRate >= 0.8) {
        motivationalMessage = 'أداء ممتاز! لقد أكملت معظم الحروف بنجاح! 🎉';
      } else if (successRate >= 0.5) {
        motivationalMessage =
            'أحسنت! لقد أكملت نصف الحروف على الأقل! استمر في التحسن! 👏';
      } else {
        motivationalMessage =
            'شكراً لمشاركتك! استمر في التدريب لتحسين مهاراتك! 💪';
      }

    
      _speakMessage(motivationalMessage);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Image.asset(
                'assets/trophy_icon.png',
                height: 36,
                width: 36,
              ),
              const SizedBox(width: 10),
              const Text('تهانينا! 🎉',
                  style: TextStyle(fontSize: 24, color: Color(0xFF2ECC71))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/celebration_animation.json',
                height: 120,
                repeat: true,
              ),
              const SizedBox(height: 16),
              Text(
                'لقد أكملت جميع الحروف بنجاح!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'عدد الحروف الصحيحة: $_correctCount',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3498DB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                motivationalMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentLetterIndex = 0;
                      _correctCount = 0;
                      _consecutiveCorrect = 0;
                      _completedLetters =
                          List.generate(_labels.length, (index) => false);
                      _saveProgress();
                      _saveCompletedLetters();
                      _saveScore();
                    });
                    _speakMessage("لنبدأ من جديد! حظاً موفقاً!");
                  },
                  icon: const Icon(Icons.replay, color: Colors.white),
                  label: const Text('ابدأ من جديد',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Future<void> loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/model_unquant1.tflite');
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n');
      print('Labels loaded: $_labels'); 
      print('Number of labels: ${_labels.length}');

      var inputShape = _interpreter.getInputTensor(0).shape;
      batchSize = inputShape[0];
      print('Batch size from model: $batchSize');
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
      // إنشاء مسجل للرسم (PictureRecorder) لتسجيل ما يرسمه المستخدم
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(300, 250);

     
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      
      DrawingPainter(points).paint(canvas, size);

      // إنهاء التسجيل والحصول على الصورة النهائية
      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());


      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

  
      final bytes = byteData.buffer.asUint8List();

   
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return;

     
      img.Image resizedImage =
          img.copyResize(originalImage, width: inputSize, height: inputSize);

      // إعداد مصفوفة المدخلات للنموذج (Float32List)
      var inputArray = Float32List(batchSize * inputSize * inputSize * 3);

      // معالجة كل بكسل في الصورة وإعداده للنموذج
      for (var batch = 0; batch < batchSize; batch++) {
        var batchOffset = batch * inputSize * inputSize * 3;
        for (var y = 0; y < inputSize; y++) {
          for (var x = 0; x < inputSize; x++) {
            var pixel = resizedImage.getPixel(x, y);
            var pixelOffset = batchOffset + (y * inputSize + x) * 3;

            // تطبيع قيم البكسل (RGB) لتكون في المدى [-1, 1]
            inputArray[pixelOffset] = (pixel.r.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 1] = (pixel.g.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 2] = (pixel.b.toDouble() - 127.5) / 127.5;
          }
        }
      }
      // إعداد مصفوفة المخرجات لتخزين نتائج النموذج
      var output = List.generate(batchSize, (index) => List.filled(28, 0.0));


      _interpreter.run(
          inputArray.reshape([batchSize, inputSize, inputSize, 3]), output);


      var firstResult = output[0];

// إعداد قائمة لتنظيم النتائج
      var results = <Map<String, dynamic>>[];

// تحويل نتائج النموذج إلى قائمة من الكائنات (كل كائن يمثل حرفاً وثقة النموذج به)
      for (var i = 0; i < firstResult.length; i++) {
        results.add({
          "index": i, 
          "label": _labels[i], 
          "confidence": firstResult[i] // درجة ثقة النموذج (بين 0 و1)
        });
      }


      results.sort((a, b) => b["confidence"].compareTo(a["confidence"]));

// الحصول على النتيجة الأولى (أعلى ثقة)
      var topResult = results[0];


      var isCorrectLetter = topResult["index"] == _currentLetterIndex;

// الحصول على درجة الثقة في التنبؤ
      var confidence = topResult["confidence"];


      setState(() {
        _loading = false;
      });


      _attempts++;


      if (confidence > 0.5 && isCorrectLetter) {
        _success = true; // تم الرسم بنجاح
        _correctCount++; 
        _saveScore(); 

      
        _consecutiveCorrect++;

        // تخزين المخرجات للعرض
        _outputs = [
          {
            "label": _labels[_currentLetterIndex], 
            "confidence": confidence, 
            "isCorrect": true, 
          }
        ];

        String stars = '';
        if (_attempts == 1) {
          stars = '⭐⭐⭐';
        } else if (_attempts == 2) {
          stars = '⭐⭐';
        } else {
          stars = '⭐';
        }

    
        _correctMessages.shuffle();
        String feedbackMessage = _correctMessages.first;

      
        if (_consecutiveCorrect >= 3) {
          feedbackMessage +=
              " لديك ${_consecutiveCorrect} إجابات صحيحة متتالية!";
        }

      
        await _speakMessage(feedbackMessage);

        showDialog(
          context: context,
          barrierDismissible: false, // لا يمكن إغلاق النافذة بالنقر خارجها
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'أحسنت! $stars',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  
                    Lottie.asset(
                      'assets/correct_animation.json',
                      height: 100,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    // عرض رسالة التحفيز
                    Text(
                      feedbackMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('التالي'),
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    _moveToNextLetter(
                        fromCompletion: true); 
                  },
                ),
              ],
            );
          },
        );
      } else {
        _success = false;
        // إعادة تعيين عدد الإجابات الصحيحة المتتالية
        _consecutiveCorrect = 0;

        // اختيار رسالة تحفيزية عشوائية
        _incorrectMessages.shuffle();
        String incorrectMessage = _incorrectMessages.first;

        _outputs = [
          {
            "label":
                _labels[topResult["index"]], // الحرف الذي تعرف عليه النموذج
            "confidence": confidence, 
            "isCorrect": false, 
            "message": incorrectMessage, // رسالة تحفيزية
          }
        ];

        await _speakMessage(incorrectMessage);

        showDialog(
          context: context,
          barrierDismissible: true, // يمكن إغلاق النافذة بالنقر خارجها
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'حاول مرة أخرى 💪',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE67E22)), 
                  ),
                
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Color(0xFF3498DB)),
                    onPressed: () => _speakMessage(incorrectMessage),
                    tooltip: 'استمع مرة أخرى',
                  ),
                ],
              ),
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
                    // عرض الرسالة في مربع مميز
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9E7), 
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE67E22).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(incorrectMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE67E22), 
                          )),
                    ),
                    const SizedBox(height: 15),
                    
                    Text(
                      'الحرف المطلوب: ${_labels[_currentLetterIndex]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50), 
                      ),
                    ),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15), 
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, 
                  children: [
                    ElevatedButton.icon(
                   
                      icon: const Icon(Icons.refresh,
                          color: Colors.white), 
                      label: const Text(
                        'حاول مرة أخرى',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFE67E22), 
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10), 
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), 
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); 
                        setState(() {
                          points.clear(); 
                          _outputs = null; // إعادة تعيين المخرجات
                        });
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error predicting drawing: $e'); // طباعة الخطأ في الكونسول
      setState(() {
        _loading = false; // إيقاف مؤشر التحميل في حالة الخطأ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pencil_icon.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'اختبار رسم الحروف',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التقدم: ${_currentLetterIndex + 1}/${_labels.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        'النقاط: $_correctCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _labels.isNotEmpty
                        ? (_currentLetterIndex + 1) / _labels.length
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3498DB),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Current Letter Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFECF0F1), Colors.white],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _labels.isNotEmpty && _currentLetterIndex < _labels.length
                        ? 'ارسم الحرف'
                        : 'جاري التحميل...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // إضافة إطار ظل للحرف الحالي
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3498DB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3498DB).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF3498DB).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: InkWell(
                            onTap: _speakCurrentLetter,
                            child: const Icon(
                              Icons.volume_up,
                              size: 36,
                              color: Color(0xFF3498DB),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // زر معلومات حول الاختبار
                      InkWell(
                        onTap: _showInstructions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF9B59B6),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // إضافة مؤشر رقم الحرف ضمن اختبار الحروف
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_currentLetterIndex + 1}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'من ${_labels.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Drawing Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3498DB), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // إزالة الدليل المرئي للحرف
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            points.add(details.localPosition);
                          });
                          // تشغيل صوت عند بدء الرسم
                          _playDrawSound();
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            points.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            points.add(null);
                            _isDrawing =
                                false; // إعادة تعيين حالة الرسم عند الانتهاء
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _labels.isNotEmpty ? _speakCurrentLetter : null,
                        icon: const Icon(Icons.volume_up,
                            color: Colors.white, size: 24),
                        label: const Text('استمع',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498DB),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                     
                      ElevatedButton.icon(
                        onPressed:
                            _labels.isNotEmpty ? _speakLetterDetails : null,
                        icon: const Icon(Icons.help_outline,
                            color: Colors.white, size: 24),
                        label: const Text('مساعدة',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B59B6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

               
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'سرعة النطق:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSpeedButton('بطيء', 0.3),
                            _buildSpeedButton('متوسط', 0.5),
                            _buildSpeedButton('سريع', 0.7),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: points.isNotEmpty
                              ? () {
                                  setState(() {
                                    points.clear();
                                    _outputs = null;
                                    _isDrawing =
                                        false; 
                                  });
                                  
                                  _playClearSound();
                                }
                              : null,
                          icon: const Icon(Icons.refresh,
                              color: Colors.white, size: 24),
                          label: const Text('إعادة',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: points.isNotEmpty ? predictDrawing : null,
                          icon: const Icon(Icons.check,
                              color: Colors.white, size: 24),
                          label: const Text('تحقق',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSpeedButton(String label, double rate) {
    bool isSelected = _speechRate == rate;
    return InkWell(
      onTap: () => _changeSpeechRate(rate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3498DB) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
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


  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF3498DB), size: 28),
            const SizedBox(width: 10),
            const Text('كيفية الاستخدام',
                style: TextStyle(color: Color(0xFF2C3E50))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionItem(
                'اضغط على زر الاستماع لسماع الحرف المطلوب رسمه'),
            _buildInstructionItem('استخدم الشاشة لرسم الحرف كما سمعته'),
            _buildInstructionItem(
                'اضغط على زر المساعدة للحصول على تفاصيل حول كيفية رسم الحرف'),
            _buildInstructionItem(
                'استخدم أزرار ضبط سرعة النطق لتغيير سرعة نطق الحروف'),
            _buildInstructionItem('عند الانتهاء من الرسم، اضغط على زر التحقق'),
            _buildInstructionItem('يمكنك إعادة المحاولة بالضغط على زر المسح'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            child: const Text('فهمت',
                style: TextStyle(color: Color(0xFF3498DB), fontSize: 16)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // بناء عنصر تعليمات
  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    flutterTts.stop();
    super.dispose();
  }
}
