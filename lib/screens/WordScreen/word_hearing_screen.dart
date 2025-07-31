import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/custom_app_bar.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';

// تعريف كلاس WordHearingScreen الذي يمثل شاشة اختبار الاستماع للكلمات وهو StatefulWidget
class WordHearingScreen extends StatefulWidget {
  final int level; 

  const WordHearingScreen(
      {super.key, required this.level}); // كونستركتور يأخذ مستوى الصعوبة

  @override
  State<WordHearingScreen> createState() =>
      _WordHearingScreenState(); 
}


class _WordHearingScreenState extends State<WordHearingScreen> {
  late FlutterTts flutterTts; 
  bool isSpeaking = false; 
  int currentIndex = 0; 
  final bool _isInit = false; 
  double speechRate = 0.5;
  double volume = 1.0;
  bool useLetterByLetterMode = false; 

  @override
  void initState() {
    super.initState();
    _initializeFlutterTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakWelcomeMessage(); 
      _initializeWords();
    });
  }


  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts(); 
    await flutterTts.setLanguage("ar-SA"); 
    await flutterTts.setPitch(1.0); // درجة الصوت الافتراضية
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.setVolume(volume);
    flutterTts.setCompletionHandler(() {
   
      setState(() {
        isSpeaking = false; 
      });
    });
  }

 
  Future<void> speak(String text) async {
    if (isSpeaking) {

      await flutterTts.stop();
    }

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(text); // بدء النطق بالنص المطلوب
  }

  
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
        'مرحباً بك في اختبار الاستماع للكلمات في المستوى $levelName'); 
  }


  Future<void> _initializeWords() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
      await wordsProvider.loadLocalData();
      if (wordsProvider.items.isEmpty) {
        // إذا لم توجد بيانات
        await wordsProvider.fetchAndSyncData(); // جلب البيانات من المصدر
      }
      if (mounted && wordsProvider.items.isNotEmpty) {
        // إذا كانت الشاشة موجودة وهناك كلمات
        await speakCurrentWord(); 
      }
    });
  }

  
  Future<void> speakCurrentWord() async {
    if (!mounted) return; // إذا كانت الشاشة غير موجودة، خروج

    final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    final levelWords = wordsProvider.items
        .where(
            (word) => word.level == widget.level) // تصفية الكلمات حسب المستوى
        .toList();

    if (levelWords.isEmpty || currentIndex >= levelWords.length)
      return; // إذا لا توجد كلمات

    setState(() {
      isSpeaking = true;
    });

    String wordText = levelWords[currentIndex].text; // نص الكلمة الحالية

    if (useLetterByLetterMode) {
      
      await speakLetterByLetter(wordText); 
    } else {
      // الوضع العادي
      await flutterTts.speak("الكلمة هي $wordText"); // نطق الكلمة كاملة
      await flutterTts.awaitSpeakCompletion(true); 
    }

    if (mounted) {
      setState(() {
        isSpeaking = false; 
      });
    }
  }

  
  Future<void> speakLetterByLetter(String word) async {
  
    await flutterTts.speak("الكلمة هي $word");
    await flutterTts.awaitSpeakCompletion(true);

    // إضافة فاصل زمني قصير
    await Future.delayed(const Duration(milliseconds: 500));

   
    await flutterTts.speak("حروف الكلمة هي");
    await flutterTts.awaitSpeakCompletion(true);

    // نطق كل حرف على حدة
    for (int i = 0; i < word.length; i++) {
      String letter = word[i];
      await flutterTts.speak(letter);
      await flutterTts.awaitSpeakCompletion(true);
      await Future.delayed(
          const Duration(milliseconds: 300)); // تأخير بين الحروف
    }

    
    await Future.delayed(const Duration(milliseconds: 500));
    await flutterTts.speak("الكلمة كاملة هي $word");
    await flutterTts.awaitSpeakCompletion(true);
  }

 
  Future<void> changeSpeechRate(double newRate) async {
    setState(() {
      speechRate = newRate; // تحديث سرعة النطق
    });
    await flutterTts.setSpeechRate(newRate); 

   
    String speedMessage = newRate <= 0.3
        ? "تم ضبط سرعة النطق على بطيء"
        : newRate >= 0.7
            ? "تم ضبط سرعة النطق على سريع"
            : "تم ضبط سرعة النطق على متوسط";

    await flutterTts.speak(speedMessage);
    await flutterTts.awaitSpeakCompletion(true);

    // إعادة نطق الكلمة الحالية بالسرعة الجديدة
    if (mounted) {
      speakCurrentWord();
    }
  }


  Future<void> changeVolume(double newVolume) async {
    setState(() {
      volume = newVolume; 
    });
    await flutterTts.setVolume(newVolume); // تطبيق مستوى الصوت الجديد
  }

  
  void previousWord() {
    setState(() {
      if (currentIndex > 0) {
        // إذا لم نكن في أول كلمة
        currentIndex--; // تقليل الفهرس
        speakCurrentWord(); // نطق الكلمة الجديدة
      }
    });
  }

 
  void nextWord() {
    final wordsProvider = Provider.of<WordsProvider>(context, listen: false);
    final levelWords = wordsProvider.items
        .where(
            (word) => word.level == widget.level) // تصفية الكلمات حسب المستوى
        .toList();

    setState(() {
      if (currentIndex < levelWords.length - 1) {
       
        currentIndex++; 
        speakCurrentWord(); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'استماع الكلمات'),
      body: Consumer<WordsProvider>(
        builder: (context, wordsProvider, child) {
          final levelWords = wordsProvider.items
              .where((word) => word.level == widget.level)
              .toList();

          if (wordsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (levelWords.isEmpty) {
            return const Center(
                child: Text('لا توجد كلمات متاحة لهذا المستوى'));
          }

          final currentWord = levelWords[currentIndex];
          final wordImage = currentWord.image != null
              ? base64Decode(currentWord.image)
              : null;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade100,
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'الكلمة ${currentIndex + 1} من ${levelWords.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (wordImage != null)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.memory(
                          wordImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),

                  // Word text
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      currentWord.text,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          
                            _buildControlButton(
                              icon: useLetterByLetterMode
                                  ? Icons.sort_by_alpha
                                  : Icons.text_fields,
                              label: useLetterByLetterMode
                                  ? 'حرف بحرف'
                                  : 'كلمة كاملة',
                              onPressed: () {
                                setState(() {
                                  useLetterByLetterMode =
                                      !useLetterByLetterMode;
                                });
                              },
                              color: useLetterByLetterMode
                                  ? Colors.purple
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 15),

                            // زر نطق بطيء
                            _buildControlButton(
                              icon: Icons.speed,
                              label: 'بطيء',
                              onPressed: () => changeSpeechRate(0.3),
                              color: speechRate <= 0.3
                                  ? Colors.teal
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 15),

                         
                            _buildControlButton(
                              icon: Icons.speed,
                              label: 'عادي',
                              onPressed: () => changeSpeechRate(0.5),
                              color: speechRate > 0.3 && speechRate < 0.7
                                  ? Colors.teal
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 15),

                          
                            _buildControlButton(
                              icon: Icons.speed,
                              label: 'سريع',
                              onPressed: () => changeSpeechRate(0.7),
                              color: speechRate >= 0.7
                                  ? Colors.teal
                                  : Colors.grey.shade600,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // شريط تحكم بمستوى الصوت
                        Row(
                          children: [
                            const Icon(Icons.volume_down, color: Colors.blue),
                            Expanded(
                              child: Slider(
                                value: volume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                activeColor: Colors.blue,
                                inactiveColor: Colors.blue.withOpacity(0.3),
                                onChanged: (value) {
                                  changeVolume(value);
                                },
                              ),
                            ),
                            const Icon(Icons.volume_up, color: Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // زر التنقل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavigationButton(
                        icon: Icons.arrow_back_ios,
                        onPressed: currentIndex > 0 ? previousWord : null,
                      ),
                      const SizedBox(width: 20),
                      _buildSpeakButton(
                        isSpeaking: isSpeaking,
                        onPressed: isSpeaking ? null : () => speakCurrentWord(),
                      ),
                      const SizedBox(width: 20),
                      _buildNavigationButton(
                        icon: Icons.arrow_forward_ios,
                        onPressed: currentIndex < levelWords.length - 1
                            ? nextWord
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// دالة لبناء زر التنقل (السابق/التالي)
  Widget _buildNavigationButton({
    required IconData icon, 
    VoidCallback? onPressed, // دالة الضغط على الزر (يمكن أن تكون null)
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null
            ? Colors.blue
            : Colors
                .grey.shade300, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3), 
                  blurRadius: 8, 
                  offset: const Offset(0, 4), 
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white), 
        onPressed: onPressed, 
        iconSize: 30, 
        padding: const EdgeInsets.all(12), 
      ),
    );
  }

  // دالة لبناء زر التكلم/الإيقاف
  Widget _buildSpeakButton({
    required bool isSpeaking, 
    VoidCallback? onPressed, 
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null
            ? Colors.grey.shade100
            : Colors.blue.shade100, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: onPressed != null 
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8, 
                  offset: const Offset(0, 6), 
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(
          isSpeaking
              ? Icons.volume_up
              : Icons.volume_up_outlined, // تغيير الأيقونة حسب حالة النطق
          color: Colors.blue, 
        ),
        onPressed: onPressed, 
        iconSize: 35,
        padding: const EdgeInsets.all(12), 
      ),
    );
  }

  // دالة لبناء أزرار التحكم (مثل تغيير السرعة، مستوى الصوت...)
  Widget _buildControlButton({
    required IconData icon, 
    required String label, // نص يظهر تحت الأيقونة
    required VoidCallback onPressed, 
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3), 
            blurRadius: 5,
            offset: const Offset(0, 2), 
          ),
        ],
      ),
      child: InkWell(
        // يجعل الزر قابل للضغط مع تأثير رقيق
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10), // زوايا دائرية لتأثير الضغط
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 6), // حواف داخلية
          child: Column(
            mainAxisSize: MainAxisSize.min, // عمود بأقل مساحة ممكنة
            children: [
              Icon(icon, color: color, size: 22), // عرض الأيقونة
              const SizedBox(height: 4), // مسافة بين الأيقونة والنص
              Text(
                label, // النص تحت الأيقونة
                style: TextStyle(
                  color: color, 
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
    flutterTts.stop(); // إيقاف النطق عند إغلاق الشاشة
    super.dispose(); 
  }
}
