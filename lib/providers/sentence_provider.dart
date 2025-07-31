import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teatcher_smarter/models_for_api/sentence_model.dart';

import '../services/api_sentens_service.dart';
import '../utils/database_sentens_operations.dart';

class SentenceProvider with ChangeNotifier {
  final ApiSentensService apiService;
  final DatabaseSentensOperations databaseSentensOperations =
      DatabaseSentensOperations();
  late final SharedPreferences _prefs;

  List<SentenceModel> _items = [];
  bool _isLoading = false;
  String? _eTag;
  int _currentIndex = 0;
  BuildContext? _context;
  final Map<int, List<Map<String, String>>> _sentenceAssemblyStates = {};

  SentenceProvider({required this.apiService, BuildContext? context}) {
    _initPrefs();
    _context = context;
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _eTag = _prefs.getString('sentens_eTag');
    print('Initial ETag loaded: $_eTag');
  }

  List<SentenceModel> get items => _items;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;

  List<Map<String, String>> get currentSentenceAssembly =>
      _sentenceAssemblyStates[currentSentence?.id ?? -1] ?? [];

  SentenceModel? get currentSentence =>
      _items.isNotEmpty && _currentIndex < _items.length
          ? _items[_currentIndex]
          : null;

  void updateSentenceAssembly(int sentenceId, List<Map<String, String>> newAssembly) {
    _sentenceAssemblyStates[sentenceId] = newAssembly;
    notifyListeners();
  }

  // تصفية الجمل حسب المستوى
  void filterSentencesByLevel(int level) {
    _items = _items.where((item) => item.level == level).toList();
    _loadCurrentIndex(level); // استرجاع المؤشر بعد الفلترة
    notifyListeners();
  }

  Future<void> _loadCurrentIndex(int level) async {
    if (_items.isNotEmpty) {
      _currentIndex = _prefs.getInt('currentSentenceIndex_$level') ?? 0;
      _currentIndex = _currentIndex.clamp(0, _items.length - 1);
    } else {
      _currentIndex = 0;
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('لا توجد جمل لهذا المستوى في الوقت الحالي.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // حفظ الموقع الحالي
  Future<void> saveCurrentIndex(int level) async {
    await _prefs.setInt('currentSentenceIndex_$level', _currentIndex);
  }

  // تحديث الموقع الحالي
  void setCurrentIndex(int index, int level) {
    if (index >= 0 && index < _items.length) {
      _currentIndex = index;
      saveCurrentIndex(level);
      notifyListeners();
    }
  }

  void moveToPrevious(int level) {
    if (_currentIndex > 0) {
      saveSentenceAssemblyState(); // حفظ الحالة قبل الانتقال
      _currentIndex--;
      saveCurrentIndex(level);
      notifyListeners();
    }
  }

  void moveToNext(int level) {
    if (_currentIndex < _items.length - 1) {
      saveSentenceAssemblyState(); // حفظ الحالة قبل الانتقال
      _currentIndex++;
      saveCurrentIndex(level);
      notifyListeners();
    }
  }

  // حفظ حالة تجميع الجملة
  void saveSentenceAssemblyState() {
    if (currentSentence != null) {
      _sentenceAssemblyStates[currentSentence!.id] = List.from(currentSentenceAssembly);
    }
  }

  // استرجاع حالة تجميع الجملة
  List<Map<String, String>>? getSentenceAssemblyState(int sentenceId) {
    return _sentenceAssemblyStates[sentenceId];
  }

  Future<void> loadLocalData() async {
    try {
      _isLoading = true;
      notifyListeners();

      _items = await databaseSentensOperations.FetchSentens();
      print('Loaded ${_items.length} items from local database');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading local data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAndSyncData() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      notifyListeners();

      if (_items.isEmpty) {
        await loadLocalData();
      }

      final (fetchedItems, newEtag) = await apiService.fetchDataWithEtag(_eTag);
      print(
          'Fetched ${fetchedItems.length} items from API, new ETag: $newEtag');

      if (fetchedItems.isNotEmpty) {
        final localItemIds = _items.map((item) => item.id).toSet();
        final fetchedItemIds = fetchedItems.map((item) => item.id).toSet();
        final itemsToDelete = localItemIds.difference(fetchedItemIds);

        for (var itemId in itemsToDelete) {
          await databaseSentensOperations.DeleteSentens(itemId);
        }

        for (var item in fetchedItems) {
          await databaseSentensOperations.InsertSentens(item);
        }

        _eTag = newEtag;
        await _prefs.setString('sentens_eTag', newEtag!);
        print('Updated local database, new ETag: $_eTag');

        await loadLocalData();
      } else if (newEtag == _eTag && _eTag != null) {
        print(
            'Data has not changed, and connection available. Using cached data.');
      } else if (newEtag != _eTag && _eTag != null) {
        print('ETag changed but no items fetched. Checking for deletions.');
        final localItems = await databaseSentensOperations.FetchSentens();
        final localItemIds = localItems.map((item) => item.id).toSet();

        for (var itemId in localItemIds) {
          print('Deleting item with ID: $itemId');
          await databaseSentensOperations.DeleteSentens(itemId);
        }

        _eTag = newEtag;
        await _prefs.setString('sentens_eTag', newEtag!);
        print('Updated local database after deletion, new ETag: $_eTag');

        await loadLocalData();
      } else {
        print('Data has not changed. Using cached data.');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error syncing data: $e');
      if (_items.isEmpty) {
        await loadLocalData();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(SentenceModel item) async {
    try {
      await databaseSentensOperations.InsertSentens(item);
      await loadLocalData();
    } catch (e) {
      print('Error adding item: $e');
    }
  }

  Future<void> updateItem(SentenceModel item) async {
    try {
      await databaseSentensOperations.UpdateSentens(item);
      await loadLocalData();
    } catch (e) {
      print('Error updating item: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await databaseSentensOperations.DeleteSentens(id);
      await loadLocalData();
    } catch (e) {
      print('Error deleting item: $e');
    }
  }
}