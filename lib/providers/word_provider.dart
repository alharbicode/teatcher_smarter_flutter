import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teatcher_smarter/models_for_api/word_model.dart';
import '../services/api_service.dart';
import '../utils/database_operations.dart';

class WordsProvider with ChangeNotifier {
  final ApiService apiService;
  final DatabaseOperations databaseOperations = DatabaseOperations();
  late final SharedPreferences _prefs;

  List<WordModel> _items = [];
  List<WordModel> _filteredItems = [];
  bool _isLoading = false;
  String? _eTag;
  int _currentIndex = 0;
  final Map<int, Map<String, dynamic>> _wordAssemblyStates =
      {}; // لحفظ حالة تجميع الكلمات
  final Set<int> _completedWords = {};

  WordsProvider({required this.apiService}) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _eTag = _prefs.getString('eTag');
    _loadCurrentIndex();
  }

  Future<void> _loadCurrentIndex() async {
    _currentIndex = _prefs.getInt('currentWordIndex_${_getCurrentKey()}') ?? 0;
    print('Loaded current index: $_currentIndex for key: ${_getCurrentKey()}');
  }

  String _getCurrentKey() {
    if (_filteredItems.isEmpty) return 'default';
    final currentWord = _filteredItems[_currentIndex];
    return 'level_${currentWord.level}';
  }

  List<WordModel> get items => _items;
  List<WordModel> get filteredItems => _filteredItems;
  bool get isLoading => _isLoading;
  WordModel? get currentWord =>
      _filteredItems.isNotEmpty && _currentIndex < _filteredItems.length
          ? _filteredItems[_currentIndex]
          : null;

  // استرجاع حالة تجميع الكلمة
  String get assembledWord =>
      _wordAssemblyStates[currentWord?.id ?? -1]?['assembledWord'] ?? '';
  Set<Map<String, String>> get selectedLettersSet =>
      Set<Map<String, String>>.from(_wordAssemblyStates[currentWord?.id ?? -1]
              ?['selectedLettersSet'] ??
          {});

  void setCurrentWordIndex(int index) {
    if (index >= 0 && index < _filteredItems.length) {
      _currentIndex = index;
      _saveCurrentIndex();
      notifyListeners();
    }
  }

  Future<void> _saveCurrentIndex() async {
    await _prefs.setInt('currentWordIndex_${_getCurrentKey()}', _currentIndex);
    print('Saved current index: $_currentIndex for key: ${_getCurrentKey()}');
  }

  void nextWord() {
    if (_currentIndex < _filteredItems.length - 1) {
      _saveWordAssemblyState(); // حفظ الحالة قبل الانتقال
      _currentIndex++;
      _saveCurrentIndex();
      notifyListeners();
    }
  }

  void previousWord() {
    if (_currentIndex > 0) {
      _saveWordAssemblyState(); // حفظ الحالة قبل الانتقال
      _currentIndex--;
      _saveCurrentIndex();
      notifyListeners();
    }
  }

  // حفظ حالة تجميع الكلمة الحالية
  void _saveWordAssemblyState() {
    if (currentWord != null) {
      _wordAssemblyStates[currentWord!.id] = {
        'assembledWord': assembledWord,
        'selectedLettersSet': selectedLettersSet.toList(),
      };
    }
  }

  // استرجاع حالة تجميع الكلمة
  Map<String, dynamic>? getWordAssemblyState(int wordId) {
    return _wordAssemblyStates[wordId];
  }

  Future<void> loadLocalData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final localWords = await databaseOperations.fetchItems();
      _items = localWords;
      _filterItemsByLevel();
      await _loadCurrentIndex(); // تحميل المؤشر بعد تحميل الكلمات
      _currentIndex = _currentIndex.clamp(0, _filteredItems.length - 1);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading local data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByLevel(int level) {
    _filteredItems = _items.where((word) => word.level == level).toList();
    _loadCurrentIndex(); // تحميل المؤشر بعد الفلترة
    _currentIndex = _currentIndex.clamp(0, _filteredItems.length - 1);
    notifyListeners();
  }

  void _filterItemsByLevel() {
    if (_filteredItems.isNotEmpty) {
      final currentLevel = _filteredItems.first.level;
      _filteredItems =
          _items.where((word) => word.level == currentLevel).toList();
      _loadCurrentIndex(); // تحميل المؤشر بعد الفلترة الداخلية
      _currentIndex = _currentIndex.clamp(0, _filteredItems.length - 1);
    }
  }

  Future<void> resetProgress(int level) async {
    await _prefs.remove('currentWordIndex_level_$level');
    _currentIndex = 0;
    notifyListeners();
  }

  List<String> getShuffledLetters(String word) {
    List<String> letters = word.split('');
    letters.shuffle();
    return letters;
  }

  // دوال التعامل مع تجميع الكلمة
  void selectLetter(Map<String, String> letterMap) {
    final currentWordId = currentWord?.id ?? -1;
    if (currentWordId != -1) {
      _ensureWordAssemblyStateExists(currentWordId);
      final assembled =
          _wordAssemblyStates[currentWordId]!['assembledWord'] as String;
      final selected = _wordAssemblyStates[currentWordId]!['selectedLettersSet']
          as List<Map<String, String>>;
      if (!selected.contains(letterMap)) {
        selected.add(letterMap);
        _wordAssemblyStates[currentWordId]!['assembledWord'] =
            assembled + letterMap['letter']!;
        notifyListeners();
      }
    }
  }

  void deselectLetter(Map<String, String> letterMap) {
    final currentWordId = currentWord?.id ?? -1;
    if (currentWordId != -1) {
      _ensureWordAssemblyStateExists(currentWordId);
      final assembled =
          _wordAssemblyStates[currentWordId]!['assembledWord'] as String;
      List<Map<String, String>> selected =
          List.from(_wordAssemblyStates[currentWordId]!['selectedLettersSet']);
      selected.removeWhere((item) => item == letterMap);
      _wordAssemblyStates[currentWordId]!['assembledWord'] =
          assembled.replaceFirst(letterMap['letter']!, '');
      _wordAssemblyStates[currentWordId]!['selectedLettersSet'] = selected;
      notifyListeners();
    }
  }

  void _ensureWordAssemblyStateExists(int wordId) {
    if (!_wordAssemblyStates.containsKey(wordId)) {
      _wordAssemblyStates[wordId] = {
        'assembledWord': '',
        'selectedLettersSet': []
      };
    }
  }

  Future<void> fetchAndSyncData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final (fetchedItems, newEtag) = await apiService.fetchDataWithEtag(_eTag);

      if (newEtag != null && newEtag != _eTag) {
        await _prefs.setString('eTag', newEtag);
        _eTag = newEtag;
        print('Updated ETag to: $newEtag');
      }

      if (fetchedItems.isNotEmpty) {
        _items = fetchedItems;
        await databaseOperations.saveItems(_items);
        print('Updated items from server: ${_items.length} items');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching data: $e');
    }
  }

  Future<void> addItem(WordModel item) async {
    await databaseOperations.insertItem(item);
    await loadLocalData();
  }

  Future<void> updateItem(WordModel item) async {
    await databaseOperations.updateItem(item);
    await loadLocalData();
  }

  Future<void> deleteItem(int id) async {
    await databaseOperations.deleteItem(id);
    await loadLocalData();
  }

  bool hasNextWord() {
    return _currentIndex < _filteredItems.length - 1;
  }

  int remainingWordsCount() {
    return _filteredItems.length - (_currentIndex + 1);
  }

  bool hasPreviousWord() {
    return _currentIndex > 0;
  }

  void markWordAsCompleted(WordModel word) {
    _completedWords.add(word.id);
    notifyListeners();
  }

  bool isWordCompleted(WordModel word) {
    return _completedWords.contains(word.id);
  }
}
