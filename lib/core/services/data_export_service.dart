import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../database/database_helper.dart';
import '../theme/app_color_locker.dart';
import '../theme/app_typography.dart';
import '../theme/currency_provider.dart';
import '../theme/theme_provider.dart';
import 'reset_interval_service.dart';

class DataExportService {
  /// Escapes CSV values conforming to RFC 4180
  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Saves content directly to the device's public Download folder (or document storage)
  /// and returns the saved File object.
  static Future<File> saveFileLocally({
    required String filename,
    required String content,
  }) async {
    Directory? targetDir;

    if (!kIsWeb && Platform.isAndroid) {
      // 1. Primary: Android public Download directory
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (await publicDownload.exists()) {
        try {
          final testFile = File('${publicDownload.path}/.radix_perm_test');
          await testFile.writeAsString('test');
          await testFile.delete();
          targetDir = publicDownload;
        } catch (_) {
          targetDir = null;
        }
      }

      // 2. Secondary: App-specific external Downloads directory
      if (targetDir == null) {
        try {
          final externalDirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          );
          if (externalDirs != null && externalDirs.isNotEmpty) {
            final dir = externalDirs.first;
            if (await dir.exists()) {
              targetDir = dir;
            }
          }
        } catch (_) {}
      }

      // 3. Fallback to external files directory
      targetDir ??= await getExternalStorageDirectory();
    } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      targetDir = await getApplicationDocumentsDirectory();
    } else if (!kIsWeb) {
      // Windows, Linux
      targetDir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }

    targetDir ??= await getTemporaryDirectory();
    final file = File('${targetDir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file;
  }

  /// Exports all active SQLite transactions to a strict CSV file.
  /// If [share] is true, opens the system share sheet.
  /// If [share] is false (default), saves directly to the device storage via system file dialog and Downloads.
  static Future<void> exportTransactionsCsv(
    BuildContext context, {
    bool share = false,
  }) async {
    try {
      final db = DatabaseHelper();
      final transactions = await db.getTransactions();

      if (transactions.isEmpty) {
        if (context.mounted) {
          showToast(context, 'No transactions found to export.');
        }
        return;
      }

      String currencyCode = 'USD';
      if (context.mounted) {
        try {
          currencyCode = CurrencyProvider.read(context).code;
        } catch (_) {}
      }

      final buffer = StringBuffer();
      // Required Columns: id,date,type,category,description,amount,currency
      buffer.writeln('id,date,type,category,description,amount,currency');

      for (final tx in transactions) {
        buffer.writeln(
          '${tx.id ?? ""},'
          '${_escapeCsv(tx.date)},'
          '${_escapeCsv(tx.type)},'
          '${_escapeCsv(tx.category)},'
          '${_escapeCsv(tx.title)},'
          '${tx.amount.toStringAsFixed(2)},'
          '${_escapeCsv(currencyCode)}',
        );
      }

      final csvContent = buffer.toString();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = 'RADIX_export_$timestamp.csv';
      final bytes = Uint8List.fromList(utf8.encode(csvContent));

      if (kIsWeb) {
        await FilePicker.saveFile(
          fileName: filename,
          bytes: bytes,
          mimeType: 'text/csv',
        );
        if (context.mounted) {
          showToast(
            context,
            'Exported ${transactions.length} transactions to $filename',
          );
        }
        return;
      }

      if (share) {
        final savedFile = await saveFileLocally(
          filename: filename,
          content: csvContent,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(savedFile.path, mimeType: 'text/csv')],
            subject: 'RADIX Transactions Export',
          ),
        );
        if (context.mounted) {
          showToast(context, 'Sharing $filename...');
        }
        return;
      }

      // Default: Save directly to device storage via native file save dialog
      bool saved = false;
      try {
        final uri = await FilePicker.saveFile(
          dialogTitle: 'Save Transactions CSV',
          fileName: filename,
          bytes: bytes,
          mimeType: 'text/csv',
          allowedExtensions: ['csv'],
        );
        if (uri != null) {
          saved = true;
        } else {
          // User canceled the save dialog
          if (context.mounted) {
            showToast(context, 'Export cancelled');
          }
          return;
        }
      } catch (e) {
        debugPrint('[DataExportService] FilePicker.saveFile fallback: $e');
      }

      // Also ensure a local copy is written to Downloads folder if possible
      try {
        await saveFileLocally(filename: filename, content: csvContent);
        saved = true;
      } catch (_) {}

      if (context.mounted && saved) {
        showToast(context, 'Saved: $filename');
      }
    } catch (e) {
      debugPrint('[DataExportService] Error exporting CSV: $e');
      if (context.mounted) {
        showToast(context, 'Export failed: $e', isError: true);
      }
    }
  }

  /// Exports full database (transactions, settings, interval) to portable JSON.
  /// If [share] is true, opens the system share sheet.
  /// If [share] is false (default), saves directly to the device storage via system file dialog and Downloads.
  static Future<void> createBackupJson(
    BuildContext context, {
    bool share = false,
  }) async {
    try {
      final db = DatabaseHelper();
      final transactions = await db.getTransactions();
      final settings = await db.getAllSettings();
      final intervalMonths =
          await ResetIntervalService.getResetIntervalMonths();
      final lastReset = await ResetIntervalService.getLastResetTimestamp();

      String currencyCode = 'USD';
      if (context.mounted) {
        try {
          currencyCode = CurrencyProvider.read(context).code;
        } catch (_) {}
      }

      final double budget =
          double.tryParse(settings['monthly_budget'] ?? '0') ?? 0.0;

      final backupData = {
        'app': 'RADIX',
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'meta': {
          'activeCurrency': currencyCode,
          'monthlyBudget': budget,
          'resetIntervalMonths': intervalMonths,
          'lastResetTimestamp': lastReset.toIso8601String(),
        },
        'settings': settings,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

      final jsonContent = const JsonEncoder.withIndent(
        '  ',
      ).convert(backupData);
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final filename = 'RADIX_backup_$timestamp.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonContent));

      if (kIsWeb) {
        await FilePicker.saveFile(
          fileName: filename,
          bytes: bytes,
          mimeType: 'application/json',
        );
        if (context.mounted) {
          showToast(context, 'Backup created: $filename');
        }
        return;
      }

      if (share) {
        final savedFile = await saveFileLocally(
          filename: filename,
          content: jsonContent,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(savedFile.path, mimeType: 'application/json')],
            subject: 'RADIX Database Backup',
          ),
        );
        if (context.mounted) {
          showToast(context, 'Sharing backup file...');
        }
        return;
      }

      // Default: Native file save dialog (ACTION_CREATE_DOCUMENT on Android)
      bool saved = false;
      try {
        final uri = await FilePicker.saveFile(
          dialogTitle: 'Save RADIX Backup',
          fileName: filename,
          bytes: bytes,
          mimeType: 'application/json',
          allowedExtensions: ['json'],
        );
        if (uri != null) {
          saved = true;
        } else {
          // User canceled
          if (context.mounted) {
            showToast(context, 'Backup cancelled');
          }
          return;
        }
      } catch (e) {
        debugPrint('[DataExportService] FilePicker.saveFile fallback: $e');
      }

      // Also ensure local backup copy exists in Downloads
      try {
        await saveFileLocally(filename: filename, content: jsonContent);
        saved = true;
      } catch (_) {}

      if (context.mounted && saved) {
        showToast(context, 'Backup saved: $filename');
      }
    } catch (e) {
      debugPrint('[DataExportService] Error creating backup: $e');
      if (context.mounted) {
        showToast(context, 'Backup failed: $e', isError: true);
      }
    }
  }

  /// Restores database from a user-selected JSON file within an atomic transaction.
  static Future<void> restoreBackupJson(
    BuildContext context, {
    required VoidCallback onRestored,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: !kIsWeb && Platform.isAndroid
            ? '/storage/emulated/0/Download'
            : null,
      );

      if (files.isEmpty) {
        return; // User canceled
      }

      final pickedFile = files.first;
      final bytes = await pickedFile.readAsBytes();
      final jsonContent = utf8.decode(bytes);

      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic> ||
          decoded['app'] != 'RADIX' ||
          decoded['transactions'] is! List) {
        throw Exception('Invalid RADIX backup file schema.');
      }

      // 1. Atomic database restore
      final db = DatabaseHelper();
      await db.restoreFromBackupData(decoded);

      // 2. Restore meta configuration if present
      final meta = decoded['meta'] as Map<String, dynamic>?;
      if (meta != null) {
        if (meta['resetIntervalMonths'] is int) {
          await ResetIntervalService.setResetIntervalMonths(
            meta['resetIntervalMonths'] as int,
          );
        }
        if (meta['lastResetTimestamp'] is String) {
          final dt = DateTime.tryParse(meta['lastResetTimestamp'] as String);
          if (dt != null) {
            await ResetIntervalService.setLastResetTimestamp(dt);
          }
        }
        if (meta['activeCurrency'] is String && context.mounted) {
          final code = meta['activeCurrency'] as String;
          CurrencyProvider.of(context).value = CurrencyInfo.find(code);
        }
      }

      // 3. Trigger parent refresh callback
      onRestored();

      if (context.mounted) {
        final txCount = (decoded['transactions'] as List).length;
        showToast(
          context,
          'Successfully restored $txCount transactions & budget.',
        );
      }
    } catch (e) {
      debugPrint('[DataExportService] Error restoring backup: $e');
      if (context.mounted) {
        showToast(
          context,
          'Restore failed: Invalid or corrupted backup file.',
          isError: true,
        );
      }
    }
  }

  static OverlayEntry? _activeToast;

  /// Displays an elegant, non-intrusive floating toast notification.
  /// Uses an OverlayEntry at the top of the viewport to guarantee it never collides
  /// with bottom navigation bars, bottom sheets, or triggers 'Floating SnackBar presented off screen'.
  static void showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback for isolated widget tests without an Overlay hierarchy
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return;
    }

    _activeToast?.remove();
    _activeToast = null;

    final locker = AppColorLocker.of(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final themeMode = ThemeProvider.of(context).value;
      if (themeMode == ThemeMode.light) {
        isDark = false;
      } else if (themeMode == ThemeMode.dark) {
        isDark = true;
      } else if (themeMode == ThemeMode.system) {
        isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      }
    } catch (_) {}

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        isError: isError,
        locker: locker,
        isDark: isDark,
        onDismiss: () {
          if (_activeToast == entry) {
            entry.remove();
            _activeToast = null;
          }
        },
      ),
    );

    _activeToast = entry;
    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final AppColorLocker locker;
  final bool isDark;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.isError,
    required this.locker,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = widget.isDark;

    final backgroundColor = widget.locker.toastBackground;
    final textColor = widget.locker.toastText;
    final borderColor = widget.isError
        ? widget.locker.accentRed.withValues(alpha: isDark ? 0.6 : 0.45)
        : widget.locker.accentGreen.withValues(alpha: isDark ? 0.5 : 0.40);

    final shadowColor = widget.locker.toastShadow;

    final iconBgColor =
        (widget.isError ? widget.locker.accentRed : widget.locker.accentGreen)
            .withValues(alpha: isDark ? 0.18 : 0.12);

    return Positioned(
      top: topPadding > 0 ? topPadding + 14 : 32,
      left: 20,
      right: 20,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            type: MaterialType.transparency,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: isDark ? 24 : 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isError
                              ? Icons.error_outline_rounded
                              : Icons.check_rounded,
                          color: widget.isError
                              ? widget.locker.accentRed
                              : widget.locker.accentGreen,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: AppTypography.openSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
