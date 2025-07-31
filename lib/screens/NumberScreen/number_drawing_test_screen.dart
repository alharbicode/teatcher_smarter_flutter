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

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class NumberDrawingTestScreen extends StatefulWidget {
  const NumberDrawingTestScreen({super.key});

  @override
  _NumberDrawingTestScreenState createState() =>
      _NumberDrawingTestScreenState();
}

class _NumberDrawingTestScreenState extends State<NumberDrawingTestScreen> {
  List<Offset?> points = [];
  List? _outputs;
  bool _loading = false;
  late Interpreter _interpreter;
  List<String> _labels = [];
  static const int inputSize = 224;
  int batchSize = 1;
  int _currentNumberIndex = 0;
  bool _success = false;
  int _correctCount = 0;
  int _consecutiveCorrect = 0;
  int _attempts = 0;
  List<bool> _completedNumbers = [];
  bool _isDrawing = false; // متغير لتتبع حالة الرسم
  late FlutterTts flutterTts; // تعريف متغير FlutterTts


  double _speechRate = 0.5; // معدل السرعة الافتراضي

 
  final List<String> _correctMessages = [
    "أحسنت! رسمك للرقم  ممتاز",
    "رائع! لقد رسمت الرقم  بشكل صحيح",
    "ممتاز! استمر هكذا",
    "إجابة صحيحة! أنت تتحسن",
    "أحسنت! أداء رائع"
  ];

  final List<String> _incorrectMessages = [
    "حاول مرة أخرى، أنت قريب من الإجابة الصحيحة",
    "لم يكن صحيحًا، لكن استمر في المحاولة!",
    "حاول مرة أخرى، أنت تستطيع!",
    "لا تقلق، يمكنك المحاولة مرة أخرى",
    "قريب جدًا، ركز أكثر على شكل الرقم "
  ];

  // مفاتيح لحفظ الإعدادات
  static const String _progressKey = 'currentNumberIndex';
  static const String _scoreKey = 'correctCount';
  static const String _completedNumbersKey = 'completedNumbers';
  static const String _speechRateKey = 'drawing_speech_rate';

  @override
  void initState() {
    super.initState();
    _loading = true; 
    initTts();
    _loadcompletedNumbers();
    _loadProgress();
    _loadScore();

    loadModel().then((_) {
      setState(() {
        _loading = false;
        if (_labels.isNotEmpty) {
          // إذا لم يتم تحميل الارقام  المكتملة، نقوم بإنشاء مصفوفة جديدة
          if (_completedNumbers.isEmpty) {
            _completedNumbers = List.generate(_labels.length, (index) => false);
          }
        }
      });


      if (_labels.isNotEmpty && _currentNumberIndex < _labels.length) {
        // تأخير بسيط لضمان استعداد واجهة المستخدم
        Future.delayed(const Duration(milliseconds: 500), () {
          _speakCurrentLetter();
        });
      }
    });
  }

  Future<void> _loadcompletedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedNumbersKey);
    if (completed != null) {
      setState(() {
        _completedNumbers = completed.map((e) => e == 'true').toList();
      });
    }
  }

  Future<void> _savecompletedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final completedStrings =
        _completedNumbers.map((e) => e.toString()).toList();
    prefs.setStringList(_completedNumbersKey, completedStrings);
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentNumberIndex = prefs.getInt(_progressKey) ?? 0;
      _correctCount = prefs.getInt(_scoreKey) ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_progressKey, _currentNumberIndex);
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(_scoreKey, _correctCount);
  }

  // استرجاع نتيجة درجة الاختبار
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

    // استعادة معدل سرعة النطق المحفوظ
    _loadSpeechRate();
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
    if (_labels.isNotEmpty && _currentNumberIndex < _labels.length) {
      await Future.delayed(const Duration(milliseconds: 300));

      // نطق رسالة توجيهية أكثر تفصيلاً
      String instructionMessage = "ارسم رقم ${_labels[_currentNumberIndex]}";
      await flutterTts.speak(instructionMessage);
    }
  }

  // إضافة دالة لنطق الارقام المتبقية
  Future<void> _speakRemainingLetters() async {
    if (_labels.isNotEmpty) {
      int remaining = _labels.length - (_currentNumberIndex + 1);

      if (remaining > 0) {
        String remainingMessage = "بقي لديك $remaining ارقام";
        if (remaining == 1) {
          remainingMessage = "بقي لديك رقم واحد فقط";
        } else if (remaining == 2) {
          remainingMessage = "بقي لديك رقمان فقط";
        }

        await _speakMessage(remainingMessage);
      }
    }
  }

  Future<void> _speakLetterDetails() async {
    if (_labels.isNotEmpty && _currentNumberIndex < _labels.length) {
      String currentNumber = _labels[_currentNumberIndex];
      String detailMessage = _getLetterDetailMessage(currentNumber);

      await flutterTts.speak(detailMessage);
    }
  }


  String _getLetterDetailMessage(String letter) {

    Map<String, String> numberDetails = {
      '0':
          'الصفر يرسم كدائرة كاملة. ابدأ من أعلى الدائرة وارسمها باتجاه عقارب الساعة حتى تكتمل.',
      '1':
          'الواحد يرسم كخط عامودي مستقيم من الأعلى إلى الأسفل. يمكنك البدء من الأعلى والنزول لأسفل بخط مستقيم.',
      '2':
          'الاثنان يرسم كقوس مفتوح للأعلى يبدأ من اليسار، ثم ينزل بشكل مائل للأسفل، ثم ينتهي بخط أفقي من اليسار إلى اليمين.',
      '3':
          'الثلاثة ترسم كقوسين متتاليين مفتوحين للجهة اليمنى. ابدأ من الأعلى بقوس مفتوح ثم ارسم قوساً آخر مماثل له من المنتصف نحو الأسفل.',
      '4':
          'الأربعة ترسم كخط عامودي مع خط أفقي يقطعه من المنتصف، ثم خط عامودي آخر ينزل من طرف الخط الأفقي.',
      '5':
          'الخمسة ترسم كخط أفقي في الأعلى، ثم خط عامودي ينزل منه، ثم قوس مفتوح لليمين في الأسفل.',
      '6':
          'الستة ترسم بدءاً من الأعلى بخط ينحني تدريجياً حتى يشكل دائرة في الأسفل.',
      '7':
          'السبعة ترسم كخط أفقي في الأعلى، ثم خط مائل ينزل من طرفه الأيمن إلى الأسفل.',
      '8':
          'الثمانية ترسم كدائرتين فوق بعضهما، ويمكن رسمها بحركة متصلة تشبه رقم 8 باللغة الإنجليزية.',
      '9':
          'التسعة ترسم كدائرة في الأعلى يتصل بها خط عامودي ينزل من جهة اليمين.',
    };
    return numberDetails[letter] ?? 'ارسم رقم  $letter بعناية واهتمام';
  }

  Future<void> _speakMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak(message);
  }


  Future<void> _playDrawSound() async {
    // تجنب تكرار الصوت إذا كان الرسم مستمرا
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
    if (_currentNumberIndex > 0 && _completedNumbers[_currentNumberIndex - 1]) {
      setState(() {
        _currentNumberIndex--;
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
          content: Text('لا يمكنك الرجوع إلى رقم  لم يتم حله بعد!'),
        ),
      );
    }
  }

  void _moveToNextLetter({bool fromCompletion = false}) {
    if (_currentNumberIndex < _labels.length - 1 &&
        (fromCompletion || _completedNumbers[_currentNumberIndex])) {
      setState(() {
        _currentNumberIndex++;
        _attempts = 0;
        _outputs = null;
        points.clear();
        _saveProgress();
      });

      // قم بنطق الرقم  الجديد
      _speakCurrentLetter();

   
      if (_labels.length - (_currentNumberIndex + 1) < 4) {
        Future.delayed(const Duration(seconds: 2), () {
          _speakRemainingLetters();
        });
      }
    } else if (_currentNumberIndex == _labels.length - 1 ||
        !_completedNumbers.contains(false)) {
      // حساب نسبة الإجابات الصحيحة كمؤشر للأداء
      double successRate = _correctCount / _labels.length;

      // رسالة تحفيزية بناءً على عدد النقاط
      String motivationalMessage = '';
      if (successRate >= 1.0) {
        motivationalMessage =
            'رائع! لقد أتممت جميع الارقام  بنجاح! أنت نجم حقيقي! 🌟';
      } else if (successRate >= 0.8) {
        motivationalMessage = 'أداء ممتاز! لقد أكملت معظم الارقام  بنجاح! 🎉';
      } else if (successRate >= 0.5) {
        motivationalMessage =
            'أحسنت! لقد أكملت نصف الارقام  على الأقل! استمر في التحسن! 👏';
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
                'لقد أكملت جميع الارقام  بنجاح!',
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
                    'عدد الارقام  الصحيحة: $_correctCount',
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
                      _currentNumberIndex = 0;
                      _correctCount = 0;
                      _consecutiveCorrect = 0;
                      _completedNumbers =
                          List.generate(_labels.length, (index) => false);
                      _saveProgress();
                      _savecompletedNumbers();
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
      _interpreter = await Interpreter.fromAsset('assets/numbers_model.tflite');
      final labelData = await rootBundle.loadString('assets/labelsNum.txt');
      _labels = labelData.split('\n');
      print('Labels loaded: $_labels'); // إضافة طباعة للتأكد من التحميل
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
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(300, 250);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      DrawingPainter(points).paint(canvas, size);

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

      var inputArray = Float32List(batchSize * inputSize * inputSize * 3);

      for (var batch = 0; batch < batchSize; batch++) {
        var batchOffset = batch * inputSize * inputSize * 3;
        for (var y = 0; y < inputSize; y++) {
          for (var x = 0; x < inputSize; x++) {
            var pixel = resizedImage.getPixel(x, y);
            var pixelOffset = batchOffset + (y * inputSize + x) * 3;
            inputArray[pixelOffset] = (pixel.r.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 1] = (pixel.g.toDouble() - 127.5) / 127.5;
            inputArray[pixelOffset + 2] = (pixel.b.toDouble() - 127.5) / 127.5;
          }
        }
      }

      var output = List.generate(batchSize, (index) => List.filled(10, 0.0));
      _interpreter.run(
          inputArray.reshape([batchSize, inputSize, inputSize, 3]), output);

      var firstResult = output[0];

      var results = <Map<String, dynamic>>[];
      for (var i = 0; i < firstResult.length; i++) {
        results.add(
            {"index": i, "label": _labels[i], "confidence": firstResult[i]});
      }

      results.sort((a, b) => b["confidence"].compareTo(a["confidence"]));

      var topResult = results[0];
      var isCorrectLetter = topResult["index"] == _currentNumberIndex;
      var confidence = topResult["confidence"];

      setState(() {
        _loading = false;
      });

      _attempts++;
      if (confidence > 0.5 && isCorrectLetter) {
        _success = true;
        _correctCount++;
        _saveScore();

        // تحديث مصفوفة الأرقام المكتملة
        _completedNumbers[_currentNumberIndex] = true;
        _savecompletedNumbers();

        // زيادة عدد الإجابات الصحيحة المتتالية
        _consecutiveCorrect++;

        _outputs = [
          {
            "label": _labels[_currentNumberIndex],
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

        // اختيار رسالة تحفيزية عشوائية
        _correctMessages.shuffle();
        String feedbackMessage = _correctMessages.first;

        // إضافة تشجيع إضافي للإجابات الصحيحة المتتالية
        if (_consecutiveCorrect >= 3) {
          feedbackMessage +=
              " لديك $_consecutiveCorrect إجابات صحيحة متتالية!";
        }

        // نطق رسالة النجاح
        await _speakMessage(feedbackMessage);

        showDialog(
          context: context,
          barrierDismissible: false,
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
                    _moveToNextLetter(fromCompletion: true);
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
            "label": _labels[topResult["index"]],
            "confidence": confidence,
            "isCorrect": false,
            "message": incorrectMessage,
          }
        ];

        await _speakMessage(incorrectMessage);

        showDialog(
          context: context,
          barrierDismissible: true,
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
                      'الرقم  المطلوب: ${_labels[_currentNumberIndex]}',
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
                borderRadius: BorderRadius.circular(15),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'حاول مرة أخرى',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE67E22),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          points.clear();
                          _outputs = null;
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
      print('Error predicting drawing: $e');
      setState(() {
        _loading = false;
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
              'اختبار رسم الارقام ',
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
                        'التقدم: ${_currentNumberIndex + 1}/${_labels.length}',
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
                        ? (_currentNumberIndex + 1) / _labels.length
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
                    _labels.isNotEmpty && _currentNumberIndex < _labels.length
                        ? 'ارسم الرقم '
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
                      // إضافة إطار ظل للرقم  الحالي
                      Container(
                        width: 60,
                        height: 60,
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
                      // إضافة مؤشر رقم الرقم  ضمن اختبار الارقام
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
                              '${_currentNumberIndex + 1}',
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
                    // إزالة الدليل المرئي للرقم
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            points.add(details.localPosition);
                          });
                          // تشغيل صوت عند بدء الرسم
                          // _playDrawSound();
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
            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // إضافة زر للاستماع إلى توجيهات الرسم
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
                      // إضافة زر للمساعدة في الرسم
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

                  // إضافة ضبط سرعة النطق
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
                                        false; // إعادة تعيين حالة الرسم
                                  });
                                  // تشغيل صوت عند مسح اللوحة
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

  // دالة لبناء زر سرعة النطق
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

  // إظهار تعليمات استخدام الشاشة
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
                'اضغط على زر الاستماع لسماع الرقم  المطلوب رسمه'),
            _buildInstructionItem('استخدم الشاشة لرسم الرقم  كما سمعته'),
            _buildInstructionItem(
                'اضغط على زر المساعدة للحصول على تفاصيل حول كيفية رسم الرقم '),
            _buildInstructionItem(
                'استخدم أزرار ضبط سرعة النطق لتغيير سرعة نطق الارقام '),
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
