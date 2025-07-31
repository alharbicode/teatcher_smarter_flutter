
import 'dart:async'; 
import 'dart:io'; 
import 'dart:convert'; 


import 'package:http/http.dart' as http;

import 'package:teatcher_smarter/models_for_api/sentence_model.dart';


class ApiSentensService {
  final String baseUrl; 
  late http.Client _client; 
  final Duration timeout = const Duration(seconds: 3); // مهلة انتظار للطلبات

  // دالة البناء التي تهيئ عنوان URL وعميل HTTP
  ApiSentensService(this.baseUrl) {
    _client = http.Client(); 
  }

  Future<List<SentenceModel>> fetchData() async {
    try {
      // طباعة رسالة تنبيهية لعرض محاولة الاتصال
      print('Attempting to connect to: $baseUrl');
      // إجراء طلب GET إلى العنوان الأساسي مع رأس قبول JSON
      final response = await _client.get(
        Uri.parse(baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout); 

      // طباعة رمز حالة الاستجابة ونص الاستجابة لأغراض التصحيح
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

  
      if (response.statusCode == 200) {
 
        final List<dynamic> jsonData = json.decode(response.body);
        // تحويل كل عنصر في القائمة إلى نموذج SentenceModel وإرجاعها
        return jsonData
            .map((sentens) => SentenceModel.fromJson(sentens))
            .toList();
      } else {
     
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // معالجة أخطاء اتصال الشبكة
      print('Socket Exception: $e');
      throw Exception(
          'Cannot connect to server. Please check if the server is running.');
    } on TimeoutException catch (e) {
      // معالجة أخطاء انتهاء مهلة الطلب
      print('Timeout Exception: $e');
      throw Exception(
          'Connection timed out. Please check your network connection.');
    } catch (e) {
      // معالجة أي أخطاء أخرى
      print('Error details: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  // دالة لجلب البيانات باستخدام ETag للتخزين المؤقت
  Future<(List<SentenceModel>, String?)> fetchDataWithEtag(String? eTag) async {
    try {
      // طباعة رسالة تنبيهية مع عنوان URL وETag
      print('Attempting to connect to: $baseUrl with ETag: $eTag');
      // إعداد رؤوس الطلب
      final headers = <String, String>{'Accept': 'application/json'};

      // إضافة ETag إلى الرؤوس إذا كان متوفراً
      if (eTag != null) {
        headers['If-None-Match'] = eTag;
      }

      // إجراء طلب GET مع الرؤوس
      final response = await _client
          .get(
            Uri.parse(baseUrl),
            headers: headers,
          )
          .timeout(timeout); // تطبيق المهلة الزمنية

      // طباعة رمز حالة الاستجابة
      print('Response status code: ${response.statusCode}');
      // طباعة نص الاستجابة فقط إذا لم يكن رمز الحالة 304 (لم يتم التعديل)
      if (response.statusCode != 304) {
        print('Response body: ${response.body}');
      }

      // معالجة الاستجابة الناجحة (200)
      if (response.statusCode == 200) {
        // الحصول على ETag جديد من رؤوس الاستجابة
        final newEtag = response.headers['etag'];

        // تحويل نص الاستجابة من JSON
        final List<dynamic> jsonData = json.decode(response.body);

        // إرجاع القائمة مع نماذج SentenceModel وETag الجديد
        return (
          jsonData.map((sentence) => SentenceModel.fromJson(sentence)).toList(),
          newEtag
        );
      } else if (response.statusCode == 304) {
        // معالجة حالة عدم التعديل (304)
        print('Data not changed (304), returning empty list and old ETag.');
        // إرجاع قائمة فارغة وETag الأصلي
        return (<SentenceModel>[], eTag);
      } else {
        // إطلاق استثناء لرموز الحالة الأخرى
        throw Exception(
            'Failed to fetch data with ETag: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // معالجة أخطاء اتصال الشبكة
      print('Socket Exception: $e');
      throw Exception(
          'Cannot connect to server. Please check if the server is running.');
    } on TimeoutException catch (e) {
      // معالجة أخطاء انتهاء مهلة الطلب
      print('Timeout Exception: $e');
      throw Exception(
          'Connection timed out. Please check your network connection.');
    } catch (e) {
      // معالجة أي أخطاء أخرى
      print('Error details: $e');
      throw Exception('Error syncing data: $e');
    }
  }
}