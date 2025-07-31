
import 'package:flutter/material.dart';


import 'package:provider/provider.dart';

import 'package:teatcher_smarter/custom_widgets/CustomPositionedElements.dart';

import 'package:teatcher_smarter/providers/math_provider.dart';

import 'package:teatcher_smarter/screens/math_Learning_screen/math_test_screen.dart';

import 'package:teatcher_smarter/screens/math_Learning_screen/math_teaching_screen.dart';

import '../../custom_widgets/custom_app_bar.dart';

import '../../custom_widgets/menu_item_widget.dart';

class MainMath extends StatefulWidget {
  const MainMath({super.key});

  @override
  _MainMathState createState() => _MainMathState();
}

class _MainMathState extends State<MainMath> {
  int selectedLevel = 0; // متغير لتخزين المستوى المختار (0: مبتدئ، 1: متوسط، 2: متقدم)

  @override
  void initState() {
    super.initState();
    // تنفيذ كود بعد انتهاء بناء الويدجت
    WidgetsBinding.instance.addPostFrameCallback((_) {
      
      context.read<MathProvider>().loadData();
    });
  }

  String getLevelName(int level) {
    switch (level) {
      case 0:
        return 'مبتدئ';
      case 1:
        return 'متوسط';
      case 2:
        return 'متقدم';
      default:
        return 'مبتدئ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تعلم الحساب',
        onBackPressed: () => Navigator.pop(context),
      ),
  
      body: Stack(
        children: [
          // محتوى رئيسي مع حشوة أفقية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
               
                  Card(
                    elevation: 4, 
                    shape: RoundedRectangleBorder( 
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // نص لاختيار المستوى
                          const Text(
                            'اختر المستوى:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                            textDirection: TextDirection.rtl, // اتجاه النص من اليمين لليسار
                          ),
                          const SizedBox(height: 16), 
                       
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildLevelButton(0, 'مبتدئ', Colors.green),
                              const SizedBox(width: 8),
                              _buildLevelButton(1, 'متوسط', Colors.orange),
                              const SizedBox(width: 8),
                              _buildLevelButton(2, 'متقدم', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // عنصر قائمة لتعلم الحساب
                  MenuItemWidget(
                    iconPath: 'assets/icons/maleteacher.png',
                    title: 'تعلم الحساب',
                    subtitle: 'المستوى: ${getLevelName(selectedLevel)}',
                    onTap: () {
                      // الانتقال إلى شاشة تعليم الرياضيات
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MathTeachingScreen(
                            level: selectedLevel,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // عنصر قائمة لاختبار حل المسائل
                  MenuItemWidget(
                    iconPath: 'assets/icons/testing.png',
                    title: 'إختبار حل مسائل',
                    subtitle: 'المستوى: ${getLevelName(selectedLevel)}',
                    onTap: () {
                      // الانتقال إلى شاشة اختبار الرياضيات
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MathScreen(
                            level: selectedLevel,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 250), 
                ],
              ),
            ),
          ),
          // إضافة العناصر المخصصة ذات المواضع الثابتة
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

  // دالة مساعدة لبناء زر المستوى
  Widget _buildLevelButton(int level, String label, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = level; // تحديث المستوى المختار
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selectedLevel == level ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedLevel == level ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}