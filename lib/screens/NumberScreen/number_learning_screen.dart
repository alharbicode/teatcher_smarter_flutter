import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';
import 'package:teatcher_smarter/screens/NumberScreen/NumberDrawingScreen.dart';
import 'package:teatcher_smarter/screens/NumberScreen/number_screen.dart';
import '../../custom_widgets/custom_app_bar.dart';
import '../../custom_widgets/menu_item_widget.dart';
import 'number_drawing_test_screen.dart';

class NumbersLearningScreen extends StatefulWidget {
  const NumbersLearningScreen({super.key});

  @override
  _NumbersLearningScreenState createState() => _NumbersLearningScreenState();
}

class _NumbersLearningScreenState extends State<NumbersLearningScreen> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    _playWelcomeMessage();
  }

  Future<void> _playWelcomeMessage() async {
    await flutterTts.speak("أهلا بك في مرحلة تعلم نطق الأرقام وكتابتها");
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
        title: 'تعلم الأرقام',
        onBackPressed: () => Navigator.pop(context),
        icon_theme: Colors.orange,
      ),
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
                      iconPath: 'assets/icons/number_icon/pron_number.svg',
                      title: 'نطق الأرقام',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NumberScreen()));
                      },
                    ),
                    SizedBox(height: 20),
                    MenuItemWidget(
                      iconPath: 'assets/icons/number_icon/draw_number.svg',
                      title: 'رسم الأرقام',
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => NumberDrawingScreen()));
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
                                builder: (context) =>
                                    NumberDrawingTestScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ),
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
        ],
      ),
    );
  }
}
