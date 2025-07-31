import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';

class ResultDialog extends StatefulWidget {
  final bool isCorrect;
  final VoidCallback onClose;
  final String message;
  final VoidCallback? onDialogOpen;

  const ResultDialog({
    super.key,
    required this.isCorrect,
    required this.onClose,
    required this.message,
    this.onDialogOpen,
  });

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  
  // رسائل صوتية للإجابة الصحيحة
  final List<String> correctSounds = [
    "أحسنت! إجابة صحيحة",
    "ممتاز! أنت ذكي جداً",
    "رائع! استمر في التقدم",
    "صحيح! أنت تتعلم بسرعة",
    "إجابة صحيحة! أنا فخور بك",
  ];
  
  // رسائل صوتية للإجابة الخاطئة
  final List<String> incorrectSounds = [
    "حاول مرة أخرى، أنت تستطيع",
    "لا بأس، يمكنك المحاولة مجدداً",
    "غير صحيح، لكن استمر في المحاولة",
    "لم توفق هذه المرة، لكن لا تستسلم",
  ];

  @override
  void initState() {
    super.initState();
    _initializeFlutterTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // تشغيل الصوت عند ظهور الدايلوج
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onDialogOpen != null) {
        widget.onDialogOpen!();
      } else {
        // تشغيل الصوت تلقائيًا إذا لم يتم تمرير onDialogOpen
        _playResultSound();
      }
    });
    
    // بدء تشغيل الرسوم المتحركة
    _animationController.forward();
  }
  
  // إعداد إعدادات النطق
  Future<void> _initializeFlutterTts() async {
    await flutterTts.setLanguage('ar');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
    
    flutterTts.setErrorHandler((error) {
      setState(() {
        isSpeaking = false;
      });
      print("خطأ في النطق: $error");
    });
  }
  
  // دالة نطق النص
  Future<void> speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    }
    await flutterTts.speak(text);
  }
  
  // تشغيل صوت مناسب للنتيجة
  Future<void> _playResultSound() async {
    if (widget.isCorrect) {
      // تشغيل صوت النجاح مع تأخير قليل للتناسق مع الرسوم المتحركة
      await Future.delayed(const Duration(milliseconds: 500));
      await speak(correctSounds[Random().nextInt(correctSounds.length)]);
    } else {
      // تشغيل صوت الإجابة الخاطئة
      await Future.delayed(const Duration(milliseconds: 500));
      await speak(incorrectSounds[Random().nextInt(incorrectSounds.length)]);
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // صورة متحركة للصواب أو الخطأ
            Lottie.asset(
              widget.isCorrect
                  ? 'assets/correct_animation.json'
                  : 'assets/incorrect_animation.json',
              width: 150,
              height: 150,
              repeat: false,
              controller: _animationController,
            ),
            SizedBox(height: 20),
            // رسالة النتيجة
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isCorrect ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // زر إعادة الاستماع للصوت
            IconButton(
              onPressed: isSpeaking ? null : _playResultSound,
              icon: Icon(
                isSpeaking ? Icons.volume_up : Icons.refresh,
                color: widget.isCorrect ? Colors.green : Colors.red,
                size: 30,
              ),
              tooltip: 'إعادة الاستماع',
            ),
            SizedBox(height: 10),
            // زر الإغلاق
            ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isCorrect ? Colors.green : Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
