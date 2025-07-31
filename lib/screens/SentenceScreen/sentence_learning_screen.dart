import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';
import 'package:teatcher_smarter/providers/sentence_progress_provider.dart';
import 'package:teatcher_smarter/providers/sentence_provider.dart';
import 'package:teatcher_smarter/screens/SentenceScreen/sentence_screen.dart';
import 'package:teatcher_smarter/screens/SentenceScreen/sentence_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SentenceLearningScreen extends StatefulWidget {
  const SentenceLearningScreen({super.key});

  @override
  _SentenceLearningScreenState createState() => _SentenceLearningScreenState();
}

class _SentenceLearningScreenState extends State<SentenceLearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FlutterTts flutterTts;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeFlutterTts();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // إعادة بناء الواجهة عند تغيير التاب
      _speakWelcomeMessage(_tabController.index);
    });

    // تحميل البيانات بعد إنشاء الـ TabController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SentenceProgressProvider>(context, listen: false)
          .loadAllProgress();
      Provider.of<SentenceProvider>(context, listen: false).loadLocalData();
      _speakWelcomeMessage(0); // الترحيب الأولي
    });
  }

  Future<void> _initializeFlutterTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage("ar");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    // ignore: avoid_types_on_closure_parameters
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

    await flutterTts.speak(text);
  }

  void _speakWelcomeMessage(int tabIndex) {
    String welcomeMessage = '';
    switch (tabIndex) {
      case 0:
        welcomeMessage =
            'مرحباً بك في مرحلة تعلم الجمل وتركيبها،  في المستوى المبتدئ';
        break;
      case 1:
        welcomeMessage =
            'مرحباً بك في مرحلة تعلم الجمل وتركيبها، في المستوى المتوسط';
        break;
      case 2:
        welcomeMessage =
            'مرحباً بك في مرحلة تعلم الجمل وتركيبها، في المستوى المتقدم';
        break;
    }
    speak(welcomeMessage);
  }

  @override
  void dispose() {
    flutterTts.stop();
    _tabController.dispose();
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
            Text('تعلم الجمل',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                )),
            // IconButton(
            //     onPressed: () {},
            //     icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[800]))
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: TabBar(
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
    return Consumer2<SentenceProvider, SentenceProgressProvider>(
      builder: (context, sentenceProvider, progressProvider, child) {
        // حساب إحصائيات المستوى
        final sentencesInLevel =
            sentenceProvider.items.where((s) => s.level == level).toList();
        int masteredSentences = 0;
        double averageSuccess = 0.0;

        for (var sentence in sentencesInLevel) {
          if (progressProvider.isSentenceMastered(sentence.id)) {
            masteredSentences++;
          }
          averageSuccess +=
              progressProvider.getSentenceSuccessRate(sentence.id);
        }

        if (sentencesInLevel.isNotEmpty) {
          averageSuccess /= sentencesInLevel.length;
        }

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
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
                              SizedBox(height: 10),
                              // عرض عدد الجمل في المستوى
                              Text(
                                'عدد الجمل: ${sentencesInLevel.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 5),
                              // استخدام Consumer لتحديث إحصائيات الجمل المتقنة
                              // Consumer<SentenceProgressProvider>(
                              //   builder: (context, progressProvider, child) {
                              //     return FutureBuilder<int?>(
                              //       future: progressProvider
                              //           .getLastAccessedSentence(level),
                              //       builder: (context, snapshot) {
                              //         if (snapshot.connectionState ==
                              //             ConnectionState.waiting) {
                              //           return CircularProgressIndicator();
                              //         }

                              //         final lastAccessedSentenceId =
                              //             snapshot.data;
                              //         int masteredSentencesBeforeLast = 0;
                              //         if (lastAccessedSentenceId != null) {
                              //           for (var sentence in sentencesInLevel) {
                              //             if (sentence.id <
                              //                     lastAccessedSentenceId &&
                              //                 progressProvider
                              //                         .getSentenceProgress(
                              //                             sentence.id) !=
                              //                     null &&
                              //                 progressProvider
                              //                     .isSentenceMastered(
                              //                         sentence.id)) {
                              //               masteredSentencesBeforeLast++;
                              //             }
                              //           }
                              //         }

                              //         return Text(
                              //           'الجمل المتقنة: $masteredSentencesBeforeLast',
                              //           textAlign: TextAlign.center,
                              //           style: TextStyle(
                              //             fontSize: 16,
                              //             color: Colors.grey[600],
                              //           ),
                              //         );
                              //       },
                              //     );
                              //   },
                              // ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: averageSuccess,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            level == 0
                                ? Colors.green
                                : level == 1
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        SizedBox(height: 40),
                        _buildOptionCard(
                          context,
                          icon: "assets/icons/sentence_icon/sentence.PNG",
                          title: 'تركيب الجمل',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SentenceScreen(level: level),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        _buildOptionCard(
                          context,
                          icon: "assets/icons/testing.png",
                          title: 'اختبار الجمل',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SentenceTest(level: level),
                              ),
                            );
                          },
                        ),
                        // إضافة SizedBox مرن في نهاية Column
                        SizedBox(
                            height: constraints.maxHeight *
                                0.1), // 10% من المساحة المتاحة
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon(icon, size: 60, color: Colors.black87),
                Image.asset(
                  icon,
                  fit: BoxFit.contain,
                  height: 100,
                ),
                const SizedBox(width: 10),
                Text(
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
