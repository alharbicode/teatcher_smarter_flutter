
import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';

import 'package:teatcher_smarter/screens/letters_learning/drawing_screen.dart';

import 'package:teatcher_smarter/screens/letters_learning/drawing_test_screen.dart';

import '../../custom_widgets/custom_app_bar.dart';
import '../../custom_widgets/menu_item_widget.dart';
import 'letter_pronunciation_screen.dart';


class LettersLearningScreen extends StatefulWidget {
  const LettersLearningScreen({super.key});

  @override
  _LettersLearningScreenState createState() => _LettersLearningScreenState();
}


class _LettersLearningScreenState extends State<LettersLearningScreen> {

  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    
    flutterTts = FlutterTts();
    // ضبط إعدادات المحرك
    _initTts();
  }


  Future<void> _initTts() async {
 
    await flutterTts.setLanguage("ar-SA");

    await flutterTts.setSpeechRate(0.5);

    await flutterTts.setPitch(1.0);

    _playWelcomeMessage();
  }

 
  Future<void> _playWelcomeMessage() async {
    await flutterTts.speak("أهلا بك في مرحلة تعلم نطق الأحرف وكتابتها");
  }

  @override
  void dispose() {
    
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // شريط التطبيق المخصص
      appBar: CustomAppBar(
        title: 'تعلم الأحرف',
        onBackPressed: () => Navigator.pop(context),
        icon_theme: Colors.orange,
      ),
      // جسم الواجهة باستخدام Stack للعناصر المتعددة
      body: Stack(
        children: [
     
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  
                    MenuItemWidget(
                      iconPath: 'assets/icons/pronounce.png',
                      title: 'نطق الأحرف',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Letterpronunciationscreen()));
                      },
                    ),
                    SizedBox(height: 20),
                   
                    MenuItemWidget(
                      iconPath: 'assets/icons/draw.png',
                      title: 'رسم الأحرف',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DrawingScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                  
                    MenuItemWidget(
                      iconPath: 'assets/icons/testing.png',
                      title: 'اختبار',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DrawingTestScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // العناصر الزخرفية الثابتة (أحرف عربية ورموز)
          CustomPositionedElements.starIconTopRight(),
          CustomPositionedElements.taaIconTopRight(),
          CustomPositionedElements.khaIconRightMiddle(),
          CustomPositionedElements.haaIconBottomRight(),
          CustomPositionedElements.fourIconTopLeft(),
          CustomPositionedElements.dashIconTopLeft(),
          CustomPositionedElements.seenIconMiddleLeft(),
          CustomPositionedElements.noonIconBottomLeft(),
          CustomPositionedElements.starIconBottomLeft(),
        ],
      ),
    );
  }
}