import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'services/adb_service.dart';
import 'services/apk_manager.dart';
import 'theme/app_theme.dart';
import 'widgets/accounts_dialog.dart';
import 'widgets/action_cards.dart';
import 'widgets/apk_selector_card.dart';
import 'widgets/console_sheet.dart';
import 'widgets/device_card.dart';
import 'widgets/guide_dialog.dart';
import 'widgets/header_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1180, 800),
      minimumSize: Size(980, 640),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'مفاد وان پلاس | Mafad One Plus Desktop Pro',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MafadDesktopApp());
}

class MafadDesktopApp extends StatelessWidget {
  const MafadDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مفاد وان پلاس',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fa', 'IR'),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AdbService _adbService;
  late final ApkManager _apkManager;
  bool _isConsoleOpen = false;

  @override
  void initState() {
    super.initState();
    _adbService = AdbService();
    _apkManager = ApkManager();
  }

  @override
  void dispose() {
    _adbService.dispose();
    _apkManager.dispose();
    super.dispose();
  }

  void _showAccountsDialog() {
    final dev = _adbService.selectedDevice;
    if (dev == null) return;
    showDialog(
      context: context,
      builder: (_) => AccountsDialog(
        device: dev,
        adbService: _adbService,
      ),
    );
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (_) => const GuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_adbService, _apkManager]),
      builder: (context, _) {
        final selectedDev = _adbService.selectedDevice;

        return Scaffold(
          body: Column(
            children: [
              // 1. Top Header Bar
              HeaderBar(
                adbService: _adbService,
                isConsoleOpen: _isConsoleOpen,
                onToggleConsole: () {
                  setState(() => _isConsoleOpen = !_isConsoleOpen);
                },
                onOpenGuide: _showGuideDialog,
              ),

              // 2. Busy Progress Indicator Bar
              if (_adbService.isBusy)
                Container(
                  color: AppTheme.primary.withOpacity(0.12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _adbService.busyMessage.isNotEmpty
                              ? _adbService.busyMessage
                              : 'در حال اجرای عملیات سیستمی...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Main Body Scrollable Workspace
              Expanded(
                child: Row(
                  children: [
                    // Main Content
                    Expanded(
                      flex: _isConsoleOpen ? 6 : 10,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Device Status Card
                            DeviceCard(
                              device: selectedDev,
                              adbService: _adbService,
                              onShowAccounts: _showAccountsDialog,
                            ),

                            const SizedBox(height: 20),

                            // Action Cards (One-Click, Set Owner, Remove Admin)
                            ActionCards(
                              adbService: _adbService,
                              apkManager: _apkManager,
                              onShowAccounts: _showAccountsDialog,
                            ),

                            const SizedBox(height: 20),

                            // APK Manager Card
                            ApkSelectorCard(
                              apkManager: _apkManager,
                              adbService: _adbService,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Side / Bottom Console Panel
                    if (_isConsoleOpen)
                      Expanded(
                        flex: 4,
                        child: ConsoleSheet(
                          adbService: _adbService,
                          onClose: () {
                            setState(() => _isConsoleOpen = false);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
