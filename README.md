# RADIX — Premium Personal Finance Tracker

<p align="center">
  <img src="assets/images/logo/LOGORADIXNEW.png" alt="RADIX Logo" width="220" style="border-radius: 20%;" />
</p>

<p align="center">
  <strong>A premium, minimalist, and highly responsive personal finance application built with Flutter.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/SQLite-Sqflite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Release-v1.0.0.2%20Remastered-blueviolet?style=for-the-badge" alt="Release" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge" alt="Platforms" />
</p>

---

## Table of Contents

- [01. Introduction](#01-introduction)
- [02. What's New in v1.0.0.2 (Remastered Edition)](#02-whats-new-in-v1002-remastered-edition)
- [03. The Motivation (Why I Built This)](#03-the-motivation-why-i-built-this)
- [04. Features & Engineering Highlights](#04-features--engineering-highlights)
- [05. Tech Stack & Key Libraries](#05-tech-stack--key-libraries)
- [06. Development Tools & AI Assistants](#06-development-tools--ai-assistants)
- [07. Project Architecture](#07-project-architecture)
- [08. Getting Started](#08-getting-started)
- [09. Retrospective & Key Learning Points](#09-retrospective--key-learning-points)
- [10. Special Thanks](#10-special-thanks)
- [11. Contribution & Feedback](#11-contribution--feedback)
- [12. License & Trademark](#12-license--trademark)
- [13. Demo Images](#13-demo-images)

---

## 01. Introduction

**RADIX** is an independent, offline personal finance tracker developed as an educational and experimental project. Built with Flutter, it features a **Crisp Apple Minimalist White** light mode and a **Luxury Dark Mode**, utilizing custom typography (`Monument Extended`, `Font Ultra`) and offline database capabilities.

This is my very first programming project. It was developed over a 5-week period between **June 8 and July 15** by a 16-year-old creator. While I co-piloted the development with AI (often called "vibe-coding"), I took complete ownership of the system design and architecture. I designed all layouts, conceptualized and implemented the animations, mapped the local SQLite database structures to the reactive UI layers (via ValueNotifiers/Providers), and implemented the mathematics for real-time currency conversions.

---

## 02. What's New in v1.0.0.2 (Remastered Edition)

The **Remastered Edition** represents a complete architectural and visual overhaul of RADIX, evolving it from a fast prototype into a modular, production-ready application:

- **Clean Architecture & Code Modularization:** Deconstructed monolithic screens (especially `HomeScreen`) into domain-driven packages (`core/`, `models/`, `screens/<feature>/widgets/`), extracting dialogs, state notifiers, and animations into isolated, testable components.
- **Adaptive Typography & Font Overhaul:** Switched app body, inputs, and descriptions to **Google Fonts Open Sans** with an enforced bold weight discipline (w700–w900) and a universal size boost (+2.0) for seamless cross-language character support and superior readability. Standardized numerical readouts and currency symbols with the dedicated `RadixCurrencyText` engine to prevent layout overflow.
- **Dual-Column Landscape Mode:** Full responsive screen rotation support. Rotating into landscape mode activates an expanded 2-column split-view financial workspace with zero layout jitter.
- **Remastered Date Headers & Daily Totals:** Transactions are intelligently grouped by calendar day, featuring real-time daily expense and income aggregate totals directly beside each date badge.
- **Modern Glassmorphic Navigation Bar & Center FAB:** Floating, pill-shaped navigation shell with real-time frosted glass backdrop blur (`BackdropFilter`) and an elevated action button (`+`).
- **New Edit Dialogue & Fluid Micro-Interactions:** Inline controls on transaction tiles with an animated modal dialogue for quick edits, category re-selection, and safe SQLite atomic updates.
- **Precision Currency Picker:** Reimagined currency bottom sheet supporting 8 global currencies (USD, EUR, CNY, VND, GBP, JPY, AUD, CAD) with atomic conversion math.
- **Automated Budget Reset Intervals:** Added customizable budget reset cycles (1M, 2M, 3M, 4M, 5M, 6M) managed by `ResetIntervalService`.
- **In-App Legal Suite & Feature Previews:** Integrated native Privacy Policy, Terms of Service, and About screens (zero telemetry guarantee), plus preview hubs for Social and Profile tabs.
- **Haptic Feedback & Performance Polish:** Tactile vibrations (`HapticHelper`) across interactions and `RepaintBoundary` isolation for silky 60–120 FPS scrolling.

<!-- Screenshot Placeholder: v1.0.0.2 Remastered Highlights -->

---

## 03. The Motivation (Why I Built This)

The development of RADIX was inspired by three main factors:

- **Interest in Finance & AI:** I have a deep curiosity for financial systems, artificial intelligence, and building products. This project serves as a learning step to understand how they intersect in real-world applications.

- **Addressing the Youth "Money Leak" Problem:** I observed a prevalent social pattern among my peers and youth: the phenomenon of **"micro-spending creep"** or the **"money leak."** Young people frequently spend small, seemingly insignificant amounts on daily comforts—such as bubble tea, subscription services, gaming micro-transactions, or impulse snacks. Individually, these purchases feel negligible, but cumulatively, they create a silent leakage that drains their monthly allowance, preventing them from saving or understanding their actual cash flow. Most traditional budgeting apps are dry, clinical, and complex, which discourages teens from using them consistently. RADIX was built as a response to this: by combining a premium, responsive visual design with smooth micro-animations, I wanted to lower the friction of tracking and make financial awareness engaging. The dynamic budgeting indicators and instant visual analytics are engineered specifically to help young users identify where their money is leaking, helping them take control of their finances and build long-term financial literacy.

- **Childhood Dream & Business Mindset:** Since I was young, I dreamed of building and launching functional products. Developing RADIX at **16 years old** is my first step in learning product creation and business execution.

---

## 04. Features & Engineering Highlights

- **Reactive Daily Transaction Logger**
  - Instant logging of expenses and incomes.
  - Multi-attribute transactions including title, type, category, date, and currency mapping.
  - **Flexible Income Strategies:** Supports two distinct tracking logic strategies: `add_to_budget` (directly increases the monthly budget limit) and `deduct_from_spent` (cancels out or deducts from recorded spent amounts).
  - Quick-search filters and custom multi-sorting options (by Date, Amount, etc.) implemented on the database query layer.

- **Dynamic Currency Exchange & Conversion Math**
  - Supports switching active currencies (USD, EUR, CNY, VND, GBP, JPY, AUD, CAD) on-the-fly.
  - **Atomic Database Transactions:** Bulk conversion calculations for historical logs and monthly budgets run within a single, atomic SQLite transaction (`db.transaction`). This guarantees absolute database integrity and auto-rollback on failure.
  - Math formulation utilizes relative exchange rates to convert all database amounts dynamically and notify the UI layer reactively.

- **State-to-Database Bridging:** Synchronizes physical database records to the presentation layer reactively using a custom state structure powered by `ValueNotifier` and `InheritedWidget` wrappers (`ThemeProvider` and `CurrencyProvider`).
  - Real-time arithmetic tracking of:
    - `Remaining Budget = Monthly Budget - Total Expenses`
  - High-precision floating-point calculation to handle web and mobile platforms smoothly without rounding errors.

- **Performance-Optimized Charts & Analytics**
  - Visual financial analytics powered by `fl_chart` containing dynamic donut charts for category share distributions, premium category icons, featuring both total expense and specific expenses for categories.
  - **Memoization Cache:** Uses a custom transaction hashing algorithm to cache grouped transactions. It prevents redundant computation on every UI rebuild, achieving stable 60 FPS list scrolling.

- **Premium Visual Themes & Fine-tuned Animations**
  - **Crisp Apple Minimalist White** (Light) & **Luxury Dark** themes with centralized color schemes (`AppColorLocker`).
  - **Clockwise Sequential Loop Dot Loader:** A custom-designed, physics-tuned splash animation where money symbols move sequentially in a clockwise loop using sequential TweenSequences and curved animation controllers.
  - **Hold-to-Confirm Gesture (Settings Reset):** A continuous press gesture built with custom AnimationControllers that maps user duration to a circular scaling indicator, preventing accidental deletions.
  - **Fluid Page Route Transitions:** Custom slide and scale transitions for navigation, ensuring a polished, platform-native feel.

---

## 05. Tech Stack & Key Libraries

- **Framework:** [Flutter](https://flutter.dev/) (Dart 3.x)
- **Database:** [sqflite](https://pub.dev/packages/sqflite) (Native SQLite) & [sqflite_common_ffi_web](https://pub.dev/packages/sqflite_common_ffi_web) (IndexedDB + WebAssembly SQLite for Web compatibility).
- **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart) for smooth and interactive charting.
- **Localization & Formatting:** [intl](https://pub.dev/packages/intl).
- **Export & Sharing:** [share_plus](https://pub.dev/packages/share_plus), [file_picker](https://pub.dev/packages/file_picker), [path_provider](https://pub.dev/packages/path_provider).
- **Fonts:** Custom typography combining Google Fonts ([Open Sans](https://fonts.google.com/specimen/Open+Sans) bold weights) for crisp body copy and global character support, paired with Canva/custom geometric fonts (`MonumentExtended`, `FontUltra`) for display headers and branding.

---

## 06. Development Tools & AI Assistants

The development of RADIX was supported by a suite of modern coding tools and AI pair programmers:
- **VS Code:** The primary Integrated Development Environment (IDE) used for building, testing, and formatting the application.
- **Cline:** The AI assistant framework that facilitated code modifications, search, and development coordination.
- **Gemini:** The LLM intelligence powering complex problem-solving, code suggestions, prompt writing, and analytical reasoning.
- **Antigravity:** The specialized agent system that performed pairs-programming, lint fixes, architectural refactoring, and static analysis verification.

---

## 07. Project Architecture

```
lib/
├── core/
│   ├── database/
│   │   └── database_helper.dart          # Singleton SQLite database & Web IndexedDB bridge
│   ├── services/
│   │   ├── data_export_service.dart      # CSV spreadsheets & JSON backup/restore engine
│   │   ├── haptic_helper.dart            # Tactile feedback vibrations with user preference persistence
│   │   └── reset_interval_service.dart   # Budget reset cycle scheduling & cycle calculations
│   ├── theme/
│   │   ├── app_color_locker.dart         # Dual-theme color registries (Crisp Light & Luxury Dark)
│   │   ├── app_theme.dart                # Theme definitions and Material styling
│   │   ├── app_typography.dart           # Custom typography system and responsive font scales
│   │   ├── currency_provider.dart        # Reactive active currency notifier & conversion rates
│   │   └── theme_provider.dart           # Reactive ThemeMode state notifier
│   └── widgets/
│       └── radix_currency_text.dart      # Auto-scaling currency text widget preventing overflow
├── models/
│   └── transaction_model.dart            # Transaction schema, serialization, and sorting algorithms
├── screens/
│   ├── graph/
│   │   ├── widgets/                      # Donut charts, category breakdown, drill-down lists
│   │   └── graph_screen.dart             # Interactive financial analytics & drill-down view
│   ├── home/
│   │   ├── widgets/                      # Transaction tiles, add dialog, budget dialog, bounce card
│   │   ├── home_screen.dart              # Main dashboard with adaptive portrait/landscape layout
│   │   └── instruction_screen.dart       # Comprehensive user guide & feature documentation
│   ├── profile/
│   │   └── profile_screen.dart           # Profile & personal statistics preview
│   ├── settings/
│   │   ├── legal/                        # Privacy policy, Terms of service, About app
│   │   ├── widgets/                      # Theme bar, currency picker, reset interval selector
│   │   └── settings_screen.dart          # Unified settings hub & danger zone controls
│   ├── social/
│   │   └── social_screen.dart            # Community & social budgeting preview
│   └── splash/
│       ├── widgets/                      # Clockwise sequential money loop animation
│       └── splash_screen.dart            # Physics-tuned animated loading screen
├── main.dart                             # App initialization, service bootstrap & state providers
└── nav_wrapper.dart                      # Frosted glass floating navigation bar & orientation handler
```

---

## 08. Getting Started

### Try It Instantly

- **Direct Download (Android):** Download the pre-built [RADIX Android APK](https://github.com/ngoleminhphuc1011/RADIX-finance-tracker-app/releases) directly from the Releases page and install it on your device.
- **Web Demo (Not recommended for regular use):** Open the [Interactive Web Version](https://ngoleminhphuc1011.github.io/RADIX-finance-tracker-app/) in your browser for a quick preview. *(Note: The Web build is provided solely for demonstration purposes; for optimal performance, full offline capabilities, and design accuracy, please use the native Android or iOS builds).*

---

### Running Locally

Follow these steps to compile and run the project on your machine.

#### Prerequisites

- Ensure you have [Flutter SDK installed](https://docs.flutter.dev/get-started/install).
- A device, emulator, or browser configured for Flutter.

#### Installation & Launch

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ngoleminhphuc1011/RADIX-finance-tracker-app.git
   cd RADIX-finance-tracker-app
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

## 09. Retrospective & Key Learning Points

As my first programming project, building RADIX was a wonderful learning experience. Developing this app alongside AI allowed me to learn rapidly, though it also highlighted areas for my growth as a creator:

1. **Learning to Code alongside AI ("Vibe-Coding"):**
   In the early days, my process was mostly "vibe-coding" — prompting and coding in tandem with AI tools without a concrete system plan. While this allowed me to prototype at an incredibly fast pace, it sometimes resulted in temporary bugs and code styling warnings. Learning to debug and standardize this code taught me the value of static analysis, compiler guidelines, and strict formatting rules.

2. **Evolving Code Organization into Clean Architecture:**
   To build quickly, I initially placed a lot of logic directly within single user interface files (causing screens like `home_screen.dart` to grow large). In the Remastered v1.0.0.2 release, refactoring this into modular sub-components, services, and domain-focused packages taught me how professional software maintains scalability and high testability.

3. **Balancing Design & Core Logic:**
   I initially invested a lot of energy into polishing the micro-animations and custom transitions early on because I wanted the product to feel premium. However, this taught me the lesson of sequencing: I learned that establishing a solid database structure and core system logic must always be finalized before perfecting the design details.

---

## 10. Special Thanks

I would like to express my deepest gratitude to:
- **My Father & Family:** For constantly encouraging me to learn programming and being the motivation for me to build something meaningful that can bring positive value to our family, also I really want to give my family a better life. Thank you so much to Dad, Mom and my little sister. You are the reason why I keep going.
- **Alex Le:** A close friend who changed my mindset from planning to **real execution**, he also bring me to this finance and building mindset. Thanks bro!

---

## 11. Contribution & Feedback

This is my first personal project and was coded with AI assistance, so quite a few bugs are expected. I am very open to hearing both positive and negative suggestions, feedback, or feature requests! Please feel free to open an issue, submit a pull request, or share your thoughts.

Developed by **Fulton Ngo Corporation**.

---

### Credits

- **Idea by:** Phuc Ngo
- **Writing & Improvement by:** Gemini 3.5 Flash, Gemini 3.8 Flash, and Phuc Ngo

---

## 12. License & Trademark

### Source Code
The core source code of this project is licensed under the [MIT License](LICENSE).

### Brand & Trademark Notice
The names **"RADIX"**, logos, project branding, and custom UI design assets are the exclusive intellectual property of the author. 
- You may inspect, fork, and learn from the architecture and logic.
- You **may NOT** redistribute, fork, or publish this application using the name **"RADIX"**, the official logo, or misleading branding that implies endorsement.

---

## 13. Demo Images

<img width="858" height="1908" alt="z8059831511430_b7b52bb460307cc09557cfa4684eee99" src="https://github.com/user-attachments/assets/5916b6d4-f48d-4086-9cf8-d737681e4c28" />
<img width="858" height="1908" alt="z8059831487564_85ed76fd2b9262dc9314e3c93782ddfb" src="https://github.com/user-attachments/assets/dc8e6b1a-5f55-462d-931b-c40c890e2b74" />
<img width="858" height="1908" alt="z8059831487565_585d44928fdc0d971a8f3c36d75383e9" src="https://github.com/user-attachments/assets/4ad490a1-69ec-42e2-afe3-d1134106e0d4" />
<img width="858" height="1908" alt="z8059831487562_b962b754696951172e42dd77a3eb7628" src="https://github.com/user-attachments/assets/ceb6fe58-cdc4-4f58-95da-99cf1fa811a5" />
<img width="858" height="1908" alt="z8059831725787_d25b3e96d7b5855196df027db803ca10" src="https://github.com/user-attachments/assets/643b24a6-eed6-49a4-835a-e4232962842c" />
<img width="858" height="1908" alt="z8059831735573_ef872c8526f8bdf0c4820256f6a341dd" src="https://github.com/user-attachments/assets/1dc49878-3402-4485-bfdb-453aee0153e3" />
<img width="858" height="1908" alt="z8059831776816_81d5d452247a90c2203f4dde8ae843a8" src="https://github.com/user-attachments/assets/0678d18f-fa4b-44b7-b6d3-6a368638558f" />
<img width="858" height="1908" alt="z8059831490887_a406159410025fc105d26ad67bbf3e3e" src="https://github.com/user-attachments/assets/3b5cdbcc-b67a-424a-9a85-f58e3de6a490" />
<img width="858" height="1908" alt="z8059831857273_b9a2ccb3af15005a2a09e422a0c832e3" src="https://github.com/user-attachments/assets/75226bf7-cd30-4bec-9485-bca3e3b74b90" />
<img width="858" height="1908" alt="z8059831490886_501648fb20b8e4ed5bf178d05edd930a" src="https://github.com/user-attachments/assets/2a400df1-e4d2-4d46-b868-4c1e27277650" />
<img width="858" height="1908" alt="z8059831795905_c1664d4dd62e59bd14f6357bbac8227f" src="https://github.com/user-attachments/assets/31312b41-b284-4c03-85cf-f9ff08399d33" />
