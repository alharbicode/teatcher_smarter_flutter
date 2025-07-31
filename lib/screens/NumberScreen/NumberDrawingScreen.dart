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
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override //مسح
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class NumberDrawingScreen extends StatefulWidget {
  const NumberDrawingScreen({super.key});

  @override
  _NumberDrawingScreenState createState() => _NumberDrawingScreenState();
}

class _NumberDrawingScreenState extends State<NumberDrawingScreen> {
  List<Offset?> points = [];
  List? _outputs;
  bool _loading = false;
  late Interpreter _interpreter;
  List<String> _labels = [];
  static const int inputSize = 244;
  int batchSize = 1;
  int _currentNumberIndex = 0;
  bool _success = false;
  late FlutterTts flutterTts;
  int _correctCount = 0;
  int _attempts = 0;
  List<bool> _completedNumbers = [];
  static const String _progressKey = 'drawingScreenNumberProgress';
  static const String _scoreKey = 'drawingScreenNumberScore';
  static const String _completedNumbersKey = 'drawingScreenCompletedNumbers';
  double _speechRate = 0.5;
  static const String _speechRateKey = 'drawingScreenNumberSpeechRate';
  bool _isDrawing = false;
  int _consecutiveCorrect = 0;
  bool _showTrace = false; // تضهار الاثر

  final List<String> _encouragementMessages = [
    "أحسنت! استمر في التقدم",
    "ممتاز! أنت تتعلم بسرعة",
    "رائع! انتقل إلى الرقم التالي",
    "جميل جداً! واصل التقدم",
    "ما شاء الله! أداء رائع",
    "أنت موهوب جداً!",
    "استمر هكذا، أنت تتحسن",
    "كتابة جميلة! أحسنت",
    "رائع! يمكنك أن تكون خطاطاً ماهراً!",
    "إبداع متميز! واصل الكتابة الجميلة",
    "تحسن ملحوظ! أنت تتقن الكتابة بسرعة",
  ];

  final List<String> _instructionMessages = [
    "ارسم الرقم",
    "حاول رسم الرقم",
    "اكتب الرقم",
    "دعنا نتعلم كتابة رقم",
  ];

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
          _speakInstructions();
          _completedNumbers = List.generate(_labels.length, (index) => false);
          _loadCompletedNumbers();
        }
      });
    });
    initTts();
  }

  Future<void> _loadCompletedNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList(_completedNumbersKey);
    if (completed != null) {
      setState(() {
        _completedNumbers = completed.map((e) => e == 'true').toList();
      });
    }
  }

  Future<void> _saveCompletedNumbers() async {
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

  void initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("ar-SA");
    flutterTts.setSpeechRate(_speechRate);
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);
  }

  Future<void> _saveSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_speechRateKey, _speechRate);
  }

  Future<void> _loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
    });
  }

  void _changeSpeechRate(double rate) {
    setState(() {
      _speechRate = rate;
    });
    flutterTts.setSpeechRate(rate);
    _saveSpeechRate();
  }

  Future<void> _speakInstructions() async {
    if (_labels.isEmpty) return;

    final random = Random();
    String instruction =
        _instructionMessages[random.nextInt(_instructionMessages.length)];
    await flutterTts.speak("$instruction ${_labels[_currentNumberIndex]}");
  }

  Future<void> _speakCurrentNumber() async {
    if (_labels.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      await flutterTts.speak(_labels[_currentNumberIndex]);
    }
  }

  Future<void> _speakNumberDetails() async {
    if (_labels.isNotEmpty && _currentNumberIndex < _labels.length) {
      String currentNumber = _labels[_currentNumberIndex];
      String detailMessage = _getNumberDetailMessage(currentNumber);

      await flutterTts.speak(detailMessage);
    }
  }

  String _getNumberDetailMessage(String number) {
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

    return numberDetails[number] ??
        'ارسم الرقم $number بعناية واهتمام. لاحظ شكله وحاول تقليده بدقة.';
  }

  Future<void> _speakMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak(message);
  }

  Future<void> _playDrawSound() async {
    if (!_isDrawing) {
      _isDrawing = true;
      await flutterTts.speak("ابدأ الرسم الآن");
    }
  }

  Future<void> _playClearSound() async {
    await flutterTts.speak("تم مسح اللوحة");
    _isDrawing = false;
  }

  String _getRandomEncouragement() {
    final random = Random();
    return _encouragementMessages[
        random.nextInt(_encouragementMessages.length)];
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/numbers_model.tflite');
      final labelData = await rootBundle.loadString('assets/labelsNum.txt');
      _labels = labelData.split('\n');

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
      var isCorrectNumber = topResult["index"] == _currentNumberIndex;
      var confidence = topResult["confidence"];

      setState(() {
        _loading = false;
      });

      _attempts++;
      if (confidence > 0.5 && isCorrectNumber) {
        _success = true;
        _correctCount++;
        _saveScore();

        // Actualizar consecutivos
        _consecutiveCorrect++;

        String stars = '';
        if (_attempts == 1) {
          stars = '⭐⭐⭐';
        } else if (_attempts == 2) {
          stars = '⭐⭐';
        } else {
          stars = '⭐';
        }

        var message = _getRandomEncouragement();
        _outputs = [
          {
            "label": _labels[_currentNumberIndex],
            "confidence": confidence,
            "isCorrect": true,
            "message": message,
          }
        ];

      
        String additionalMessage = "";
        if (_consecutiveCorrect >= 5) {
          additionalMessage = "! خمسة إجابات صحيحة متتالية! أنت عبقري";
        } else if (_consecutiveCorrect >= 3) {
          additionalMessage = "! ثلاثة إجابات صحيحة متتالية! رائع";
        }

        await _speakMessage(
            "$message! لقد رسمت رقم ${_labels[_currentNumberIndex]} بشكل صحيح $additionalMessage");

        showDialog(
          context: context,
          barrierDismissible: false,
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2ECC71).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'لقد رسمت رقم ${_labels[_currentNumberIndex]} بشكل صحيح',
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
                    Navigator.of(context).pop();
                    if (_currentNumberIndex < _labels.length - 1) {
                      _completedNumbers[_currentNumberIndex] = true;
                      _saveCompletedNumbers();
                      _currentNumberIndex++;
                      _saveProgress();
                      _speakInstructions();
                      setState(() {
                        points.clear();
                        _outputs = null;
                        _success = false;
                        _attempts = 0;
                      });
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تهانينا! 🎉'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset(
                                'assets/correct_animation.json',
                                height: 120,
                                repeat: true,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'لقد أكملت جميع الأرقام بنجاح! عدد الأرقام الصحيحة: $_correctCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C7D32),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  _currentNumberIndex = 0;
                                  _correctCount = 0;
                                  _consecutiveCorrect = 0;
                                  _completedNumbers = List.generate(
                                      _labels.length, (index) => false);
                                  _saveProgress();
                                  _saveCompletedNumbers();
                                  _saveScore();
                                  _speakInstructions();
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
        _success = false;
        _consecutiveCorrect = 0; // Reiniciar consecutivos en caso de error

        List<String> incorrectMessages = [
          "حاول مرة أخرى!",
          "لا بأس، يمكنك المحاولة مجدداً",
          "استمر في المحاولة، أنت تتحسن!",
          "كل محاولة تقربك من النجاح",
          "حاول مرة أخرى، أنت تستطيع!"
        ];

        var random = Random();
        var incorrectMessage =
            incorrectMessages[random.nextInt(incorrectMessages.length)];
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
              title: const Text('حاول مرة أخرى 💪'),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFB74D).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        incorrectMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
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
                      _outputs = null;
                    });
                  },
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

  void _moveToNextNumber() {
    setState(() {
      if (_currentNumberIndex < _labels.length - 1) {
        _currentNumberIndex++;
        _consecutiveCorrect++;
        _saveProgress();

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/correct_animation.json',
                  height: 120,
                  repeat: true,
                ),
                const SizedBox(height: 10),
                Text(
                  'لقد أكملت جميع الأرقام بنجاح! عدد الأرقام الصحيحة: $_correctCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C7D32),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentNumberIndex = 0;
                    _correctCount = 0;
                    _consecutiveCorrect = 0;
                    _completedNumbers =
                        List.generate(_labels.length, (index) => false);
                    _saveProgress();
                    _saveCompletedNumbers();
                    _saveScore();
                    _speakInstructions();
                  });
                },
                child: const Text('ابدأ من جديد'),
              ),
            ],
          ),
        );
      }
      points.clear();
      _outputs = null;
      _success = false;
      _attempts = 0;
    });
  }

  void _toggleTrace() {
    setState(() {
      _showTrace = !_showTrace;
    });

    if (_showTrace) {
      _speakMessage(
          "هذه طريقة رسم الرقم ${_labels[_currentNumberIndex]}. حاول تتبع الخطوط المنقطة بقلمك.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pen.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              'رسم الأرقام',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade100,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Center(
                        child: _labels.isNotEmpty
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/image_numbers/${_labels[_currentNumberIndex]}.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return Text(
                                        _labels[_currentNumberIndex],
                                        style: TextStyle(
                                          fontSize: orientation ==
                                                  Orientation.portrait
                                              ? screenWidth * 0.2
                                              : screenWidth * 0.15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      );
                                    },
                                  ),
                                  if (_showTrace)
                                    Image.asset(
                                      'assets/traces/${_labels[_currentNumberIndex]}_trace.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (BuildContext context,
                                          Object exception,
                                          StackTrace? stackTrace) {
                                        return Container(); // Si no existe la imagen, no mostramos nada
                                      },
                                    ),
                                ],
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    height: screenHeight * 0.4,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            points.add(details.localPosition);
                          });
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
                            _isDrawing = false;
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(points),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Primera fila de botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: points.isNotEmpty
                                ? () {
                                    setState(() {
                                      points.clear();
                                      _outputs = null;
                                      _isDrawing = false;
                                    });
                                    _playClearSound();
                                  }
                                : null,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 30,
                            ),
                            label: const Text('',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF08080),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            onPressed:
                                points.isNotEmpty ? predictDrawing : null,
                            icon: const Icon(Icons.check,
                                color: Colors.white, size: 30),
                            label: const Text('',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF90EE90),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
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
                            onPressed: _speakNumberDetails,
                            icon: const Icon(Icons.help_outline,
                                color: Colors.white, size: 30),
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
                            onPressed: _speakCurrentNumber,
                            icon: const Icon(Icons.volume_up,
                                color: Colors.white, size: 30),
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
                      const SizedBox(height: 12),
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

  @override
  void dispose() {
    _interpreter.close();
    flutterTts.stop();
    super.dispose();
  }
}
