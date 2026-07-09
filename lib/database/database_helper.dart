import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/transaction_model.dart';

/// A Singleton helper that owns the single SQLite connection for the app.
///
/// ── Tables ───────────────────────────────────────────────────────────────────
///   transactions  — all expense / income records
///   settings      — key-value store for user preferences (budget, etc.)
///
/// ── Path ─────────────────────────────────────────────────────────────────────
/// On Android: /data/data/com.example.finance_tracker/databases/radix_database.db
/// On iOS:     ~/Documents/radix_database.db
/// On web:     IndexedDB (via sqflite_common_ffi_web, factory set in main.dart)
///
/// This is a PHYSICAL file, NOT ':memory:'. Data survives app restarts.
class DatabaseHelper {
  // ─── Singleton wiring ──────────────────────────────────────────────────────

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // ─── Constants ──────────────────────────────────────────────────────────────

  static const String _dbFileName = 'radix_database.db';
  static const int _dbVersion = 2; // bumped from 1 → 2 to add settings table

  // ─── Database handle ───────────────────────────────────────────────────────

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ─── Initialisation ────────────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    try {
      final String dbPath = join(await getDatabasesPath(), _dbFileName);
      debugPrint('[DB] Opening database at: $dbPath');

      final db = await openDatabase(
        dbPath,
        version: _dbVersion,

        // Fresh install — create both tables from scratch.
        onCreate: (Database db, int version) async {
          debugPrint('[DB] onCreate — creating all tables (version $version).');
          await _createTransactionsTable(db);
          await _createSettingsTable(db);
          debugPrint('[DB] All tables created successfully.');
        },

        // Existing DB — add any missing tables for the new version.
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          debugPrint('[DB] onUpgrade — $oldVersion → $newVersion.');
          if (oldVersion < 2) {
            await _createSettingsTable(db);
            debugPrint('[DB] Added settings table (upgrade to v2).');
          }
        },
      );

      debugPrint('[DB] Database opened successfully (version $_dbVersion).');
      return db;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — Failed to initialise database: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ─── Table creation helpers ────────────────────────────────────────────────

  static Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        title           TEXT    NOT NULL,
        amount          REAL    NOT NULL,
        type            TEXT    NOT NULL,
        income_strategy TEXT,
        category        TEXT    NOT NULL,
        date            TEXT    NOT NULL
      )
    ''');
  }

  static Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSACTION CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inserts [transaction] into the DB.
  /// Returns the auto-assigned AUTOINCREMENT id.
  Future<int> insertTransaction(TransactionModel transaction) async {
    try {
      final Database db = await database;
      final int newId = await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      debugPrint('[DB] Inserted transaction → id: $newId');
      return newId;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — insertTransaction: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Returns all transactions, newest first.
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
      final transactions = rows.map(TransactionModel.fromMap).toList();
      debugPrint('[DB] Fetched ${transactions.length} transaction(s).');
      return transactions;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — getTransactions: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Updates title, amount, and category for [id].
  Future<int> updateTransaction({
    required int id,
    required String title,
    required double amount,
    required String category,
  }) async {
    try {
      final Database db = await database;
      final int rowsAffected = await db.update(
        'transactions',
        {'title': title, 'amount': amount, 'category': category},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('[DB] Updated transaction id: $id ($rowsAffected row(s))');
      return rowsAffected;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — updateTransaction: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Deletes the row with [id].
  Future<int> deleteTransaction(int id) async {
    try {
      final Database db = await database;
      final int rowsAffected = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('[DB] Deleted transaction id: $id ($rowsAffected row(s))');
      return rowsAffected;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — deleteTransaction: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SETTINGS (key-value store)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reads a setting value by [key]. Returns null if not found.
  Future<String?> getSetting(String key) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final value = rows.first['value'] as String;
      debugPrint('[DB] getSetting("$key") → "$value"');
      return value;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — getSetting("$key"): $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Writes a setting [key] = [value]. Overwrites if the key already exists.
  Future<void> setSetting(String key, String value) async {
    try {
      final Database db = await database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace, // upsert
      );
      debugPrint('[DB] setSetting("$key", "$value") ✓');
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — setSetting("$key"): $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }
}
