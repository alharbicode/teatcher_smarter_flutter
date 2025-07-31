// استيراد المكتبات المطلوبة
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/math_model.dart';
import 'package:flutter_tts/flutter_tts.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 

import '../../providers/math_provider.dart'; 


class MathScreen extends StatefulWidget {
  final int level;
  const MathScreen({super.key, required this.level});

  @override
  _MathScreenState createState() => _MathScreenState();
}


class _MathScreenState extends State<MathScreen> {
  late FlutterTts flutterTts; 
  final TextEditingController _answerController = TextEditingController(); // تحكم في حقل الإجابة
  bool isProcessing = false; 
  bool _isSpeakingEnabled = true; // تفعيل/تعطيل الصوت
  double _speechRate = 0.5; 


  static const String _speechRateKey = 'math_speech_rate';//معدل
  static const String _speakingEnabledKey = 'math_speaking_enabled';


  List<String> correctMessages = [
    "أحسنت!",
    "إجابة صحيحة!",
    "ممتاز!",
    "عمل رائع!",
    "تابع هكذا!"
  ];


  List<String> incorrectMessages = [
    "حاول مرة أخرى.",
    "إجابة غير صحيحة.",
    "لا بأس، استمر في المحاولة.",
    "قريب جدًا!",
    "أنت تستطيع!"
  ];

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    flutterTts.awaitSpeakCompletion(true); 
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تصفية المسائل حسب المستوى بعد بناء الواجهة
      context.read<MathProvider>().filterByLevel(widget.level);
    });
  }


  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
      _isSpeakingEnabled = prefs.getBool(_speakingEnabledKey) ?? true;
    });
    await flutterTts.setSpeechRate(_speechRate);
  }


  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, _speechRate);
    await prefs.setBool(_speakingEnabledKey, _isSpeakingEnabled);
  }

  // دالة التحدث بالنص
  Future<void> speak(String text) async {
    if (!_isSpeakingEnabled) return;
    await flutterTts.setLanguage("ar-SA"); 
    await flutterTts.setSpeechRate(_speechRate);//معدل الكلام
    await flutterTts.speak(text);
    await flutterTts.awaitSpeakCompletion(true);
  }

  // تبديل تفعيل/تعطيل الصوت
  void _toggleSpeaking() {
    setState(() {
      _isSpeakingEnabled = !_isSpeakingEnabled;
    });
    _saveSettings();
  }

  
  void _changeSpeechRate(double rate) {
    setState(() {
      _speechRate = rate;
    });
    flutterTts.setSpeechRate(_speechRate); // تطبيق السرعة الجديدة
    _saveSettings();
  }

  // عرض نافذة اختيار سرعة الكلام
  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر سرعة النطق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption('بطيء', 0.3),
            _buildSpeedOption('متوسط', 0.5),
            _buildSpeedOption('سريع', 0.7),
          ],
        ),
      ),
    );
  }

  // بناء خيار سرعة الصوت
  Widget _buildSpeedOption(String label, double rate) {
    return ListTile(
      title: Text(label),
      trailing: _speechRate == rate ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        _changeSpeechRate(rate);
        Navigator.pop(context);
      },
    );
  }

  // الحصول على رمز العملية الحسابية
  String getOperationSymbol(Operation operation) {
    switch (operation) {
      case Operation.addition:
        return '+';
      case Operation.subtraction:
        return '-';
      case Operation.multiplication:
        return '×';
      case Operation.division:
        return '÷';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    flutterTts.stop(); 
    _answerController.dispose(); // التخلص من المتحكم في حقل الإجابة
    super.dispose();
  }

  // عرض نافذة النتائج
  void _showScoreDialog(BuildContext context, MathModel model) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'ملخص الأداء',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildScoreRow('الإجابات الصحيحة:',
                model.correctAttempts.toString(), Colors.green),
            const SizedBox(height: 8),
            _buildScoreRow('الإجابات الخاطئة:',
                model.incorrectAttempts.toString(), Colors.red),
            const SizedBox(height: 8),
            _buildScoreRow(
                'النقاط الإجمالية:', model.userScore.toString(), Colors.orange),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('حسناً'),
            ),
          ),
        ],
      ),
    );
  }

  // بناء صف النتيجة
  Widget _buildScoreRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mathModel = Provider.of<MathModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'تمارين ${_getOperationName(mathModel.currentOperation)}',
          style: const TextStyle(color: Colors.orange),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر تشغيل/إيقاف الصوت
          IconButton(
            icon: Icon(_isSpeakingEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSpeaking,
            tooltip: 'تشغيل/إيقاف النطق',
          ),
          // زر ضبط سرعة الصوت
          IconButton(
            icon: const Icon(Icons.speed),
            onPressed: _showSpeedDialog,
            tooltip: 'ضبط سرعة النطق',
          ),
          // زر عرض النتائج
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.orange),
            onPressed: () => _showScoreDialog(context, mathModel),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: mathModel.currentOperation == null
          ? buildOperationSelection(context, mathModel) // عرض واجهة اختيار العملية
          : Consumer<MathProvider>(
              builder: (context, mathProvider, child) {
                if (mathProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentMath = mathProvider.currentMath;
                if (currentMath == null) {
                  return const Center(child: Text('لا توجد أمثلة متاحة'));
                }

                return AbsorbPointer(
                  absorbing: isProcessing,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // بطاقة عرض المسألة
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const Text(
                                  'حل المسألة التالية:',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${currentMath.num1} ${getOperationSymbol(mathModel.currentOperation!)} ${currentMath.num2} = ؟',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // زر الاستماع إلى المسألة
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  String operationName = _getOperationName(
                                      mathModel.currentOperation);
                                  String problemText =
                                      '${currentMath.num1} $operationName ${currentMath.num2}';
                                  await speak('ما ناتج $problemText؟');
                                },
                                icon: const Icon(Icons.volume_up),
                                label: const Text('استمع إلى المسألة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // حقل إدخال الإجابة
                        TextField(
                          controller: _answerController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            labelText: 'اكتب إجابتك هنا',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // زر التحقق من الإجابة
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  setState(() {
                                    isProcessing = true;
                                  });
                                  String userInput =
                                      _answerController.text.trim();
                                  if (userInput.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('⚠️ يرجى إدخال الإجابة')),
                                    );
                                    setState(() {
                                      isProcessing = false;
                                    });
                                    return;
                                  }

                                  int answer = int.parse(userInput);
                                  bool isCorrect = false;

                                  // التحقق من صحة الإجابة حسب نوع العملية
                                  switch (mathModel.currentOperation) {
                                    case Operation.addition:
                                      isCorrect = answer ==
                                          currentMath.num1 + currentMath.num2;
                                      break;
                                    case Operation.subtraction:
                                      isCorrect = answer ==
                                          currentMath.num1 - currentMath.num2;
                                      break;
                                    case Operation.multiplication:
                                      isCorrect = answer ==
                                          currentMath.num1 * currentMath.num2;
                                      break;
                                    case Operation.division:
                                      isCorrect = answer ==
                                          currentMath.num1 ~/ currentMath.num2;
                                      break;
                                    default:
                                      break;
                                  }

                                  if (isCorrect) {
                                    String feedback =
                                        (correctMessages..shuffle()).first;
                                    await speak(feedback);
                                    _answerController.clear();
                                    mathProvider.nextItem();
                                    mathModel.incrementScore();
                                  } else {
                                    String feedback =
                                        (incorrectMessages..shuffle()).first;
                                    await speak(feedback);
                                    mathModel.decrementScore();
                                  }
                                  setState(() {
                                    isProcessing = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'تحقق من الإجابة',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // عرض النقاط
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stars, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'النقاط: ${mathModel.userScore}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // زر تغيير نوع التمرين
                        OutlinedButton.icon(
                          onPressed: () {
                            mathModel.resetOperation();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('تغيير نوع التمرين'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // الحصول على اسم العملية الحسابية
  String _getOperationName(Operation? operation) {
    switch (operation) {
      case Operation.addition:
        return 'الجمع';
      case Operation.subtraction:
        return 'الطرح';
      case Operation.multiplication:
        return 'الضرب';
      case Operation.division:
        return 'القسمة';
      default:
        return 'الحساب';
    }
  }

  // بناء واجهة اختيار العملية الحسابية
  Widget buildOperationSelection(BuildContext context, MathModel mathModel) {
    final mathProvider = Provider.of<MathProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'اختر نوع العملية التي تريد التدرب عليها:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // عرض ملخص التقدم
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ملخص تقدمك:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressRow(
                    'الجمع',
                    mathProvider.items
                        .where((item) => item.arithmeticOperations == 0)
                        .length,
                    Colors.green,
                  ),
                  _buildProgressRow(
                    'الطرح',
                    mathProvider.items
                        .where((item) => item.arithmeticOperations == 1)
                        .length,
                    Colors.red,
                  ),
                  _buildProgressRow(
                    'الضرب',
                    mathProvider.items
                        .where((item) => item.arithmeticOperations == 2)
                        .length,
                    Colors.blue,
                  ),
                  _buildProgressRow(
                    'القسمة',
                    mathProvider.items
                        .where((item) => item.arithmeticOperations == 3)
                        .length,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                // بطاقة عملية الجمع
                buildOperationCard(
                  context,
                  label: 'الجمع',
                  icon: Icons.add,
                  color: Colors.green,
                  count: mathProvider.items
                      .where((item) =>
                          item.arithmeticOperations == 0 &&
                          item.level == widget.level)
                      .length,
                  onTap: () {
                    mathModel.setOperation(Operation.addition);
                    mathProvider.filterByOperationAndLevel(
                        Operation.addition, widget.level);
                  },
                ),
                // بطاقة عملية الطرح
                buildOperationCard(
                  context,
                  label: 'الطرح',
                  icon: Icons.remove,
                  color: Colors.red,
                  count: mathProvider.items
                      .where((item) =>
                          item.arithmeticOperations == 1 &&
                          item.level == widget.level)
                      .length,
                  onTap: () {
                    mathModel.setOperation(Operation.subtraction);
                    mathProvider.filterByOperationAndLevel(
                        Operation.subtraction, widget.level);
                  },
                ),
                // بطاقة عملية الضرب
                buildOperationCard(
                  context,
                  label: 'الضرب',
                  icon: Icons.close,
                  color: Colors.blue,
                  count: mathProvider.items
                      .where((item) =>
                          item.arithmeticOperations == 2 &&
                          item.level == widget.level)
                      .length,
                  onTap: () {
                    mathModel.setOperation(Operation.multiplication);
                    mathProvider.filterByOperationAndLevel(
                        Operation.multiplication, widget.level);
                  },
                ),
                // بطاقة عملية القسمة
                buildOperationCard(
                  context,
                  label: 'القسمة',
                  icon: Icons.horizontal_split,
                  color: Colors.orange,
                  count: mathProvider.items
                      .where((item) =>
                          item.arithmeticOperations == 3 &&
                          item.level == widget.level)
                      .length,
                  onTap: () {
                    mathModel.setOperation(Operation.division);
                    mathProvider.filterByOperationAndLevel(
                        Operation.division, widget.level);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء صف التقدم
  Widget _buildProgressRow(String operation, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                operation,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count مثال',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء بطاقة العملية الحسابية
  Widget buildOperationCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int count,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count مثال متوفر',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}