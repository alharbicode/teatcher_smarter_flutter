
import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart';


class DatabaseSetup {
  static final DatabaseSetup _instance = DatabaseSetup._internal();

  static Database? _database;

  // مصنع لإرجاع النسخة الوحيدة من الكلاس
  factory DatabaseSetup() => _instance;

  // مُنشئ داخلي خاص لنمط السنجلتون
  DatabaseSetup._internal();


  Future<Database> get database async {
    // إذا كانت قاعدة البيانات موجودة بالفعل، أرجعها
    if (_database != null) return _database!;
    // إذا لم تكن موجودة، قم بتهيئتها أولاً
    _database = await _initDatabase();
    return _database!;
  }


  Future<Database> _initDatabase() async {

    String path = join(await getDatabasesPath(), 'learning_app.db');
  
    return await openDatabase(
      path,
      version: 4, // رقم إصدار قاعدة البيانات (يتم زيادته عند تعديل الهيكل)
      onCreate: _onCreate, // دالة تنفذ عند إنشاء قاعدة بيانات جديدة
      onUpgrade: _onUpgrade,
    );
  }


  Future<void> _onCreate(Database db, int version) async {
    // إنشاء جدول الأمثلة الرياضية
    await db.execute('''
      CREATE TABLE IF NOT EXISTS math_examples (
        id INTEGER PRIMARY KEY,
        firstNumber INTEGER,
        secondNumber INTEGER,
        result INTEGER,
        arithmeticOperations INTEGER,
        level INTEGER,
        problemText TEXT,
        isExample INTEGER
      )
    ''');

    // إنشاء جدول تقدم المستخدم في الرياضيات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation INTEGER,
        level INTEGER,
        completed_examples TEXT,
        last_accessed INTEGER,
        is_completed INTEGER DEFAULT 0,
        last_accessed_word_id INTEGER
      )
    ''');

    // إنشاء جدول تقدم تعلم الكلمات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER,
        attempts INTEGER DEFAULT 0,
        correct_attempts INTEGER DEFAULT 0,
        last_practiced INTEGER,
        is_mastered INTEGER DEFAULT 0,
        confidence_level REAL DEFAULT 0.0
      )
    ''');

    // إنشاء جدول الحروف
    await db.execute('''
      CREATE TABLE IF NOT EXISTS letters (
        character TEXT PRIMARY KEY,
        name TEXT,
        stars INTEGER,
        attempts INTEGER,
        status INTEGER
      )
    ''');

    // إنشاء جدول العناصر (من قاعدة البيانات الثانية)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id INTEGER PRIMARY KEY,
        text TEXT,
        image TEXT,
        level INTEGER
      )
    ''');

    // إنشاء جدول الجمل (من قاعدة البيانات الثانية)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sentens (
        id INTEGER PRIMARY KEY,
        text TEXT,
        level INTEGER
      )
    ''');

    // إنشاء جدول العناصر الرياضية (من قاعدة البيانات الثانية)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS math_items (
        id INTEGER PRIMARY KEY,
        arithmeticOperations INTEGER,
        num1 INTEGER,
        num2 INTEGER,
        steps TEXT,
        level INTEGER
      )
    ''');

    // إنشاء جدول تقدم تعلم الجمل
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sentence_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sentence_id INTEGER,
        attempts INTEGER DEFAULT 0,
        correct_attempts INTEGER DEFAULT 0,
        last_practiced INTEGER,
        is_mastered INTEGER DEFAULT 0,
        confidence_level REAL DEFAULT 0.0
      )
    ''');
  }

  // دالة تحديث قاعدة البيانات عند تغيير رقم الإصدار
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // تحديثات للإصدار 2
    if (oldVersion < 2) {
      // إنشاء جدول تقدم المستخدم إذا كان الترقية من إصدار < 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation INTEGER,
          level INTEGER,
          completed_examples TEXT,
          last_accessed INTEGER,
          is_completed INTEGER DEFAULT 0
        )
      ''');

      // إنشاء جدول تقدم الكلمات إذا كان الترقية من إصدار < 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS word_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word_id INTEGER,
          attempts INTEGER DEFAULT 0,
          correct_attempts INTEGER DEFAULT 0,
          last_practiced INTEGER,
          is_mastered INTEGER DEFAULT 0,
          confidence_level REAL DEFAULT 0.0
        )
      ''');
    }

 
    if (oldVersion < 3) {
    
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sentens (
          id INTEGER PRIMARY KEY,
          text TEXT,
          level INTEGER
        )
      ''');

      // إنشاء جدول العناصر الرياضية إذا كان الترقية من إصدار < 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS math_items (
          id INTEGER PRIMARY KEY,
          arithmeticOperations INTEGER,
          num1 INTEGER,
          num2 INTEGER,
          steps TEXT,
          level INTEGER
        )
      ''');

      // إنشاء جدول تقدم الجمل إذا كان الترقية من إصدار < 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sentence_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sentence_id INTEGER,
          attempts INTEGER DEFAULT 0,
          correct_attempts INTEGER DEFAULT 0,
          last_practiced INTEGER,
          is_mastered INTEGER DEFAULT 0,
          confidence_level REAL DEFAULT 0.0
        )
      ''');
    }

    // تحديث للإصدار 4 - إضافة عمود جديد لجدول تقدم المستخدم
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE user_progress
        ADD COLUMN last_accessed_word_id INTEGER
      ''');
    }
  }
}