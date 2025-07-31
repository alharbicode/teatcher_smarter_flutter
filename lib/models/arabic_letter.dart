// lib/models/arabic_letter.dart
class ArabicLetter {
  final String character; // الحرف العربي
  final String name; // اسم الحرف باللغة العربية
  int stars; // عدد النجوم المكتسبة
  int attempts; // عدد المحاولات

  ArabicLetter({
    required this.character,
    required this.name,
    this.stars = 0,
    this.attempts = 0,
  });

  // دالة لتحديث النجوم بناءً على عدد المحاولات
  void updateStars() {
    if (attempts <= 2) {
      stars = 3;
    } else if (attempts <= 4) {
      stars = 2;
    } else if (attempts == 5) {
      stars = 1;
    }
  }

  // إعادة تعيين المحاولات
  void resetAttempts() {
    attempts = 0;
    stars = 0;
  }
}
