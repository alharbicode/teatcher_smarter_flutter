import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models_for_api/math_model_api.dart';
import '../utils/math_operations.dart';

class MathService {
  final String baseUrl;
  final MathOperations _mathOperations = MathOperations();
  String? _eTag;

  MathService({required this.baseUrl});

  Future<List<MathModelApi>> fetchAndSaveData() async {
    try {
      // جلب البيانات المحلية
      List<MathModelApi> localData = await _mathOperations.getAllItems();
      
      // محاولة مزامنة البيانات مع الخادم
      try {
        final prefs = await SharedPreferences.getInstance();
        _eTag = prefs.getString('mathETag');

        final headers = _eTag != null ? {'If-None-Match': _eTag!} : <String, String>{};
        final response = await http.get(Uri.parse('$baseUrl/'), headers: headers);

        if (response.statusCode == 200) {
          // البيانات على الخادم محدثة
          final List<dynamic> jsonData = json.decode(response.body);
          final newEtag = response.headers['etag'];

          // تحديث ETag إذا كان مختلفاً
          if (newEtag != null && newEtag != _eTag) {
            await prefs.setString('mathETag', newEtag);
            _eTag = newEtag;
          }

          // تحديث البيانات المحلية
          await _mathOperations.deleteAllItems();
          for (var item in jsonData) {
            final mathItem = MathModelApi.fromJson(item);
            await _mathOperations.insertItem(mathItem);
          }

          // إعادة قراءة البيانات المحدثة
          return await _mathOperations.getAllItems();
        } 
        else if (response.statusCode == 304) {
          // البيانات المحلية محدثة
          print('Local math data is up to date');
          return localData;
        }
        else {
          print('Server returned status code: ${response.statusCode}');
          return localData;
        }
      } catch (networkError) {
        print('Network error in fetchAndSaveData: $networkError');
        // في حالة وجود مشكلة في الاتصال، نستخدم البيانات المحلية
        return localData;
      }
    } catch (e) {
      print('Error in fetchAndSaveData: $e');
      // في حالة أي خطأ آخر، نحاول إرجاع البيانات المحلية
      try {
        return await _mathOperations.getAllItems();
      } catch (dbError) {
        print('Database error: $dbError');
        // إذا فشل كل شيء، نرجع قائمة فارغة
        return [];
      }
    }
  }

  Future<List<MathModelApi>> getAllItems() async {
    return await _mathOperations.getAllItems();
  }

  Future<List<MathModelApi>> getItemsByLevel(int level) async {
    return await _mathOperations.getItemsByLevel(level);
  }
}