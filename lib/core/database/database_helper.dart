import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/transaction_model.dart';
import '../theme/currency_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DatabaseHelper: SQLite Storage & Persistence Layer
//
// Flutter Architecture Pattern (Database Singleton):
// - Singleton Instance: Only ONE connection pool exists across the app,
//   preventing database file locks or race conditions.
// - Lazy Connection: The database is opened on first query via `await database`.
// - Cross-Platform Storage:
//   * Android: /data/data/com.example.finance_tracker/databases/radix_database.db
//   * iOS:     ~/Documents/radix_database.db
//   * Web:     IndexedDB (via sqflite_common_ffi_web)
// ═══════════════════════════════════════════════════════════════════════════════

class DatabaseHelper {
  // ─── Section 1: Singleton Pattern & Lazy Connection Handle ───────────────────

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _dbFileName = 'radix_database.db';
  static const int _dbVersion = 2; // Version 2 added 'settings' key-value table

  static Database? _database;

  /// Returns the active SQLite connection, opening it if not yet initialized.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ─── Section 2: Database Initialization & Version Migrations ─────────────────

  Future<Database> _initDatabase() async {
    try {
      final String dbPath = join(await getDatabasesPath(), _dbFileName);

      final db = await openDatabase(
        dbPath,
        version: _dbVersion,

        // Fresh install — create both tables from scratch.
        onCreate: (Database db, int version) async {
          await _createTransactionsTable(db);
          await _createSettingsTable(db);
        },

        // Existing DB — add any missing tables for the new version.
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          if (oldVersion < 2) {
            await _createSettingsTable(db);
          }
        },
      );

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

  // ─── Section 3: Transactions Table CRUD ─────────────────────────────────────

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
      int rowsAffected = 0;
      await db.transaction((txn) async {
        rowsAffected = await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
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

  /// Deletes all transactions and resets the monthly budget to 0.0.
  /// Keeps other settings like theme and currency intact.
  Future<void> resetDataKeepSettings() async {
    try {
      final Database db = await database;
      await db.transaction((txn) async {
        // 1. Delete all transactions
        await txn.delete('transactions');

        // 2. Delete monthly budget setting
        await txn.delete(
          'settings',
          where: 'key = ?',
          whereArgs: ['monthly_budget'],
        );
      });
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — resetDataKeepSettings: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  // ─── Section 4: Settings Key-Value Store ────────────────────────────────────

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
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — setSetting("$key"): $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Reads all settings into a key-value Map.
  Future<Map<String, String>> getAllSettings() async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> rows = await db.query('settings');
      final Map<String, String> result = {};
      for (final row in rows) {
        final key = row['key'] as String?;
        final val = row['value'] as String?;
        if (key != null && val != null) {
          result[key] = val;
        }
      }
      return result;
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — getAllSettings: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      return {};
    }
  }

  // ─── Section 5: Atomic Batch Transactions & Data Conversion ─────────────────

  /// Restores all transactions and settings atomically inside a single SQLite transaction.
  /// If any error occurs during restoration, all changes are automatically rolled back.
  Future<void> restoreFromBackupData(Map<String, dynamic> backupData) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        // 1. Wipe old transactions
        await txn.delete('transactions');

        // 2. Insert transactions
        final dynamic rawTxs = backupData['transactions'];
        if (rawTxs is List) {
          for (final item in rawTxs) {
            if (item is Map) {
              final title = item['title']?.toString() ?? 'Untitled';
              final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
              final type = item['type']?.toString() ?? 'expense';
              final incomeStrategy = item['income_strategy']?.toString();
              final category = item['category']?.toString() ?? 'fastfood';
              final date =
                  item['date']?.toString() ??
                  DateTime.now().toIso8601String().substring(0, 10);

              await txn.insert('transactions', {
                'title': title,
                'amount': amount,
                'type': type,
                'income_strategy': incomeStrategy,
                'category': category,
                'date': date,
              });
            }
          }
        }

        // 3. Restore settings
        final dynamic rawSettings = backupData['settings'];
        if (rawSettings is Map) {
          for (final entry in rawSettings.entries) {
            await txn.insert('settings', {
              'key': entry.key.toString(),
              'value': entry.value.toString(),
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — restoreFromBackupData: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Converts all transactions and the monthly budget from one currency to another.
  /// Runs inside a database transaction to ensure safety and atomicity.
  Future<void> convertAllTransactionsAndBudget(
    String fromCode,
    String toCode,
  ) async {
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return;

    try {
      final db = await database;
      final double fromRate =
          CurrencyInfo.exchangeRates[fromCode.toUpperCase()] ?? 1.0;
      final double toRate =
          CurrencyInfo.exchangeRates[toCode.toUpperCase()] ?? 1.0;
      final double factor = fromRate > 0 ? (toRate / fromRate) : 1.0;

      await db.transaction((txn) async {
        // 1. Convert all transaction amounts
        final List<Map<String, dynamic>> rows = await txn.query('transactions');
        for (final row in rows) {
          final int id = row['id'] as int;
          final double originalAmount = (row['amount'] as num).toDouble();
          double convertedAmount = (originalAmount * factor).roundToDouble();
          if (convertedAmount < 0 ||
              convertedAmount.isNaN ||
              convertedAmount.isInfinite) {
            convertedAmount = 0.0;
          }
          await txn.update(
            'transactions',
            {'amount': convertedAmount},
            where: 'id = ?',
            whereArgs: [id],
          );
        }

        // 2. Convert monthly_budget
        final List<Map<String, dynamic>> budgetRows = await txn.query(
          'settings',
          where: 'key = ?',
          whereArgs: ['monthly_budget'],
        );
        if (budgetRows.isNotEmpty) {
          final double originalBudget =
              double.tryParse(budgetRows.first['value'] as String) ?? 0.0;
          double convertedBudget = (originalBudget * factor).roundToDouble();
          if (convertedBudget < 0 ||
              convertedBudget.isNaN ||
              convertedBudget.isInfinite) {
            convertedBudget = 0.0;
          }
          await txn.update(
            'settings',
            {'value': convertedBudget.toString()},
            where: 'key = ?',
            whereArgs: ['monthly_budget'],
          );
        }
      });
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR — convertAllTransactionsAndBudget: $e');
      debugPrint('[DB] StackTrace: $stackTrace');
      rethrow;
    }
  }
}
