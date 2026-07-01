import 'package:flutter/material.dart';

class TransactionModel {
  final String id;
  String title;
  final double amount;
  String iconKey;
  final bool isExpense;
  final String?
  incomeAllocation; // 'budget' | 'spent' for income; null for expense

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.iconKey,
    required this.isExpense,
    this.incomeAllocation,
  });

  /// Returns the (background, foreground, badge) color triplet for this
  /// transaction type. Used by both the tile and the edit dialog.
  ({Color bg, Color fg, Color badge}) getColors() {
    if (isExpense) {
      return (
        bg: const Color(0xFFFFEBEE),
        fg: const Color(0xFFB71C1C),
        badge: const Color(0xFFC62828),
      );
    } else {
      return (
        bg: const Color(0xFFE8F5E9),
        fg: const Color(0xFF1B5E20),
        badge: const Color(0xFF2E7D32),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'iconKey': iconKey,
      'isExpense': isExpense ? 1 : 0,
      'incomeAllocation': incomeAllocation,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: map['amount'] as double,
      iconKey: map['iconKey'] as String,
      isExpense: (map['isExpense'] as int) == 1,
      incomeAllocation: map['incomeAllocation'] as String?,
    );
  }
}
