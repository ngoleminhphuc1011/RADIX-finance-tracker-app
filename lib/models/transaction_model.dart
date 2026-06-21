class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String iconKey;
  final bool isExpense;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.iconKey,
    required this.isExpense,
  });
}
