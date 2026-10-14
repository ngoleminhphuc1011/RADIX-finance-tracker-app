import 'package:flutter/material.dart';

abstract class AppColorLocker {
  const AppColorLocker();

  // Scaffold & backgrounds
  Color get scaffoldBackground;
  Color get navBarBackground;
  Color get cardBackground;
  Color get searchBarBackground;
  Color get capsuleBackground;
  Color get gridItemBackground;

  // Text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textOnDark;
  Color get textOnLight;
  Color get textDialogTitle;

  // Accents
  Color get accentRed;
  Color get accentGreen;
  Color get focusBorder;

  // Overlays / Dialogs
  Color get barrierColor;
  Color get barrierColorLight;
  Color get dialogBackground;
  Color get dialogBorder;
  Color get dialogShadow30;
  Color get dialogShadow60;
  Color get shadowLight;

  // Nav indicator
  Color get navIndicatorBackground;
  Color get navActiveCapsuleBg;
  Color get navActiveCapsuleBorder;
  Color get navActiveFg;
  Color get navInactiveFg;
  Color get frostedGlassBg;
  Color get frostedGlassBorder;

  // Transaction specific colors
  Color get expenseBg;
  Color get expenseFg;
  Color get expenseBadge;
  Color get expenseBorder;

  Color get incomeBg;
  Color get incomeFg;
  Color get incomeBadge;
  Color get incomeBorder;

  Color getTransactionBorder({required bool isExpense}) =>
      isExpense ? expenseBorder : incomeBorder;

  // Icon picker tokens (synchronized with app accents)
  Color get iconPickerExpenseAccent;
  Color get iconPickerIncomeAccent;
  Color get iconPickerExpenseBg;
  Color get iconPickerIncomeBg;
  Color get iconPickerExpenseBorder;
  Color get iconPickerIncomeBorder;

  Color getIconPickerAccent({required bool isExpense}) =>
      isExpense ? iconPickerExpenseAccent : iconPickerIncomeAccent;

  Color getIconPickerBg({required bool isExpense}) =>
      isExpense ? iconPickerExpenseBg : iconPickerIncomeBg;

  Color getIconPickerBorder({required bool isExpense}) =>
      isExpense ? iconPickerExpenseBorder : iconPickerIncomeBorder;

  Color get incomeStrategyDeductBg;
  Color get incomeStrategyDeductFg;
  Color get budgetCardBorderNormal;

  // Settings screen specific colors
  Color get settingsBackground;
  Color get settingsTitle;
  Color get settingsSectionLabel;
  Color get settingsInfoText;
  Color get settingsCapsuleBarBackground;
  Color get settingsActiveCapsuleLight;
  Color get settingsActiveCapsuleSystemLight;
  Color get settingsActiveCapsuleSystemDark;
  Color get settingsActiveCapsuleDark;
  Color get settingsCurrencySymbol;
  Color get graphBackground;

  // Cards, sheets, toasts & surfaces
  Color get settingsCardBackground;
  Color get settingsCardBorder;
  Color get settingsModalTileBackground;
  Color get settingsBadgeBackground;
  Color get settingsBadgeBorder;
  Color get sheetBackground;
  Color get sheetBorder;
  Color get navBarShadow;
  Color get toastBackground;
  Color get toastText;
  Color get toastShadow;
  Color get dividerColor;

  // Currency tile specific colors
  Color get settingsCurrencySelectedStart;
  Color get settingsCurrencySelectedEnd;
  Color get settingsCurrencySelectedBorder;
  Color get settingsCurrencySelectedText;
  Color get settingsCurrencyUnselectedBg;
  Color get settingsCurrencyUnselectedBorder;
  Color get settingsCurrencyUnselectedText;
  Color get settingsCurrencyUnselectedSymbol;

  // Dialog and delete button colors
  Color get deleteButtonBg;
  Color get expenseDialogAccent;
  Color get incomeDialogAccent;
  Color get expenseDialogText;
  Color get incomeDialogText;

  // Model-level transaction colors
  Color get expenseModelBg;
  Color get expenseModelFg;
  Color get expenseModelBadge;
  Color get incomeModelBg;
  Color get incomeModelFg;
  Color get incomeModelBadge;

  // Category visual colors (Graph & Category Grid)
  Color get catFood;
  Color get catShopping;
  Color get catTransport;
  Color get catUtilities;
  Color get catEntertainment;
  Color get catPayments;
  Color get catWork;
  Color get catEducation;
  Color get catTravel;
  Color get catFitness;
  Color get catHealth;
  Color get catPets;
  Color get catGas;
  Color get catTransit;
  Color get catOther;

  // Instruction screen specific colors
  Color get instructionIconColor;
  Color get instructionWarningColor;
  Color get instructionBodyColor;

  Color getCategoryColor(String key) {
    switch (key) {
      case 'fastfood':
        return catFood;
      case 'shopping_bag':
        return catShopping;
      case 'directions_car':
        return catTransport;
      case 'home':
        return catUtilities;
      case 'celebration':
        return catEntertainment;
      case 'payments':
        return catPayments;
      case 'work':
        return catWork;
      case 'school':
        return catEducation;
      case 'flight':
        return catTravel;
      case 'fitness_center':
        return catFitness;
      case 'health_and_safety':
        return catHealth;
      case 'pets':
        return catPets;
      case 'local_gas_station':
        return catGas;
      case 'train':
        return catTransit;
      default:
        return catOther;
    }
  }

  static AppColorLocker of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const DarkColorLocker() : const LightColorLocker();
  }
}

class LightColorLocker extends AppColorLocker {
  const LightColorLocker();

  @override
  Color get scaffoldBackground => const Color(0xFFF5F0EB);

  @override
  Color get navBarBackground => Colors.white;

  @override
  Color get cardBackground => Colors.white;

  @override
  Color get searchBarBackground => const Color(0xFFE2E2E2);

  @override
  Color get capsuleBackground => const Color(0xFFE2E2E2);

  @override
  Color get gridItemBackground => const Color(0xFFF5F5F5);

  @override
  Color get textPrimary => Colors.black;

  @override
  Color get textSecondary => Colors.black54;

  @override
  Color get textTertiary => Colors.grey;

  @override
  Color get textOnDark => Colors.white;

  @override
  Color get textOnLight => Colors.black;

  @override
  Color get textDialogTitle => const Color(0xFF3A3A3C);

  @override
  Color get accentRed => const Color(0xFFE57373);

  @override
  Color get accentGreen => const Color(0xFF81C784);

  @override
  Color get focusBorder => const Color(0xFF00E676);

  @override
  Color get barrierColor => const Color(0x66000000);

  @override
  Color get barrierColorLight => const Color(0x4D000000);

  @override
  Color get dialogBackground => Colors.white;

  @override
  Color get dialogBorder => const Color(0xFFE2E2E2);

  @override
  Color get dialogShadow30 => Colors.black.withValues(alpha: 0.08);

  @override
  Color get dialogShadow60 => Colors.black.withValues(alpha: 0.04);

  @override
  Color get shadowLight => const Color(0x14000000);

  @override
  Color get navIndicatorBackground => const Color(0xFFCFE3FB);

  @override
  Color get navActiveCapsuleBg => const Color(0xFFE3F2FD);

  @override
  Color get navActiveCapsuleBorder =>
      const Color(0xFF1976D2).withValues(alpha: 0.25);

  @override
  Color get navActiveFg => const Color(0xFF0D47A1);

  @override
  Color get navInactiveFg =>
      const Color(0xFF090A0C).withValues(alpha: 0.45);

  @override
  Color get frostedGlassBg => Colors.white.withValues(alpha: 0.50);

  @override
  Color get frostedGlassBorder => Colors.black.withValues(alpha: 0.08);

  @override
  Color get expenseBg => const Color(0xFFFFEBEE);

  @override
  Color get expenseFg => const Color(0xFF78281F);

  @override
  Color get expenseBadge => const Color(0xFFC62828);

  @override
  Color get expenseBorder => const Color(0xFFD32F2F).withValues(alpha: 0.18);

  @override
  Color get incomeBg => const Color(0xFFE8F5E9);

  @override
  Color get incomeFg => const Color(0xFF117A65);

  @override
  Color get incomeBadge => const Color(0xFF2E7D32);

  @override
  Color get incomeBorder => const Color(0xFF2E7D32).withValues(alpha: 0.18);

  @override
  Color get iconPickerExpenseAccent => const Color(0xFFE57373);

  @override
  Color get iconPickerIncomeAccent => const Color(0xFF81C784);

  @override
  Color get iconPickerExpenseBg =>
      const Color(0xFFE57373).withValues(alpha: 0.15);

  @override
  Color get iconPickerIncomeBg =>
      const Color(0xFF81C784).withValues(alpha: 0.15);

  @override
  Color get iconPickerExpenseBorder =>
      const Color(0xFFE57373).withValues(alpha: 0.35);

  @override
  Color get iconPickerIncomeBorder =>
      const Color(0xFF81C784).withValues(alpha: 0.35);

  @override
  Color get incomeStrategyDeductBg => const Color(0xFFD8E0F7);

  @override
  Color get incomeStrategyDeductFg => const Color(0xFF4C8CB4);

  @override
  Color get budgetCardBorderNormal => const Color(0xFFA3E4D7);

  @override
  Color get settingsBackground => const Color(0xFFF5F0EB);

  @override
  Color get settingsTitle => const Color(0xFF1C1C1E);

  @override
  Color get settingsSectionLabel => const Color(0xFF636366);

  @override
  Color get settingsInfoText => const Color(0xFF8E8E93);

  @override
  Color get settingsCapsuleBarBackground => const Color(0xFFE2E2E2);

  @override
  Color get settingsActiveCapsuleLight => Colors.white;

  @override
  Color get settingsActiveCapsuleSystemLight => const Color(0xFFB0B0B5);

  @override
  Color get settingsActiveCapsuleSystemDark => const Color(0xFF18181B);

  @override
  Color get settingsActiveCapsuleDark => const Color(0xFF1C1C1E);

  @override
  Color get settingsCurrencySymbol => const Color(0xFF3A3A3C);

  @override
  Color get settingsCurrencySelectedStart => const Color(0xFFFFF6D6);

  @override
  Color get settingsCurrencySelectedEnd => const Color(0xFFFFF6D6);

  @override
  Color get settingsCurrencySelectedBorder => const Color(0xFFE5C158);

  @override
  Color get settingsCurrencySelectedText => const Color(0xFF5C4314);

  @override
  Color get settingsCurrencyUnselectedBg => Colors.white;

  @override
  Color get settingsCurrencyUnselectedBorder => const Color(0xFFE5E5EA);

  @override
  Color get settingsCurrencyUnselectedText => const Color(0xFF1C1C1E);

  @override
  Color get settingsCurrencyUnselectedSymbol => const Color(0xFF3A3A3C);

  @override
  Color get graphBackground => const Color(0xFFF5F0EB);

  @override
  Color get settingsCardBackground => Colors.white;

  @override
  Color get settingsCardBorder => const Color(0xFFE5E5EA);

  @override
  Color get settingsModalTileBackground => const Color(0xFFF7F7FA);

  @override
  Color get settingsBadgeBackground => const Color(0xFFF2F2F7);

  @override
  Color get settingsBadgeBorder => const Color(0xFFE5E5EA);

  @override
  Color get sheetBackground => Colors.white.withValues(alpha: 0.96);

  @override
  Color get sheetBorder => Colors.black.withValues(alpha: 0.08);

  @override
  Color get navBarShadow => Colors.black.withValues(alpha: 0.08);

  @override
  Color get toastBackground => Colors.white.withValues(alpha: 0.98);

  @override
  Color get toastText => const Color(0xFF131518);

  @override
  Color get toastShadow => Colors.black.withValues(alpha: 0.08);

  @override
  Color get dividerColor => Colors.black.withValues(alpha: 0.06);

  @override
  Color get deleteButtonBg => const Color(0xFFC62828);

  @override
  Color get expenseDialogAccent => const Color(0xFFE57373);

  @override
  Color get incomeDialogAccent => const Color(0xFF81C784);

  @override
  Color get expenseDialogText => const Color(0xFF78281F);

  @override
  Color get incomeDialogText => const Color(0xFF117A65);

  @override
  Color get expenseModelBg => const Color(0xFFFFEBEE);

  @override
  Color get expenseModelFg => const Color(0xFFB71C1C);

  @override
  Color get expenseModelBadge => const Color(0xFFC62828);

  @override
  Color get incomeModelBg => const Color(0xFFE8F5E9);

  @override
  Color get incomeModelFg => const Color(0xFF1B5E20);

  @override
  Color get incomeModelBadge => const Color(0xFF2E7D32);

  @override
  Color get catFood => const Color(0xFFFF8B94);
  @override
  Color get catShopping => const Color(0xFFFFD3B6);
  @override
  Color get catTransport => const Color(0xFFD4A5A5);
  @override
  Color get catUtilities => const Color(0xFF9FFFCB);
  @override
  Color get catEntertainment => const Color(0xFFC7CEEA);
  @override
  Color get catPayments => const Color(0xFFFFF3B0);
  @override
  Color get catWork => const Color(0xFFB3D9FF);
  @override
  Color get catEducation => const Color(0xFFB8B3E6);
  @override
  Color get catTravel => const Color(0xFFFFB3A7);
  @override
  Color get catFitness => const Color(0xFFB2DFDB);
  @override
  Color get catHealth => const Color(0xFFD5E8D4);
  @override
  Color get catPets => const Color(0xFFFFCCAA);
  @override
  Color get catGas => const Color(0xFFD6D6D6);
  @override
  Color get catTransit => const Color(0xFFAEC6CF);
  @override
  Color get catOther => const Color(0xFFE2E8F0);

  @override
  Color get instructionIconColor => const Color(0xFF81C784); // accentGreen
  @override
  Color get instructionWarningColor => const Color(0xFFE57373); // accentRed
  @override
  Color get instructionBodyColor => Colors.black.withValues(alpha: 0.8);
}

class DarkColorLocker extends AppColorLocker {
  const DarkColorLocker();

  @override
  Color get scaffoldBackground => const Color(0xFF090A0C);

  @override
  Color get navBarBackground => const Color.fromARGB(255, 39, 41, 44);

  @override
  Color get cardBackground => const Color(0xFF131518);

  @override
  Color get searchBarBackground => const Color(0xFF1E2126);

  @override
  Color get capsuleBackground => const Color(0xFF1E2126);

  @override
  Color get gridItemBackground => const Color(0xFF1A1C20);

  @override
  Color get textPrimary => const Color(0xFFECEFF1);

  @override
  Color get textSecondary => const Color(0xFF90A4AE);

  @override
  Color get textTertiary => const Color(0xFF546E7A);

  @override
  Color get textOnDark => const Color(0xFF090A0C);

  @override
  Color get textOnLight => const Color(0xFFECEFF1);

  @override
  Color get textDialogTitle => const Color(0xFFECEFF1);

  @override
  Color get accentRed => const Color(0xFFE28F8F);

  @override
  Color get accentGreen => const Color(0xFF8CD4B4);

  @override
  Color get focusBorder => const Color(0xFF4DB6AC);

  @override
  Color get dialogBackground => const Color(0xFF131518);

  @override
  Color get dialogBorder => const Color(0xFF22262B);

  @override
  Color get dialogShadow30 => Colors.transparent;

  @override
  Color get dialogShadow60 => Colors.transparent;

  @override
  Color get barrierColor => const Color(0xAA000000);

  @override
  Color get barrierColorLight => const Color(0x77000000);

  @override
  Color get shadowLight => Colors.transparent;

  @override
  Color get navIndicatorBackground => const Color.fromARGB(255, 222, 236, 253);

  @override
  Color get navActiveCapsuleBg =>
      const Color(0xFF2979FF).withValues(alpha: 0.24);

  @override
  Color get navActiveCapsuleBorder =>
      const Color(0xFF2979FF).withValues(alpha: 0.40);

  @override
  Color get navActiveFg => const Color(0xFFE3F2FD);

  @override
  Color get navInactiveFg => Colors.white.withValues(alpha: 0.45);

  @override
  Color get frostedGlassBg => Colors.white.withValues(alpha: 0.18);

  @override
  Color get frostedGlassBorder => Colors.white.withValues(alpha: 0.20);

  @override
  Color get expenseBg => const Color(0xFF2A1C1C);

  @override
  Color get expenseFg => const Color(0xFFE28F8F);

  @override
  Color get expenseBadge => const Color(0xFFE57373);

  @override
  Color get expenseBorder => const Color(0xFFFF5252).withValues(alpha: 0.28);

  @override
  Color get incomeBg => const Color(0xFF14241E);

  @override
  Color get incomeFg => const Color(0xFF8CD4B4);

  @override
  Color get incomeBadge => const Color(0xFF81C784);

  @override
  Color get incomeBorder => const Color(0xFF00E676).withValues(alpha: 0.28);

  @override
  Color get iconPickerExpenseAccent => const Color(0xFFE57373);

  @override
  Color get iconPickerIncomeAccent => const Color(0xFF81C784);

  @override
  Color get iconPickerExpenseBg =>
      const Color(0xFFE57373).withValues(alpha: 0.16);

  @override
  Color get iconPickerIncomeBg =>
      const Color(0xFF81C784).withValues(alpha: 0.16);

  @override
  Color get iconPickerExpenseBorder =>
      const Color(0xFFE57373).withValues(alpha: 0.40);

  @override
  Color get iconPickerIncomeBorder =>
      const Color(0xFF81C784).withValues(alpha: 0.40);

  @override
  Color get incomeStrategyDeductBg => const Color(0xFF20272F);

  @override
  Color get incomeStrategyDeductFg => const Color(0xFF64B5F6);

  @override
  Color get budgetCardBorderNormal => const Color(0xFF204A3F);

  @override
  Color get settingsBackground => const Color(0xFF090A0C);

  @override
  Color get settingsTitle => const Color(0xFFECEFF1);

  @override
  Color get settingsSectionLabel => const Color(0xFF90A4AE);

  @override
  Color get settingsInfoText => const Color(0xFF546E7A);

  @override
  Color get settingsCapsuleBarBackground => const Color(0xFF131518);

  @override
  Color get settingsActiveCapsuleLight => const Color(0xFF1E2126);

  @override
  Color get settingsActiveCapsuleSystemLight => const Color(0xFF1E2126);

  @override
  Color get settingsActiveCapsuleSystemDark => const Color(0xFF1E2126);

  @override
  Color get settingsActiveCapsuleDark => const Color(0xFF1E2126);

  @override
  Color get settingsCurrencySymbol => const Color(0xFF90A4AE);

  @override
  Color get settingsCurrencySelectedStart => const Color(0xFFE5C158);

  @override
  Color get settingsCurrencySelectedEnd => const Color(0xFFC59F3F);

  @override
  Color get settingsCurrencySelectedBorder => const Color(0xFFF3D078);

  @override
  Color get settingsCurrencySelectedText => const Color(0xFF090A0C);

  @override
  Color get settingsCurrencyUnselectedBg => const Color(0xFF131518);

  @override
  Color get settingsCurrencyUnselectedBorder => const Color(0xFF1C1E22);

  @override
  Color get settingsCurrencyUnselectedText => const Color(0xFFECEFF1);

  @override
  Color get settingsCurrencyUnselectedSymbol => const Color(0xFF90A4AE);

  @override
  Color get graphBackground => const Color(0xFF090A0C);

  @override
  Color get settingsCardBackground => const Color(0xFF131518);

  @override
  Color get settingsCardBorder => const Color(0xFF22262B);

  @override
  Color get settingsModalTileBackground => const Color(0xFF131518);

  @override
  Color get settingsBadgeBackground => const Color(0xFF1E2126);

  @override
  Color get settingsBadgeBorder => const Color(0xFF2B2F36);

  @override
  Color get sheetBackground => const Color(0xFF131518).withValues(alpha: 0.95);

  @override
  Color get sheetBorder => Colors.white.withValues(alpha: 0.12);

  @override
  Color get navBarShadow => Colors.black.withValues(alpha: 0.35);

  @override
  Color get toastBackground => const Color(0xFF1E2024).withValues(alpha: 0.96);

  @override
  Color get toastText => const Color(0xFFECEFF1);

  @override
  Color get toastShadow => Colors.black.withValues(alpha: 0.28);

  @override
  Color get dividerColor => Colors.white.withValues(alpha: 0.08);

  @override
  Color get deleteButtonBg => const Color(0xFFC62828);

  @override
  Color get expenseDialogAccent => const Color(0xFFE57373);

  @override
  Color get incomeDialogAccent => const Color(0xFF81C784);

  @override
  Color get expenseDialogText => Colors.white;

  @override
  Color get incomeDialogText => Colors.white;

  @override
  Color get expenseModelBg => const Color(0xFF2A1C1C);

  @override
  Color get expenseModelFg => const Color(0xFFE28F8F);

  @override
  Color get expenseModelBadge => const Color(0xFFE57373);

  @override
  Color get incomeModelBg => const Color(0xFF14241E);

  @override
  Color get incomeModelFg => const Color(0xFF8CD4B4);

  @override
  Color get incomeModelBadge => const Color(0xFF81C784);

  @override
  Color get catFood => const Color(0xFFE5989B);

  @override
  Color get catShopping => const Color(0xFFFFB7B2);

  @override
  Color get catTransport => const Color(0xFFC9A2A2);

  @override
  Color get catUtilities => const Color(0xFFB5EAD7);

  @override
  Color get catEntertainment => const Color(0xFFC7CEEA);

  @override
  Color get catPayments => const Color(0xFFFFDAC1);

  @override
  Color get catWork => const Color(0xFFB2C9E8);

  @override
  Color get catEducation => const Color(0xFFC3BBEB);

  @override
  Color get catTravel => const Color(0xFFFFC6FF);

  @override
  Color get catFitness => const Color(0xFFBFFCC6);

  @override
  Color get catHealth => const Color(0xFFE2F0CB);

  @override
  Color get catPets => const Color(0xFFFFE5D9);

  @override
  Color get catGas => const Color(0xFFEAEAEA);

  @override
  Color get catTransit => const Color(0xFFAEC6CF);

  @override
  Color get catOther => const Color(0xFFCFD8DC);

  @override
  Color get instructionIconColor => const Color(0xFF8CD4B4); // accentGreen
  @override
  Color get instructionWarningColor => const Color(0xFFE28F8F); // accentRed
  @override
  Color get instructionBodyColor =>
      const Color(0xFFECEFF1).withValues(alpha: 0.8);
}
