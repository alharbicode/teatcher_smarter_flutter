
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_themes/app_colors.dart';
import '../../custom_widgets/custom_app_bar.dart';
import '../../custom_widgets/CustomPositionedElements.dart';
import 'operation_examples_screen.dart';

class MathTeachingScreen extends StatefulWidget {
  final int level; // مستوى الصعوبة (0: مبتدئ، 1: متوسط، 2: متقدم)
  const MathTeachingScreen({super.key, required this.level});

  @override
  _MathTeachingScreenState createState() => _MathTeachingScreenState();
}


class _MathTeachingScreenState extends State<MathTeachingScreen> {
  late FlutterTts flutterTts; 
  double speechRate = 0.5; 
  bool audioEnabled = true; 
  bool isProcessing = false; 

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts(); 
    _loadPreferences(); // تحميل التفضيلات المحفوظة
    _initTts(); // تهيئة إعدادات محول النص إلى كلام

    // تشغيل رسالة الترحيب بعد تحميل الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playWelcomeMessage();
    });
  }

 
  Future<void> _playWelcomeMessage() async {
    if (!audioEnabled) return; // الخروج إذا كان الصوت معطلاً

    String welcomeMessage = '';
    switch (widget.level) {
      case 0:
        welcomeMessage = 'مرحباً بك في تعلم الحساب للمستوى المبتدئ';
        break;
      case 1:
        welcomeMessage = 'مرحباً بك في تعلم الحساب للمستوى المتوسط';
        break;
      case 2:
        welcomeMessage = 'مرحباً بك في تعلم الحساب للمستوى المتقدم';
        break;
      default:
        welcomeMessage = 'مرحباً بك في تعلم الحساب';
    }

    await _speak(welcomeMessage); 
  }

  // دالة تحميل التفضيلات المحفوظة
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      speechRate = prefs.getDouble('math_speech_rate') ?? 0.5;
      audioEnabled = prefs.getBool('math_audio_enabled') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('math_speech_rate', speechRate);
    await prefs.setBool('math_audio_enabled', audioEnabled);
  }

  // دالة تهيئة إعدادات محول النص إلى كلام
  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA"); 
    await flutterTts.setSpeechRate(speechRate); 
    await flutterTts.setPitch(1.0); // تعيين درجة الصوت

    // معالج انتهاء الكلام
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isProcessing = false; 
        });
      }
    });
  }

 
  Future<void> _speak(String text) async {
    if (!audioEnabled) return; 

    setState(() {
      isProcessing = true; 
    });
    await flutterTts.speak(text); // نطق النص
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'الحساب',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
       
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // أزرار العمليات الحسابية
                  _buildOperationButton(
                    context: context,
                    label: 'الجمع',
                    symbol: '+',
                    operationType: 0,
                  ),
                  const SizedBox(height: 16),
                  _buildOperationButton(
                    context: context,
                    label: 'الطرح',
                    symbol: '-',
                    operationType: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildOperationButton(
                    context: context,
                    label: 'الضرب',
                    symbol: '×',
                    operationType: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildOperationButton(
                    context: context,
                    label: 'القسمة',
                    symbol: '÷',
                    operationType: 3,
                  ),
                ],
              ),
            ),
          ),
          
          CustomPositionedElements.starIconTopRight(),
          CustomPositionedElements.fourIconTopLeft(),
          CustomPositionedElements.dashIconTopLeft(),
          CustomPositionedElements.seenIconMiddleLeft(),
          CustomPositionedElements.noonIconBottomLeft(),
          CustomPositionedElements.starIconBottomLeft(),

          // مؤشر التحميل أثناء معالجة الصوت
          if (isProcessing)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('جاري النطق...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // دالة بناء زر سرعة الكلام
  Widget _buildSpeedButton(String label, double rate, bool isActive) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          speechRate = rate; // تحديث سرعة الكلام
        });
        flutterTts.setSpeechRate(speechRate); // تطبيق السرعة الجديدة
        _savePreferences();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.orange : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: isActive ? 4 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label),
    );
  }

  // دالة وصف العمليات الحسابية
  Future<void> _describeOperation(String label) async {
    String description = '';
    switch (label) {
      case 'الجمع':
        description = 'عملية الجمع هي دمج عددين أو أكثر للحصول على مجموعهما';
        break;
      case 'الطرح':
        description = 'عملية الطرح هي إيجاد الفرق بين عددين';
        break;
      case 'الضرب':
        description = 'عملية الضرب هي جمع العدد نفسه عدة مرات';
        break;
      case 'القسمة':
        description = 'عملية القسمة هي توزيع عدد على مجموعات متساوية';
        break;
    }
    await _speak(description); // نطق الوصف
  }

  // دالة بناء زر العملية الحسابية
  Widget _buildOperationButton({
    required BuildContext context,
    required String label,
    required String symbol,
    required int operationType,
  }) {

    Color operationColor;
    IconData operationIcon;

    switch (operationType) {
      case 0: // الجمع
        operationColor = Colors.blue;
        operationIcon = Icons.add_circle_outline;
        break;
      case 1: // الطرح
        operationColor = Colors.red;
        operationIcon = Icons.remove_circle_outline;
        break;
      case 2: // الضرب
        operationColor = Colors.green;
        operationIcon = Icons.close;
        break;
      case 3: // القسمة
        operationColor = Colors.purple;
        operationIcon = Icons.diversity_1_outlined;
        break;
      default:
        operationColor = AppColors.accentColor;
        operationIcon = Icons.calculate;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return InkWell(
          onTap: () {
            // تشغيل اهتزاز عند النقر
            HapticFeedback.mediumImpact();

            // وصف العملية قبل الانتقال للشاشة التالية
            _describeOperation(label).then((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OperationExamplesScreen(
                    operationType: operationType,
                    operationLabel: label,
                    level: widget.level,
                  ),
                ),
              );
            });
          },
          onHover: (isHovering) {
            setState(() {}); // إعادة البناء عند التمرير
          },
          child: Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[200]!,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: operationColor.withOpacity(0.3),
                ),
              ],
              border: Border.all(
                color: operationColor.withOpacity(0.5),
              ),
            ),
            child: Stack(
              children: [
                // العناصر الزخرفية للزر
                Positioned(
                  right: 15,
                  top: 15,
                  child: Icon(
                    operationIcon,
                    color: operationColor.withOpacity(0.3),
                    size: 35,
                  ),
                ),
                Positioned(
                  left: 15,
                  bottom: 15,
                  child: Icon(
                    Icons.calculate,
                    color: operationColor.withOpacity(0.2),
                    size: 25,
                  ),
                ),
                // المحتوى الرئيسي للزر
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        operationIcon,
                        color: operationColor,
                        size: 30,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: operationColor.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: operationColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}