import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final IconData icon;

  const CategoryInfo({required this.name, required this.icon});
}

const Map<String, CategoryInfo> categoryRegistry = {
  'fastfood': CategoryInfo(name: 'Food', icon: Icons.fastfood_outlined),
  'shopping_bag': CategoryInfo(
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
  ),
  'directions_car': CategoryInfo(
    name: 'Transport',
    icon: Icons.directions_car_filled_outlined,
  ),
  'home': CategoryInfo(name: 'Utilities', icon: Icons.home_outlined),
  'celebration': CategoryInfo(
    name: 'Entertainment',
    icon: Icons.celebration_outlined,
  ),
  'payments': CategoryInfo(name: 'Payments', icon: Icons.payments_outlined),
  'work': CategoryInfo(name: 'Work', icon: Icons.work_outline),
  'school': CategoryInfo(name: 'Education', icon: Icons.school_outlined),
  'flight': CategoryInfo(name: 'Travel', icon: Icons.flight_outlined),
  'fitness_center': CategoryInfo(
    name: 'Fitness',
    icon: Icons.fitness_center_outlined,
  ),
  'health_and_safety': CategoryInfo(
    name: 'Health',
    icon: Icons.health_and_safety_outlined,
  ),
  'pets': CategoryInfo(name: 'Pets', icon: Icons.pets_outlined),
  'local_gas_station': CategoryInfo(
    name: 'Gas',
    icon: Icons.local_gas_station_outlined,
  ),
  'train': CategoryInfo(name: 'Transit', icon: Icons.train_outlined),
};

// Fallback for empty or unknown category keys
const CategoryInfo otherCategory = CategoryInfo(
  name: 'Other',
  icon: Icons.widgets_outlined,
);

class AggregatedCategory {
  final String iconKey;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;

  const AggregatedCategory({
    required this.iconKey,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });
}
