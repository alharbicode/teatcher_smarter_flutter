import 'package:flutter/material.dart';
import '../models_for_api/math_model_api.dart';
import '../services/math_service.dart';
import '../models/math_model.dart';

class MathProvider with ChangeNotifier {
  final MathService _mathService;
  List<MathModelApi> _items = [];
  List<MathModelApi> _filteredItems = [];
  bool _isLoading = false;
  int _currentIndex = 0;

  MathProvider({required String baseUrl}) : _mathService = MathService(baseUrl: baseUrl);

  List<MathModelApi> get items => _items;
  List<MathModelApi> get filteredItems => _filteredItems;
  bool get isLoading => _isLoading;
  MathModelApi? get currentMath => _filteredItems.isNotEmpty ? _filteredItems[_currentIndex] : null;
  int get currentIndex => _currentIndex;

  int getOperationLevel(Operation operation) {
    switch (operation) {
      case Operation.addition:
        return 1;
      case Operation.subtraction:
        return 2;
      case Operation.multiplication:
        return 3;
      case Operation.division:
        return 4;
      default:
        return 1;
    }
  }

  int getOperationType(Operation operation) {
    switch (operation) {
      case Operation.addition:
        return 0; 
      case Operation.subtraction:
        return 1; 
      case Operation.multiplication:
        return 2; 
      case Operation.division:
        return 3; 
      default:
        return 0;
    }
  }
  // دالة لتصفية العناصر بناءً على نوع العملية الحسابية

  void filterByOperation(Operation operation) {
    _filteredItems = _items.where((item) {
      return item.arithmeticOperations == getOperationType(operation);
    }).toList();
    _currentIndex = 0;
    notifyListeners();
  }
  // دالة لتصفية العناصر بناءً على نوع العملية ومستوى الصعوبة

  void filterByOperationAndLevel(Operation operation, int level) {
    _filteredItems = _items.where((item) {
      return item.arithmeticOperations == getOperationType(operation) &&
             item.level == level;
    }).toList();
    _currentIndex = 0;
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      _isLoading = true;
      notifyListeners();

      _items = await _mathService.fetchAndSaveData();
      
      if (_filteredItems.isNotEmpty) {
        // حفظ المستوى الحالي
        int currentLevel = _filteredItems.first.level;
        filterByLevel(currentLevel);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading math data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // دالة لتصفية العناصر بناءً على مستوى الصعوبة فقط

  void filterByLevel(int level) {
    _filteredItems = _items.where((item) {
      return item.level == level;
    }).toList();
    _currentIndex = 0;
    notifyListeners();
  }

  void nextItem() {
    if (_currentIndex < _filteredItems.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousItem() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _filteredItems.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
