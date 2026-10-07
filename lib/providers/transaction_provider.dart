import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/my_transaction.dart';

class TransactionProvider with ChangeNotifier {
  static const String _dbName = 'expenses.db';
  static const String _tableName = 'transactions';
  Database? _database;
  Future<Database>? _dbOpening;
  List<MyTransaction> _transactions = [];

  List<MyTransaction> get transactions => [..._transactions];

  Future<void> fetchAndSetTransactions() async {
    await _initDatabase();
    if (_database == null) return;
    try {
      final rows = await _database!.query(_tableName, orderBy: 'date DESC');
      _transactions = rows.map((row) => MyTransaction.fromMap(row)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  Future<void> addTransaction(String title, double amount, DateTime date, TransactionType type) async {
    await _initDatabase(); // ตรวจสอบว่า DB พร้อมใช้งาน
    if (_database == null) return;

    final newTransaction = MyTransaction(
      title: title,
      amount: amount,
      date: date,
      type: type,
    );

    try {
      final id = await _database!.insert(_tableName, newTransaction.toMap());
      debugPrint('Inserted transaction with id: $id');
      await fetchAndSetTransactions();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  // กระบวนการที่ 2: การสร้างฐานข้อมูล
  Future<void> _initDatabase() async {
    if (_database != null) return;
    // เก็บ Future ไว้ใช้ร่วมกัน กันเปิด DB ซ้ำเมื่อเรียกพร้อมกันหลายครั้ง
    _dbOpening ??= _openDatabase();
    try {
      _database = await _dbOpening!;
    } catch (e) {
      _dbOpening = null; // เปิดไม่สำเร็จ ให้ลองใหม่ได้ในครั้งถัดไป
      debugPrint('Error initializing database: $e');
    }
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        debugPrint('Creating table $_tableName...');
        return db.execute(
          'CREATE TABLE $_tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, type TEXT)',
        );
      },
    );
    debugPrint('Database initialized at $path');
    return db;
  }
}