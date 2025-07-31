// استيراد مكتبة sqflite للتعامل مع قواعد البيانات SQLite في فلتر
import 'package:sqflite/sqflite.dart';
// استيراد نموذج بيانات الرياضيات من ملف API
import '../models_for_api/math_model_api.dart';
// استيراد إعدادات قاعدة البيانات من ملف منفصل
import 'database_setup.dart';

// تعريف كلاس لعمليات الرياضيات على قاعدة البيانات
class MathOperations {
  // إنشاء كائن من كلاس إعدادات قاعدة البيانات
  final DatabaseSetup _databaseSetup = DatabaseSetup();

  // دالة لإضافة عنصر جديد إلى جدول الرياضيات
  Future<void> insertItem(MathModelApi item) async {
    // الحصول على اتصال بقاعدة البيانات
    final Database db = await _databaseSetup.database;
    // إدراج العنصر في جدول 'math_items' مع استبدال أي بيانات متضاربة
    await db.insert(
      'math_items', // اسم الجدول
      item.toMap(), // تحويل العنصر إلى خريطة (Map) قبل الإدراج
      conflictAlgorithm: ConflictAlgorithm.replace, // خوارزمية التعامل مع التضاربات (استبدال)
    );
  }

  // دالة لاسترجاع جميع العناصر من جدول الرياضيات
  Future<List<MathModelApi>> getAllItems() async {
    // الحصول على اتصال بقاعدة البيانات
    final Database db = await _databaseSetup.database;
    // استعلام لاسترجاع جميع الصفوف من جدول 'math_items'
    final List<Map<String, dynamic>> maps = await db.query('math_items');
    // تحويل النتائج من خريطة إلى قائمة من كائنات MathModelApi
    return List.generate(maps.length, (i) => MathModelApi.fromMap(maps[i]));
  }

  // دالة لاسترجاع العناصر حسب المستوى
  Future<List<MathModelApi>> getItemsByLevel(int level) async {
    // الحصول على اتصال بقاعدة البيانات
    final Database db = await _databaseSetup.database;
    // استعلام بشرط WHERE لتصفية النتائج حسب المستوى
    final List<Map<String, dynamic>> maps = await db.query(
      'math_items', // اسم الجدول
      where: 'level = ?', // شرط WHERE
      whereArgs: [level], // قيمة المعامل في الشرط
    );
    // تحويل النتائج من خريطة إلى قائمة من كائنات MathModelApi
    return List.generate(maps.length, (i) => MathModelApi.fromMap(maps[i]));
  }

  // دالة لحذف جميع العناصر من جدول الرياضيات
  Future<void> deleteAllItems() async {
    // الحصول على اتصال بقاعدة البيانات
    final Database db = await _databaseSetup.database;
    // تنفيذ عملية حذف لجميع الصفوف في الجدول
    await db.delete('math_items');
  }
}