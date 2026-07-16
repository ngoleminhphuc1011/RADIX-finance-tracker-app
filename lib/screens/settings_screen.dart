import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_color_locker.dart';
import '../theme/theme_provider.dart';
import '../theme/currency_provider.dart';
import '../database/database_helper.dart';

enum ThemeOption { light, dark, system }

class _Currency {
  final String symbol;
  final String code;
  final String name;

  const _Currency(this.symbol, this.code, this.name);
}

const List<_Currency> _allCurrencies = [
  _Currency('\$', 'USD', 'US Dollar'),
  _Currency('€', 'EUR', 'Euro'),
  _Currency('¥', 'CNY', 'Chinese Yuan'),
  _Currency('₫', 'VND', 'Vietnam Dong'),
  _Currency('£', 'GBP', 'British Pound'),
  _Currency('¥', 'JPY', 'Japanese Yen'),
  _Currency('\$', 'AUD', 'Australian Dollar'),
  _Currency('\$', 'CAD', 'Canadian Dollar'),
];

class SettingsScreen extends StatefulWidget {
  final VoidCallback onResetAll;

  const SettingsScreen({super.key, required this.onResetAll});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  ThemeOption _selectedTheme = ThemeOption.light;
  String _searchQuery = '';
  late AnimationController _resetController;
  late Animation<double> _resetScale;
  late AnimationController _holdController;
  late Animation<double> _holdProgress;
  bool _isHolding = false;
  Color get _accentRed => AppColorLocker.of(context).accentRed;

  String get _selectedCurrencyCode {
    try {
      return CurrencyProvider.read(context).code;
    } catch (_) {
      return 'USD';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = ThemeProvider.of(context).value;
    ThemeOption targetOption;
    if (mode == ThemeMode.light) {
      targetOption = ThemeOption.light;
    } else if (mode == ThemeMode.dark) {
      targetOption = ThemeOption.dark;
    } else {
      targetOption = ThemeOption.system;
    }
    if (_selectedTheme != targetOption) {
      _selectedTheme = targetOption;
    }
  }

  Future<void> _selectCurrency(String code) async {
    try {
      final oldCode = _selectedCurrencyCode;
      if (oldCode.toUpperCase() == code.toUpperCase()) return;

      // 1. Convert all transaction amounts and budget in database
      await DatabaseHelper().convertAllTransactionsAndBudget(oldCode, code);

      // 2. Save new currency setting to settings table
      await DatabaseHelper().setSetting('active_currency', code);

      // 3. Update active currency in context
      if (mounted) {
        CurrencyProvider.of(context).value = CurrencyInfo.find(code);
      }
    } catch (e) {
      debugPrint('[Settings] Error saving currency: $e');
    }
  }

  List<_Currency> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return _allCurrencies;
    final query = _searchQuery.toLowerCase();
    return _allCurrencies.where((c) {
      return c.code.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query) ||
          c.symbol.contains(_searchQuery);
    }).toList();
  }

  int get _selectedIndex {
    switch (_selectedTheme) {
      case ThemeOption.light:
        return 0;
      case ThemeOption.system:
        return 1;
      case ThemeOption.dark:
        return 2;
    }
  }

  Color get _capsuleColor {
    final brightness = MediaQuery.of(context).platformBrightness;
    final locker = AppColorLocker.of(context);
    switch (_selectedTheme) {
      case ThemeOption.light:
        return locker.settingsActiveCapsuleLight;
      case ThemeOption.system:
        return brightness == Brightness.light
            ? locker.settingsActiveCapsuleSystemLight
            : locker.settingsActiveCapsuleSystemDark;
      case ThemeOption.dark:
        return locker.settingsActiveCapsuleDark;
    }
  }

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _resetScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.elasticOut),
    );

    _holdController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _holdProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _holdController, curve: Curves.linear));
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        debugPrint('Hold Confirm Success');
        Navigator.pop(context);
        widget.onResetAll();
      }
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: locker.settingsBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 40,
            left: 24,
            right: 24,
            bottom: 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Settings heading ---
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontFamily: 'MonumentExtended-Regular',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColorLocker.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: 40),
              // --- Appearance label (aligned with bar) ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: locker.settingsSectionLabel,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Capsule toggle bar ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: locker.settingsCapsuleBarBackground,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double tabWidth = constraints.maxWidth / 3;

                        return Stack(
                          children: [
                            // --- Sliding indicator (medicine capsule) ---
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                              left: _selectedIndex * tabWidth,
                              top: 0,
                              bottom: 0,
                              width: tabWidth,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                                decoration: BoxDecoration(
                                  color: _capsuleColor,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),

                            // --- Tab labels ---
                            Row(
                              children: [
                                _buildTab(
                                  index: 0,
                                  label: 'LIGHT',
                                  icon: Icons.sunny,
                                ),
                                _buildTab(
                                  index: 1,
                                  label: 'SYSTEM',
                                  icon: Icons.phone_android,
                                ),
                                _buildTab(
                                  index: 2,
                                  label: 'DARK',
                                  icon: Icons.dark_mode,
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // --- Currency label (aligned with bar) ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Currency',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColorLocker.of(context).settingsSectionLabel,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // --- Info text ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'You are using $_selectedCurrencyCode (${_allCurrencies.firstWhere((c) => c.code == _selectedCurrencyCode, orElse: () => _allCurrencies.first).symbol})',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 12,
                        color: locker.settingsInfoText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Search bar ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: locker.searchBarBackground,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 13,
                        color: locker.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search currency...',
                        hintStyle: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 13,
                          color: locker.textTertiary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: locker.textTertiary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Currency list (compact scroll window) ---
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: _filteredCurrencies.map((currency) {
                        return _buildCurrencyRow(currency);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildResetButton(),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 48, bottom: 40),
        child: SizedBox(
          height: 48,
          child: Listener(
            onPointerDown: (_) => _resetController.forward(),
            onPointerUp: (_) {
              _resetController.reverse();
              _showResetConfirmDialog(context);
            },
            onPointerCancel: (_) => _resetController.reverse(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => debugPrint('Reset button tapped'),
              child: ScaleTransition(
                scale: _resetScale,
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _accentRed,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColorLocker.of(context).textOnDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    final locker = AppColorLocker.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Reset Confirm',
      transitionDuration: const Duration(milliseconds: 350),
      barrierColor: locker.barrierColorLight,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: Stack(
            children: [
              Container(
                color: locker.textPrimary.withValues(alpha: 0.15),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: const SizedBox.expand(),
                ),
              ),
              Center(
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        bool isCancelPressed = false;
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: locker.dialogBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _accentRed.withValues(alpha: 0.75),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: locker.dialogShadow30,
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: locker.dialogShadow60,
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONFIRM DIALOGUE',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: locker.textDialogTitle,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone. Are you sure you want to clear all spending history?',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 13,
                        fontWeight: FontWeight.w100,
                        color: locker.textPrimary.withValues(alpha: 0.87),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatefulBuilder(
                            builder: (context, setState) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (_) => setState(() => isCancelPressed = true),
                                onTapUp: (_) {
                                  setState(() => isCancelPressed = false);
                                  Future.delayed(const Duration(milliseconds: 120), () {
                                    if (context.mounted) Navigator.pop(context);
                                  });
                                },
                                onTapCancel: () => setState(() => isCancelPressed = false),
                                child: AnimatedScale(
                                  scale: isCancelPressed ? 0.85 : 1.0,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.elasticOut,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: locker.textTertiary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'MonumentExtended-Regular',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: locker.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          _buildHoldConfirmButton(locker),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoldConfirmButton(AppColorLocker locker) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _isHolding = true);
        _holdController.forward();
      },
      onPointerUp: (_) {
        setState(() => _isHolding = false);
        _holdController.reset();
      },
      onPointerCancel: (_) {
        setState(() => _isHolding = false);
        _holdController.reset();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _holdProgress,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHolding ? 0.95 : 1.0,
              child: Container(
                width: 120,
                height: 48,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accentRed.withValues(alpha: 0.25)),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: _holdProgress.value,
                      alignment: Alignment.centerLeft,
                      child: Container(color: _accentRed),
                    ),
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [locker.textOnDark, _accentRed],
                          stops: [_holdProgress.value, _holdProgress.value],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'Confirm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: locker.textOnLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyRow(_Currency currency) {
    return _CurrencyTile(
      currency: currency,
      isSelected: currency.code == _selectedCurrencyCode,
      onTap: () => _selectCurrency(currency.code),
    );
  }

  Color get _activeTextColor {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    if (isDarkTheme) {
      return AppColorLocker.of(context).textPrimary;
    } else {
      switch (_selectedTheme) {
        case ThemeOption.light:
          return AppColorLocker.of(context).textPrimary;
        case ThemeOption.system:
          return AppColorLocker.of(context).textPrimary;
        case ThemeOption.dark:
          return AppColorLocker.of(context).textOnDark;
      }
    }
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final bool isActive = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            switch (index) {
              case 0:
                _selectedTheme = ThemeOption.light;
                ThemeProvider.of(context).value = ThemeMode.light;
                DatabaseHelper().setSetting('theme_mode', 'light');
                break;
              case 1:
                _selectedTheme = ThemeOption.system;
                ThemeProvider.of(context).value = ThemeMode.system;
                DatabaseHelper().setSetting('theme_mode', 'system');
                break;
              case 2:
                _selectedTheme = ThemeOption.dark;
                ThemeProvider.of(context).value = ThemeMode.dark;
                DatabaseHelper().setSetting('theme_mode', 'dark');
                break;
            }
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                fontFamily: 'MonumentExtended-Regular',
                fontSize: 12,
                letterSpacing: 3.0,
                fontWeight: FontWeight.bold,
                color: isActive ? _activeTextColor : AppColorLocker.of(context).textTertiary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive ? _activeTextColor : AppColorLocker.of(context).textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatefulWidget {
  final _Currency currency;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CurrencyTile> createState() => _CurrencyTileState();
}

class _CurrencyTileState extends State<_CurrencyTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);

    final Gradient gradient = widget.isSelected
        ? LinearGradient(
            colors: [
              locker.settingsCurrencySelectedStart,
              locker.settingsCurrencySelectedEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              locker.settingsCurrencyUnselectedBg,
              locker.settingsCurrencyUnselectedBg,
            ],
          );

    final Border border = widget.isSelected
        ? Border.all(
            color: locker.settingsCurrencySelectedBorder,
            width: 1.5,
          )
        : Border.all(
            color: locker.settingsCurrencyUnselectedBorder,
            width: 1.0,
          );

    final Color textColor = widget.isSelected
        ? locker.settingsCurrencySelectedText
        : locker.settingsCurrencyUnselectedText;

    final Color symbolColor = widget.isSelected
        ? locker.settingsCurrencySelectedText
        : locker.settingsCurrencyUnselectedSymbol;

    final List<BoxShadow> boxShadow = widget.isSelected
        ? [
            BoxShadow(
              color: locker.settingsCurrencySelectedBorder.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
        : [];

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(14),
            boxShadow: boxShadow,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: null,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: symbolColor,
                  ),
                  child: Text(widget.currency.symbol),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 13,
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                  child: Text('${widget.currency.code} - ${widget.currency.name}'),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: locker.settingsCurrencySelectedText,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
