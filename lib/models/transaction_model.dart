import 'package:flutter/material.dart';
import '../core/theme/app_color_locker.dart';

/// Represents a single financial transaction stored in the local SQLite DB.
///
/// Field notes:
/// - [id] is nullable because it is assigned by SQLite (AUTOINCREMENT).
///   When you build a new object to *insert*, leave id as null.
///   After insertion, SQLite gives it an integer id.
/// - [type] is either 'expense' or 'income'.
/// - [incomeStrategy] is only relevant for income transactions:
///     'add_to_budget'      → the income increases the available budget.
///     'deduct_from_spent'  → the income cancels out recorded spending.
///   It is null for all expense transactions.
/// - [date] is stored as a formatted string: "yyyy-MM-dd".
class TransactionModel {
  final int? id; // null before first DB insert
  final String title;
  final double amount;
  final String type; // 'expense' | 'income'
  final String? incomeStrategy; // 'add_to_budget' | 'deduct_from_spent' | null
  final String category;
  final String date; // ISO8601 string

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.incomeStrategy,
    required this.category,
    String? date,
  }) : date = _parseAndFormat(date ?? '');

  // ─── Convenience getter ────────────────────────────────────────────────────

  /// True when this transaction is an expense.
  bool get isExpense => type == 'expense';

  // ─── Color helper (kept from previous version) ─────────────────────────────

  /// Returns the (background, foreground, badge) color triplet for this
  /// transaction type. Used by both the tile and the edit dialog.
  ({Color bg, Color fg, Color badge}) getColors(BuildContext context) {
    final locker = AppColorLocker.of(context);
    if (isExpense) {
      return (
        bg: locker.expenseModelBg,
        fg: locker.expenseModelFg,
        badge: locker.expenseModelBadge,
      );
    } else {
      return (
        bg: locker.incomeModelBg,
        fg: locker.incomeModelFg,
        badge: locker.incomeModelBadge,
      );
    }
  }

  // ─── Serialisation ─────────────────────────────────────────────────────────

  /// Converts the model to a Map that sqflite can insert/update.
  /// We intentionally exclude [id] here: if it is null (new record), sqflite
  /// must not pass it so that AUTOINCREMENT can do its job.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'type': type,
      'income_strategy': incomeStrategy, // null is fine — stored as NULL in DB
      'category': category,
      'date': date,
    };

    // Only add id when we already have one (i.e. for updates, not inserts).
    if (id != null) map['id'] = id;

    return map;
  }

  /// Reconstructs a [TransactionModel] from a sqflite row Map.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final double rawAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final double cleanAmount =
        (rawAmount < 0 || rawAmount.isNaN || rawAmount.isInfinite)
            ? 0.0
            : rawAmount;
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled',
      amount: cleanAmount,
      type: map['type'] as String? ?? 'expense',
      incomeStrategy: map['income_strategy'] as String?,
      category: map['category'] as String? ?? '',
      date: map['date'] as String? ?? '',
    );
  }

  /// Returns a copy with selected fields overridden.
  /// Useful for UI edit flows where you want to change one field at a time.
  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    String? incomeStrategy,
    String? category,
    String? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      incomeStrategy: incomeStrategy ?? this.incomeStrategy,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, '
        'type: $type, incomeStrategy: $incomeStrategy, '
        'category: $category, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.type == type &&
        other.incomeStrategy == incomeStrategy &&
        other.category == category &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        amount,
        type,
        incomeStrategy,
        category,
        date,
      );
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _parseAndFormat(String rawDate) {
  if (rawDate.isEmpty) return _formatDate(DateTime.now());
  if (rawDate.length >= 10 && rawDate[4] == '-' && rawDate[7] == '-') {
    return rawDate.substring(0, 10);
  }
  final parsed = DateTime.tryParse(rawDate);
  if (parsed != null) {
    return _formatDate(parsed);
  }
  return rawDate;
}
