import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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
  const SettingsScreen({super.key});

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
  static const Color _accentRed = Color(0xFFE57373);

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
    switch (_selectedTheme) {
      case ThemeOption.light:
        return Colors.white;
      case ThemeOption.system:
        return brightness == Brightness.light
            ? const Color(0xFFB0B0B5)
            : const Color(0xFF18181B);
      case ThemeOption.dark:
        return const Color(0xFF1C1C1E);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Settings heading ---
            const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'MonumentExtended-Regular',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 40),
            // --- Appearance label (aligned with bar) ---
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontFamily: 'MonumentExtended-Regular',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF636366),
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
                    color: const Color(0xFFE2E2E2),
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
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Currency',
                    style: TextStyle(
                      fontFamily: 'MonumentExtended-Regular',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF636366),
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
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'You are using USD (\$)',
                    style: TextStyle(
                      fontFamily: 'MonumentExtended-Regular',
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
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
                    color: const Color(0xFFE2E2E2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'MonumentExtended-Regular',
                      fontSize: 13,
                      color: Color(0xFF1C1C1E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search currency...',
                      hintStyle: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  child: const Center(
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Reset Confirm',
      transitionDuration: const Duration(milliseconds: 350),
      barrierColor: Colors.transparent,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: Stack(
            children: [
              Container(
                color: Colors.black.withValues(alpha: 0.3),
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
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _accentRed.withValues(alpha: 0.75),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                    const Text(
                      'CONFIRM DIALOGUE',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3A3A3C),
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This action cannot be undone. Are you sure you want to clear all spending history?',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 13,
                        fontWeight: FontWeight.w100,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'MonumentExtended-Regular',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildHoldConfirmButton(),
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

  Widget _buildHoldConfirmButton() {
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
                          colors: [Colors.white, _accentRed],
                          stops: [_holdProgress.value, _holdProgress.value],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Text(
                          'Confirm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              currency.symbol,
              style: const TextStyle(
                fontFamily: null,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF3A3A3C),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${currency.code} - ${currency.name}',
            style: const TextStyle(
              fontFamily: 'MonumentExtended-Regular',
              fontSize: 13,
              color: Color(0xFF636366),
            ),
          ),
        ],
      ),
    );
  }

  Color get _activeTextColor {
    switch (_selectedTheme) {
      case ThemeOption.light:
        return Colors.black;
      case ThemeOption.system:
        return Colors.white;
      case ThemeOption.dark:
        return Colors.white;
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
                break;
              case 1:
                _selectedTheme = ThemeOption.system;
                break;
              case 2:
                _selectedTheme = ThemeOption.dark;
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
                color: isActive ? _activeTextColor : Colors.grey.shade500,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive ? _activeTextColor : Colors.grey.shade500,
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
