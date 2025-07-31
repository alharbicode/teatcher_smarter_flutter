import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';
import 'package:teatcher_smarter/providers/word_progress_provider.dart';
import 'package:teatcher_smarter/providers/word_provider.dart';
import 'package:teatcher_smarter/screens/WordScreen/word_hearing_screen.dart';
import 'package:teatcher_smarter/screens/WordScreen/word_test_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'home_game.dart';

class WordsLearningScreen extends StatefulWidget {
  const WordsLearningScreen({super.key}); 

  @override
  _WordsLearningScreenState createState() =>
      _WordsLearningScreenState(); 
}

class _WordsLearningScreenState extends State<WordsLearningScreen>
    with SingleTickerProviderStateMixin {
  // حالة الشاشة مع تحكم في التبويبات
  late TabController _tabController; 
  late FlutterTts flutterTts; 
  bool isSpeaking = false; 

  @override
  void initState() {
    super.initState();
    _initializeFlutterTts(); 
    _tabController =
        TabController(length: 3, vsync: this); // إنشاء متحكم بثلاث تبويبات
    _tabController.addListener(() {
      setState(() {}); // إعادة بناء الواجهة عند تغيير التبويب
      _speakWelcomeMessage(
          _tabController.index); 
    });

    // تحميل البيانات بعد إنشاء الـ TabController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordProgressProvider>(context, listen: false)
          .loadAllProgress(); 
      Provider.of<WordsProvider>(context, listen: false)
          .loadLocalData(); 
      _speakWelcomeMessage(0); // الترحيب الأولي عند فتح الشاشة
    });
  }

  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts(); 
    await flutterTts.setLanguage("ar"); 
    await flutterTts.setPitch(1.0); 
    await flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      // معالج عند اكتمال النطق
      setState(() {
        isSpeaking = false; 
      });
    });
  }

  Future<void> speak(String text) async {
   
    if (isSpeaking) {
      await flutterTts.stop(); // إيقاف النطق إذا كان جارياً
    }

    setState(() {
      isSpeaking = true; 
    });

    await flutterTts.speak(text); // بدء النطق
  }

  void _speakWelcomeMessage(int tabIndex) {
    // رسالة الترحيب حسب التبويب
    String welcomeMessage = '';
    switch (tabIndex) { 
      case 0:
        welcomeMessage = 'مرحباً بك في مرحلة تعلم الكلمات، في المستوى المبتدئ';
        break;
      case 1:
        welcomeMessage = 'مرحباً بك في مرحلة تعلم الكلمات، في المستوى المتوسط';
        break;
      case 2:
        welcomeMessage = 'مرحباً بك في مرحلة تعلم الكلمات، في المستوى المتقدم';
        break;
    }
    speak(welcomeMessage);
  }

  @override
  void dispose() {
    // تنظيف الموارد عند إغلاق الشاشة
    flutterTts.stop(); 
    _tabController.dispose(); // التخلص من متحكم التبويبات
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
 
    return Scaffold(
      appBar: AppBar(
       
        elevation: 0,
        backgroundColor: Colors.grey[200],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('تعلم الكلمات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                )),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: TabBar(
            // شريط التبويبات
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.1),
            ),
            splashBorderRadius: BorderRadius.circular(10),
            tabs: [
             
              SizedBox(
           
                height: 70,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) => Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green[700]?.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.star_border,
                            color: _tabController.index == 0
                                ? Colors.green[700]
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مبتدئ',
                          style: TextStyle(
                            color: _tabController.index == 0
                                ? Colors.green[700]
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
            
                height: 70,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) => Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange[700]?.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.star_half,
                            color: _tabController.index == 1
                                ? Colors.orange[700]
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'متوسط',
                          style: TextStyle(
                            color: _tabController.index == 1
                                ? Colors.orange[700]
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
            
                height: 70,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, child) => Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red[700]?.withOpacity(0.2),
                          ),
                          child: Icon(
                            Icons.star,
                            color: _tabController.index == 2
                                ? Colors.red[700]
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'متقدم',
                          style: TextStyle(
                            color: _tabController.index == 2
                                ? Colors.red[700]
                                : Colors.grey[400],
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
      body: Stack(children: [
        // جسم الشاشة
        TabBarView(
        
          controller: _tabController,
          children: [
            _buildLevelContent(context, level: 0, title: 'مستوى مبتدئ'),
            _buildLevelContent(context, level: 1, title: 'مستوى متوسط'),
            _buildLevelContent(context, level: 2, title: 'مستوى متقدم'),
          ],
        ),
        CustomPositionedElements.starIconTopRight(),
        CustomPositionedElements.taaIconTopRight(),
        CustomPositionedElements.khaIconRightMiddle(),
        CustomPositionedElements.haaIconBottomRight(),
        CustomPositionedElements.fourIconTopLeft(),
        CustomPositionedElements.dashIconTopLeft(),
        CustomPositionedElements.seenIconMiddleLeft(),
        CustomPositionedElements.noonIconBottomLeft(),
        CustomPositionedElements.starIconBottomLeft(),
      ]),
    );
  }

  Widget _buildLevelContent(BuildContext context,
      {required int level, required String title}) {
    // بناء محتوى كل مستوى
    return Consumer2<WordsProvider, WordProgressProvider>(
      builder: (context, wordsProvider, progressProvider, child) {
        // حساب إحصائيات المستوى
        final wordsInLevel =
            wordsProvider.items.where((w) => w.level == level).toList();
        int masteredWords = 0;
        for (var word in wordsInLevel) {
          if (progressProvider.isWordMastered(word.id)) {
            masteredWords++;
          }
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // خلفية متدرجة
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade100,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 10),
                       
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'إحصائيات المستوى',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'عدد الكلمات: ${wordsInLevel.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                // شريط التقدم
                                value: wordsInLevel.isEmpty
                                    ? 0
                                    : masteredWords / wordsInLevel.length,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  level == 0
                                      ? Colors.green
                                      : level == 1
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildOptionCard(
                          
                          context,
                          icon: "assets/icons/pronounce.png",
                          title: 'سماع الكلمات',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WordHearingScreen(level: level),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildOptionCard(
                         
                          context,
                          icon: "assets/icons/word_icons.png",
                          title: 'تركيب الكلمات',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WordScreen(level: level),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildOptionCard(
                      
                          context,
                          icon: "assets/icons/testing.png",
                          title: 'اختبار',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WordTestScreen(level: level),
                              ),
                            );
                          },
                        ),
                        SizedBox(
                            // مساحة فارغة في الأسفل
                            height: constraints.maxHeight * 0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
 
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.grey[200],
        child: InkWell(
          onTap: onTap, // عند النقر
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  // أيقونة الخيار
                  icon,
                  fit: BoxFit.contain,
                  height: 60,
                ),
                const SizedBox(width: 10),
                Text(
                  // عنوان الخيار
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
