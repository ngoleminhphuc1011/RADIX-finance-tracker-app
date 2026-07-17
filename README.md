# 📊 RADIX — Premium Personal Finance Tracker

<p align="center">
  <img src="assets/images/logo/LOGORADIX.png" alt="RADIX Logo" width="120" height="120" style="border-radius: 20%;" />
</p>

<p align="center">
  <strong>A premium, minimalist, and highly responsive personal finance application built with Flutter.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/SQLite-Sqflite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge" alt="Platforms" />
</p>

---

## 🌟 Introduction

**RADIX** is a personal finance tracker designed with rich aesthetics and premium performance in mind. Featuring a **Crisp Apple Minimalist White** light mode and a **Luxury Dark Mode**, RADIX delivers smooth micro-animations, customizable typography (`Monument Extended`, `Font Ultra`), and complete offline database capabilities. 

This is my first programming project, developed with care to manage expenses, budget allocations, and visual analytics seamlessly.

---

## ✨ Features

- **📝 Daily Transaction Tracker**
  - Quickly log daily income and expenses.
  - Categorize entries with custom pre-defined visual icons (Food, Shopping, Transport, Utilities, Entertainment, Health, and more).
  - Search, filter, and sort transactions instantly.

- **🎯 Smart Budgeting & Allocation**
  - Set a monthly budget and track progress dynamically.
  - Interactive displays showcasing spent amount, budget left, and progress percentage.

- **📈 Advanced Cash Flow Charts**
  - Interactive bar charts and pie charts powered by `fl_chart` to visualize category distributions and cash flow trends.
  - High-performance memoization cache for grouped transactions to ensure 60 FPS scrolling.

- **💱 Real-Time Multi-Currency Conversion**
  - Swap active currencies instantly (USD, EUR, CNY, VND, GBP, JPY, AUD, CAD).
  - When changing the base currency, **RADIX automatically converts all historical transaction records** and active budgets in the database.

- **🎨 Premium Visual Themes & Micro-Animations**
  - **Crisp Apple Minimalist White** (Light Theme) & **Luxury Dark Theme**.
  - Dynamic loading animations, clockwise sequential loading loops, and slide transitions.
  - Press-and-hold gestures for destructive actions (e.g. holding to reset data) with progress indicators.

---

## 🛠️ Tech Stack & Key Libraries

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Database:** [sqflite](https://pub.dev/packages/sqflite) (Native SQLite) & [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) (IndexedDB + WebAssembly SQLite for Web compatibility).
- **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart) for smooth and interactive charting.
- **Localization & Formatting:** [intl](https://pub.dev/packages/intl).
- **Fonts:** Custom typography with Google Fonts and local font assets (`MonumentExtended`, `FontUltra`).

---

## 📂 Project Architecture

```
lib/
├── database/
│   └── database_helper.dart      # Singleton class managing local SQLite DB / Web IndexedDB
├── models/
│   └── transaction_model.dart    # Transaction schema and model helpers
├── screens/
│   ├── splash_screen.dart        # Dynamic entry screen with custom logo & dot animations
│   ├── nav_wrapper.dart          # Root navigation layout
│   ├── home_screen.dart          # Transaction log, budget slider, and allocation dialogs
│   ├── graph_screen.dart         # fl_chart implementations for expenses and analytics
│   ├── settings_screen.dart      # Theme switcher, currency options, and hold-to-reset
│   └── instruction_screen.dart   # Interactive tutorial page
├── theme/
│   ├── app_theme.dart            # Light and Dark theme configurations
│   ├── app_color_locker.dart     # Centralized color palettes
│   ├── theme_provider.dart       # ValueNotifier-based theme state
│   └── currency_provider.dart    # ValueNotifier-based currency state
└── main.dart                     # Application bootstrap and initialization
```

---

## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites

- Ensure you have [Flutter SDK installed](https://docs.flutter.dev/get-started/install).
- A device/emulator (Android, iOS, Web browser, or Desktop build tools).

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/finance_tracker.git
   cd finance_tracker
   ```

2. **Get packages:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🤝 Contribution & License

This is a personal project. Feel free to fork it, open issues, or submit pull requests to suggest improvements!

Developed by **Fulton Ngo Corporation**.
