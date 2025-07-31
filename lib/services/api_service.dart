// استيراد المكتبات المطلوبة
import 'dart:async'; // لمهام البرمجة غير المتزامنة
import 'dart:io'; // للتعامل مع نظام الملفات والشبكات
import 'dart:convert'; // لتحويل البيانات مثل JSON
import 'package:http/http.dart' as http; // مكتبة HTTP للاتصال بالخوادم
import '../models_for_api/word_model.dart'; // نموذج البيانات الخاص بالتطبيق

class ApiService {
  final String baseUrl; // عنوان URL الأساسي للخادم
  final Duration timeout = const Duration(seconds: 3); // مهلة انتظار الاتصال
  final http.Client _client = http.Client(); // عميل HTTP لإجراء الطلبات

  // مُنشئ الخدمة مع عنوان URL الأساسي المطلوب
  ApiService({required this.baseUrl});

  // دالة لجلب البيانات من الخادم
  Future<List<WordModel>> fetchData() async {
    try {
      // إرسال طلب GET إلى الخادم
      final response = await _client.get(
        Uri.parse(baseUrl), // تحويل الرابط إلى كائن Uri
        headers: {'Accept': 'application/json'}, // طلب البيانات بصيغة JSON
      ).timeout(timeout); // تحديد مهلة الانتظار

      // إذا كانت الاستجابة ناجحة (كود 200)
      if (response.statusCode == 200) {
        // تحويل JSON إلى قائمة من الكائنات الديناميكية
        final List<dynamic> jsonData = json.decode(response.body);
        // تحويل كل عنصر في القائمة إلى نموذج WordModel وإرجاع القائمة
        return jsonData.map((item) => WordModel.fromJson(item)).toList();
      } else {
        // إذا فشل الطلب، رمي استثناء مع كود الخطأ
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // معالجة خطأ الاتصال بالخادم
      print('Socket Exception: $e');
      throw Exception(
          'Cannot connect to server. Please check if the server is running.');
    } on TimeoutException catch (e) {
      // معالجة انتهاء مهلة الاتصال
      print('Timeout Exception: $e');
      throw Exception(
          'Connection timed out. Please check your network connection.');
    } catch (e) {
      // معالجة أي أخطاء أخرى
      print('Error details: $e');
      throw Exception('Failed to fetch data: $e');
    }
  }

  // دالة لجلب البيانات مع استخدام ETag للتحقق من التغييرات
  Future<(List<WordModel>, String?)> fetchDataWithEtag(String? eTag) async {
    try {
      print('Attempting to connect to: $baseUrl with ETag: $eTag');
      // تحضير رؤوس الطلب
      final headers = <String, String>{'Accept': 'application/json'};
      // إذا كان هناك ETag، نضيفه للرؤوس
      if (eTag != null) {
        headers['If-None-Match'] = eTag;
      }

      // إرسال طلب GET مع الرؤوس
      final response = await _client
          .get(
            Uri.parse(baseUrl),
            headers: headers,
          )
          .timeout(timeout);

      print('Response status code: ${response.statusCode}');
      // الحصول على ETag الجديد من رؤوس الاستجابة
      final newEtag = response.headers['etag'];

      // إذا كانت الاستجابة ناجحة (كود 200)
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        // تحويل JSON إلى قائمة نماذج WordModel
        final List<dynamic> jsonData = json.decode(response.body);
        final items = jsonData.map((item) {
          return WordModel.fromJson({
            'id': item['id'],
            'text': item['text'],
            'image': item['image'],
            'level': item['level'],
          });
        }).toList();
        // إرجاع القائمة مع ETag الجديد
        return (items, newEtag);
      } else if (response.statusCode == 304) {
        // إذا لم تتغير البيانات (كود 304)
        print('Data not changed (304), returning null list and new ETag.');
        // إرجاع قائمة فارغة مع ETag الجديد أو القديم
        return (<WordModel>[], newEtag ?? eTag);
      } else {
        // إذا فشل الطلب، رمي استثناء
        throw Exception(
            'Failed to fetch data with ETag: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // معالجة أخطاء الاتصال
      print('Socket Exception: $e');
      throw Exception(
          'Cannot connect to server. Please check if the server is running.');
    } on TimeoutException catch (e) {
      // معالجة انتهاء مهلة الاتصال
      print('Timeout Exception: $e');
      throw Exception(
          'Connection timed out. Please check your network connection.');
    } catch (e) {
      // معالجة أي أخطاء أخرى
      print('Error details: $e');
      throw Exception('Failed to fetch data with ETag: $e');
    }
  }
}