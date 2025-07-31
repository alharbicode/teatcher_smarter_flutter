import 'package:flutter/material.dart';

class NumberModel with ChangeNotifier {
  final List<int> numbers = List.generate(10, (index) => index); // الأرقام من 0 إلى 9
  int currentIndex = 0;
  bool isArabic = true; // حالة اللغة الافتراضية (العربية)

  // إرجاع الرقم الحالي
  int get currentNumber => numbers[currentIndex];

  // إرجاع اسم الرقم الحالي بناءً على اللغة
  String get currentNumberName =>
      isArabic ? numberNamesArabic[currentNumber] ?? '' : numberNamesEnglish[currentNumber] ?? '';

  // أسماء الأرقام باللغة العربية
  final Map<int, String> numberNamesArabic = {
    0: 'صفر',
    1: 'واحد',
    2: 'اثنان',
    3: 'ثلاثة',
    4: 'أربعة',
    5: 'خمسة',
    6: 'ستة',
    7: 'سبعة',
    8: 'ثمانية',
    9: 'تسعة',
  };

  // أسماء الأرقام باللغة الإنجليزية
  final Map<int, String> numberNamesEnglish = {
    0: 'Zero',
    1: 'One',
    2: 'Two',
    3: 'Three',
    4: 'Four',
    5: 'Five',
    6: 'Six',
    7: 'Seven',
    8: 'Eight',
    9: 'Nine',
  };

  // التنقل إلى الرقم التالي
  void nextNumber() {
    if (currentIndex < numbers.length - 1) {
      currentIndex++;
      notifyListeners();
    }
  }

  // التنقل إلى الرقم السابق
  void previousNumber() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  // تبديل اللغة
  void toggleLanguage() {
    isArabic = !isArabic;
    notifyListeners();
  }
}
