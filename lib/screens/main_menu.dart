// lib/screens/main_menu.dart
import 'package:flutter/material.dart';

import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';

import 'package:teatcher_smarter/screens/NumberScreen/number_learning_screen.dart';

import 'package:teatcher_smarter/screens/SentenceScreen/sentence_learning_screen.dart';

import 'package:teatcher_smarter/screens/geometry_teaching_screen.dart';

import 'package:teatcher_smarter/screens/letters_learning/letters_learning_screen.dart';

import 'package:teatcher_smarter/screens/math_Learning_screen/main_math.dart';

import 'WordScreen/words_learning_screen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MenuItem> menuItems = [
      MenuItem(
        title: 'أبـت',
        subtitle: 'تعلم الحروف',
        iconPath: 'assets/icons/alphabet.png',
        destination: LettersLearningScreen(),
      ),
      MenuItem(
        title: 'كتب',
        subtitle: 'تعلم الكلمات',
        iconPath: 'assets/icons/words.png',
        destination: WordsLearningScreen(),
      ),
      MenuItem(
        title: 'العلم نور',
        subtitle: 'تعلم الجمل',
        iconPath: 'assets/icons/sentences.png',
        destination: SentenceLearningScreen(),
      ),
      MenuItem(
        title: '3',
        subtitle: 'تعلم الأرقام',
        iconPath: 'assets/icons/numbers.png',
        destination: NumbersLearningScreen(),
      ),
      MenuItem(
        title: 'الأشكال',
        subtitle: 'الأشكال',
        iconPath: 'assets/icons/shapes.png',
        destination: GeometryTeachingScreen(),
      ),
      MenuItem(
        title: '8 + 4 -',
        subtitle: 'الحساب',
        iconPath: 'assets/icons/calculations.png',
        destination: MainMath(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/icons/titleIcons.png",
          width: 300,
          height: 140,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: GridView.builder(
              itemCount: menuItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 30,
                mainAxisSpacing: 20,
                mainAxisExtent: 170,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => item.destination),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // عرض الأيقونة الكبيرة بدلًا من العنوان

                          Image.asset(
                            item.iconPath,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),

                          SizedBox(height: 8),

                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // الأيقونات الجانبية العائمة التي تظهر في الأمام

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

class MenuItem {
  final String title;

  final String subtitle;

  final String iconPath;

  final Widget destination;

  MenuItem({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.destination,
  });
}
