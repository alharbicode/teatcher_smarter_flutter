import 'package:sqflite/sqflite.dart';
import 'package:teatcher_smarter/models_for_api/sentence_model.dart';


import 'database_setup.dart';

// فصل لعمليات قاعدة البيانات الخاصة بالجمل
class DatabaseSentensOperations {
  // إنشاء كائن من فصل إعداد قاعدة البيانات
  final DatabaseSetup _databaseSetup = DatabaseSetup();

  // دالة للحصول على كائن قاعدة البيانات بشكل غير متزامن
  Future<Database> get _db async => await _databaseSetup.database;

  // دالة لإدراج جملة جديدة في قاعدة البيانات
  Future<void> InsertSentens(SentenceModel sentens) async {
    try {

      final db = await _db;
      // إدراج الجملة في جدول 'sentens' مع استبدال البيانات في حالة وجود تضارب
      await db.insert('sentens', sentens.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
   
      print('Successfully inserted sentence: ${sentens.toString()}');
    } catch (e) {

      print('Error inserting sentence: $e');
      // إعادة رمي الخطأ
      rethrow;
    }
  }

  // دالة لجلب جميع الجمل من قاعدة البيانات
  Future<List<SentenceModel>> FetchSentens() async {
    try {

      final db = await _db;
      // استعلام قاعدة البيانات لجلبي كل الجمل من جدول 'sentens'
      final List<Map<String, dynamic>> maps = await db.query('sentens');
      // طباعة عدد الجمل التي تم جلبها
      print('Fetched ${maps.length} sentences from database');

      // تحويل البيانات الخام إلى قائمة من نماذج الجمل
      return List.generate(maps.length, (index) {
        try {
          // إنشاء نموذج جملة من البيانات
          return SentenceModel(
            id: maps[index]['id'] ?? 0,
            text: maps[index]['text'] ?? '',
            level: maps[index]['level'] ?? 0,
          );
        } catch (e) {
          // في حالة حدوث خطأ في التحويل، طباعة رسالة الخطأ
          print('Error parsing sentence at index $index: $e');
          // إرجاع جملة افتراضية في حالة الخطأ
          return SentenceModel(
            id: 0,
            text: 'Error loading sentence',
            level: 0,
          );
        }
      });
    } catch (e) {
      // في حالة فشل عملية الجلب، طباعة رسالة الخطأ
      print('Error fetching sentences: $e');
      // إرجاع قائمة فارغة في حالة الخطأ
      return [];
    }
  }

  // دالة لتحديث جملة موجودة في قاعدة البيانات
  Future<void> UpdateSentens(SentenceModel sentens) async {
    try {
      // الحصول على كائن قاعدة البيانات
      final db = await _db;
      // تحديث الجملة في جدول 'sentens' بناء على المعرف
      await db.update(
        'sentens',
        sentens.toMap(),
        where: 'id = ?',
        whereArgs: [sentens.id],
      );
      // طباعة رسالة نجاح التحديث
      print('Successfully updated sentence: ${sentens.toString()}');
    } catch (e) {
      // طباعة رسالة الخطأ في حالة فشل التحديث
      print('Error updating sentence: $e');
      // إعادة رمي الخطأ
      rethrow;
    }
  }

  // دالة لحذف جملة من قاعدة البيانات باستخدام المعرف
  Future<void> DeleteSentens(int id) async {
    try {
      // الحصول على كائن قاعدة البيانات
      final db = await _db;
      // حذف الجملة من جدول 'sentens' بناء على المعرف
      await db.delete(
        'sentens',
        where: 'id = ?',
        whereArgs: [id],
      );
      // طباعة رسالة نجاح الحذف
      print('Successfully deleted sentence with ID: $id');
    } catch (e) {
      // طباعة رسالة الخطأ في حالة فشل الحذف
      print('Error deleting sentence: $e');
      // إعادة رمي الخطأ
      rethrow;
    }
  }

  // دالة لمسح جميع الجمل وإدراج جمل جديدة في عملية واحدة
  Future<void> clearAndInsertsentens(List<SentenceModel> sentens) async {
    try {
      // الحصول على كائن قاعدة البيانات
      final db = await _db;

      // بدء معاملة (transaction) لضمان تنفيذ العمليات كوحدة واحدة
      await db.transaction((txn) async {
        // إنشاء مجموعة عمليات (batch) لتنفيذها معًا
        final batch = txn.batch();

        // التكرار على جميع الجمل المطلوب إدراجها
        for (final item in sentens) {
          // التحقق من وجود الجملة بالفعل في قاعدة البيانات
          final existingItem = await txn.query(
            'sentens',
            where: 'id = ?',
            whereArgs: [item.id],
          );

          // إذا كانت الجملة موجودة، يتم تحديثها
          if (existingItem.isNotEmpty) {
            batch.update(
              'sentens',
              {
                'text': item.text,
                'level': item.level,
              },
              where: 'id = ?',
              whereArgs: [item.id],
            );
          } else {
            // إذا لم تكن الجملة موجودة، يتم إدراجها
            batch.insert('sentens', {
              'id': item.id,
              'text': item.text,
              'level': item.level,
            });
          }
        }

        // تنفيذ جميع العمليات في المجموعة
        await batch.commit(noResult: true);
        // طباعة رسالة نجاح العملية
        print('Successfully inserted ${sentens.length} sentences');
      });
    } catch (e) {
      // طباعة رسالة الخطأ في حالة فشل العملية
      print('Error in batch insert: $e');
      // إعادة رمي الخطأ
      rethrow;
    }
  }
}