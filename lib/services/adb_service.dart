import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/device_info.dart';
import '../models/log_entry.dart';

class AdbActionResult {
  final bool success;
  final String title;
  final String message;
  final String rawOutput;
  final String? troubleshootingTip;

  AdbActionResult({
    required this.success,
    required this.title,
    required this.message,
    required this.rawOutput,
    this.troubleshootingTip,
  });
}

class AdbService extends ChangeNotifier {
  static const String targetPackage = 'ir.akhtardanesh.mafadoneplus';
  static const String targetReceiver =
      'ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver';
  static const String targetClearReceiver =
      'ir.akhtardanesh.mafadoneplus/.ClearDeviceOwnerReceiver';
  static const String targetClearAction =
      'ir.akhtardanesh.mafadoneplus.ACTION_REMOVE_DEVICE_OWNER';

  String? _customAdbPath;
  String _effectiveAdbPath = 'adb';
  bool _isAdbAvailable = false;
  bool _isRefreshing = false;
  bool _isBusy = false;
  String _busyMessage = '';

  List<DeviceInfo> _devices = [];
  DeviceInfo? _selectedDevice;
  final List<LogEntry> _logs = [];
  Timer? _pollTimer;

  // Getters
  String get adbPath => _effectiveAdbPath;
  bool get isAdbAvailable => _isAdbAvailable;
  bool get isRefreshing => _isRefreshing;
  bool get isBusy => _isBusy;
  String get busyMessage => _busyMessage;
  List<DeviceInfo> get devices => List.unmodifiable(_devices);
  DeviceInfo? get selectedDevice => _selectedDevice;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  AdbService() {
    _initAdb();
  }

  Future<void> _initAdb() async {
    await findAdbBinary();
    await refreshDevices();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!_isBusy && !_isRefreshing) {
        await refreshDevices(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void setCustomAdbPath(String? path) {
    _customAdbPath = path;
    findAdbBinary().then((_) => refreshDevices());
  }

  void selectDevice(DeviceInfo? device) {
    _selectedDevice = device;
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void _addLog(String title, String message, LogType type, {String? command}) {
    _logs.insert(
      0,
      LogEntry(
        title: title,
        message: message,
        type: type,
        command: command,
      ),
    );
    if (_logs.length > 500) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  /// Auto-discover the best ADB binary on Linux / Windows / macOS
  Future<bool> findAdbBinary() async {
    final candidates = <String>[];

    if (_customAdbPath != null && _customAdbPath!.isNotEmpty) {
      candidates.add(_customAdbPath!);
    }

    if (Platform.isWindows) {
      // Local windows platform tools
      candidates.add(r'assets\platform-tools-windows\adb.exe');
      candidates.add(r'platform-tools\adb.exe');
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        candidates.add(
            '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe');
      }
      candidates.add('adb.exe');
    } else {
      // Linux / macOS
      final home = Platform.environment['HOME'] ?? '';
      candidates.add('/usr/bin/adb');
      candidates.add('$home/Android/Sdk/platform-tools/adb');
      candidates.add('/usr/local/bin/adb');
      candidates.add('adb');
    }

    for (final bin in candidates) {
      try {
        final result = await Process.run(bin, ['version']);
        if (result.exitCode == 0 &&
            result.stdout.toString().contains('Android Debug Bridge')) {
          _effectiveAdbPath = bin;
          _isAdbAvailable = true;
          _addLog(
            'شناسایی ابزار ADB',
            'ابزار ADB با موفقیت در مسیر زیر شناسایی شد:\n$bin',
            LogType.success,
          );
          notifyListeners();
          return true;
        }
      } catch (_) {
        // Continue checking candidates
      }
    }

    _isAdbAvailable = false;
    _addLog(
      'عدم شناسایی ADB',
      'ابزار adb در مسیر سیستم یافت نشد. لطفاً Android SDK یا adb را بررسی کنید.',
      LogType.error,
    );
    notifyListeners();
    return false;
  }

  /// Run an ADB command process
  Future<ProcessResult> runAdb(List<String> args, {String? deviceSerial}) async {
    final fullArgs = <String>[];
    if (deviceSerial != null && deviceSerial.isNotEmpty) {
      fullArgs.addAll(['-s', deviceSerial]);
    }
    fullArgs.addAll(args);

    final cmdString = '$_effectiveAdbPath ${fullArgs.join(' ')}';
    try {
      final res = await Process.run(_effectiveAdbPath, fullArgs);
      final out = (res.stdout.toString() + res.stderr.toString()).trim();
      _addLog(
        'دستور ADB',
        out.isEmpty ? '(خروجی خالی)' : out,
        res.exitCode == 0 ? LogType.command : LogType.warning,
        command: cmdString,
      );
      return res;
    } catch (e) {
      _addLog('خطا در اجرای فرآیند', e.toString(), LogType.error, command: cmdString);
      rethrow;
    }
  }

  /// Refreshes device list and updates current selected device details
  Future<void> refreshDevices({bool silent = false}) async {
    if (!_isAdbAvailable) return;
    if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final res = await Process.run(_effectiveAdbPath, ['devices', '-l']);
      if (res.exitCode != 0) {
        _isAdbAvailable = false;
        _devices = [];
        _selectedDevice = null;
        return;
      }

      final lines = res.stdout.toString().split('\n');
      final newDevices = <DeviceInfo>[];

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('List of devices')) continue;

        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final serial = parts[0];
          final state = parts[1]; // 'device', 'unauthorized', 'offline'

          var model = 'Unknown';
          var product = 'Android';
          for (final p in parts) {
            if (p.startsWith('model:')) {
              model = p.replaceFirst('model:', '');
            } else if (p.startsWith('product:')) {
              product = p.replaceFirst('product:', '');
            }
          }

          newDevices.add(DeviceInfo(
            serial: serial,
            model: model,
            brand: product,
            status: state,
          ));
        }
      }

      _devices = newDevices;

      // Update selected device
      if (_devices.isEmpty) {
        _selectedDevice = null;
      } else {
        final existing = _selectedDevice != null
            ? _devices.firstWhere(
                (d) => d.serial == _selectedDevice!.serial,
                orElse: () => _devices.first,
              )
            : _devices.first;

        if (existing.isReady) {
          _selectedDevice = await _fetchDetailedDeviceInfo(existing);
        } else {
          _selectedDevice = existing;
        }
      }
    } catch (e) {
      if (!silent) {
        _addLog('خطا در دریافت لیست دستگاه‌ها', e.toString(), LogType.error);
      }
    } finally {
      if (!silent) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Fetches package install state, device owner state, accounts, battery, and props
  Future<DeviceInfo> _fetchDetailedDeviceInfo(DeviceInfo base) async {
    final serial = base.serial;
    var brand = base.brand;
    var model = base.model;
    var androidVersion = base.androidVersion;
    var sdkInt = base.sdkInt;
    var batteryLevel = base.batteryLevel;
    var isCharging = base.isCharging;
    var isInstalled = false;
    var isOwner = false;
    var isActiveAdmin = false;
    final accounts = <String>[];

    try {
      // 1. Props (brand, model, version, sdk)
      final brandRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'getprop', 'ro.product.brand']);
      if (brandRes.exitCode == 0 && brandRes.stdout.toString().trim().isNotEmpty) {
        brand = brandRes.stdout.toString().trim();
      }

      final modelRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'getprop', 'ro.product.model']);
      if (modelRes.exitCode == 0 && modelRes.stdout.toString().trim().isNotEmpty) {
        model = modelRes.stdout.toString().trim();
      }

      final verRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'getprop', 'ro.build.version.release']);
      if (verRes.exitCode == 0 && verRes.stdout.toString().trim().isNotEmpty) {
        androidVersion = verRes.stdout.toString().trim();
      }

      final sdkRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'getprop', 'ro.build.version.sdk']);
      if (sdkRes.exitCode == 0) {
        sdkInt = int.tryParse(sdkRes.stdout.toString().trim()) ?? 0;
      }

      // 2. Battery
      final batteryRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'dumpsys', 'battery']);
      if (batteryRes.exitCode == 0) {
        final bOut = batteryRes.stdout.toString();
        final levelMatch = RegExp(r'level:\s*(\d+)').firstMatch(bOut);
        if (levelMatch != null) {
          batteryLevel = int.tryParse(levelMatch.group(1)!) ?? -1;
        }
        final statusMatch = RegExp(r'status:\s*(\d+)').firstMatch(bOut);
        if (statusMatch != null) {
          isCharging = (statusMatch.group(1) == '2' || statusMatch.group(1) == '5');
        }
      }

      // 3. Package check
      final pmRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'pm', 'list', 'packages', targetPackage]);
      if (pmRes.exitCode == 0 && pmRes.stdout.toString().contains(targetPackage)) {
        isInstalled = true;
      }

      // 4. Device Owner & Active Admin check
      final dpmRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'dumpsys', 'device_policy']);
      if (dpmRes.exitCode == 0) {
        final dpmOut = dpmRes.stdout.toString();
        // Check if package is Device Owner
        if (dpmOut.contains('Device Owner:') || dpmOut.contains('admin=ComponentInfo{$targetReceiver}')) {
          if (dpmOut.contains(targetPackage)) {
            isOwner = true;
            isActiveAdmin = true;
          }
        }
        if (dpmOut.contains(targetReceiver)) {
          isActiveAdmin = true;
        }
      }

      // 5. Check accounts
      final accRes = await Process.run(
          _effectiveAdbPath, ['-s', serial, 'shell', 'dumpsys', 'account']);
      if (accRes.exitCode == 0) {
        final lines = accRes.stdout.toString().split('\n');
        for (final l in lines) {
          final trimmed = l.trim();
          if (trimmed.startsWith('Account {name=') ||
              trimmed.startsWith('Account: name=')) {
            final m = RegExp(r'name=([^,]+)').firstMatch(trimmed);
            if (m != null) {
              accounts.add(m.group(1)!.trim());
            } else {
              accounts.add(trimmed);
            }
          }
        }
      }
    } catch (_) {}

    return base.copyWith(
      brand: brand,
      model: model,
      androidVersion: androidVersion,
      sdkInt: sdkInt,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      isAppInstalled: isInstalled,
      isDeviceOwner: isOwner,
      isActiveAdmin: isActiveAdmin,
      accounts: accounts,
    );
  }

  /// Sets device owner:
  /// `adb shell dpm set-device-owner ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver`
  Future<AdbActionResult> setDeviceOwner(String serial) async {
    _setBusy(true, 'در حال فعال‌سازی دسترسی Device Owner...');
    try {
      final res = await runAdb(
        ['shell', 'dpm', 'set-device-owner', targetReceiver],
        deviceSerial: serial,
      );

      final output = (res.stdout.toString() + res.stderr.toString()).trim();

      if (output.contains('Success') ||
          output.contains('Active admin set to component') ||
          res.exitCode == 0) {
        _addLog(
          'موفقیت Device Owner',
          'دسترسی مالکیت دستگاه (Device Owner) با موفقیت به مفاد وان پلاس اعطا شد.',
          LogType.success,
        );
        await refreshDevices();
        return AdbActionResult(
          success: true,
          title: 'عملیات موفقیت‌آمیز بود',
          message:
              'دسترسی Device Owner با موفقیت به برنامه مفاد وان پلاس داده شد! اکنون تمام امکانات سیستمی فعال هستند.',
          rawOutput: output,
        );
      }

      // Handle common Android DPM error scenarios:
      if (output.contains('Not allowed to set the device owner because there are already some accounts') ||
          output.contains('already users on the device')) {
        final tip =
            'اندروید اجازه نمی‌دهد در دستگاهی که حساب کاربری (گوگل، تلگرام، واتساپ و...) در آن ثبت شده، Device Owner فعال شود.\n\nراه حل: لطفاً به تنظیمات گوشی > حساب‌ها (Accounts) رفته و موقتاً حساب‌های ثبت شده را حذف کنید. پس از فعالسازی Device Owner می‌توانید حساب‌هایتان را مجدداً وارد کنید.';
        _addLog('خطای وجود اکانت در گوشی', tip, LogType.error);
        return AdbActionResult(
          success: false,
          title: 'وجود اکانت در گوشی',
          message:
              'برای فعال‌سازی Device Owner نباید هیچ اکانتی (جیمیل، تلگرام و...) روی گوشی باشد.',
          rawOutput: output,
          troubleshootingTip: tip,
        );
      }

      if (output.contains('Unknown package') ||
          output.contains('ComponentInfo{$targetReceiver}')) {
        final tip =
            'برنامه مفاد وان پلاس هنوز روی گوشی نصب نشده است. لطفاً ابتدا از بخش «نصب APK» برنامه را نصب کنید.';
        _addLog('برنامه نصب نیست', tip, LogType.error);
        return AdbActionResult(
          success: false,
          title: 'برنامه نصب نیست',
          message: 'برنامه مفاد وان پلاس هنوز روی گوشی نصب نشده است.',
          rawOutput: output,
          troubleshootingTip: tip,
        );
      }

      if (output.contains('Security exception') ||
          output.contains('USB debugging (Security settings)')) {
        final tip =
            'در گوشی‌های شیائومی (MIUI / HyperOS)، باید گزینه «USB debugging (Security settings)» در بخش توسعه‌دهندگان فعال شود.';
        _addLog('نیاز به مجوز امنیتی شیائومی', tip, LogType.error);
        return AdbActionResult(
          success: false,
          title: 'تنظیمات امنیتی شیائومی',
          message:
              'در گوشی‌های شیائومی باید گزینه USB Debugging (Security settings) فعال باشد.',
          rawOutput: output,
          troubleshootingTip: tip,
        );
      }

      if (output.contains('already set') || output.contains('already a device owner')) {
        await refreshDevices();
        return AdbActionResult(
          success: true,
          title: 'قبلاً فعال شده است',
          message: 'دسترسی مالکیت دستگاه (Device Owner) در حال حاضر فعال است.',
          rawOutput: output,
        );
      }

      return AdbActionResult(
        success: false,
        title: 'خطا در فعال‌سازی',
        message: 'خطایی در اجرای دستور رخ داد: $output',
        rawOutput: output,
        troubleshootingTip:
            'بررسی کنید که آیا قفل صفحه یا حساب کاربری خاصی فعال است یا خیر.',
      );
    } catch (e) {
      return AdbActionResult(
        success: false,
        title: 'خطای سیستمی',
        message: e.toString(),
        rawOutput: e.toString(),
      );
    } finally {
      _setBusy(false);
    }
  }

  /// Removes active admin / device owner:
  /// Uses in-app broadcast first (clean clearance) followed by dpm remove-active-admin
  Future<AdbActionResult> removeDeviceAdmin(String serial) async {
    _setBusy(true, 'در حال لغو دسترسی ادمین / Device Owner...');
    try {
      // 1. Send in-app broadcast first to clear Device Owner via Android API (dpm.clearDeviceOwnerApp)
      await runAdb([
        'shell',
        'am',
        'broadcast',
        '-a',
        targetClearAction,
        '-n',
        targetClearReceiver,
      ], deviceSerial: serial);

      await Future.delayed(const Duration(milliseconds: 600));

      // 2. Remove active admin via DPM command
      final res = await runAdb(
        ['shell', 'dpm', 'remove-active-admin', targetReceiver],
        deviceSerial: serial,
      );

      final output = (res.stdout.toString() + res.stderr.toString()).trim();

      await refreshDevices();
      final currentDev = _selectedDevice;
      final bool isCleared = currentDev == null ||
          (!currentDev.isDeviceOwner && !currentDev.isActiveAdmin);

      if (isCleared ||
          output.contains('Success') ||
          output.contains('not an active admin') ||
          res.exitCode == 0 ||
          output.isEmpty) {
        _addLog(
          'لغو دسترسی ادمین',
          'دسترسی ادمین و Device Owner با موفقیت از برنامه سلب و آزاد شد.',
          LogType.success,
        );
        return AdbActionResult(
          success: true,
          title: 'سلب دسترسی موفق بود',
          message: 'دسترسی ادمین و Device Owner با موفقیت از برنامه برداشته شد.',
          rawOutput: output,
        );
      }

      if (output.contains('SecurityException') ||
          output.contains('non-test admin')) {
        return AdbActionResult(
          success: false,
          title: 'محدودیت امنیتی اندروید',
          message:
              'برای سلب دسترسی در نسخه‌های نهایی، برنامه باید نسخه آپدیت شده حاوی گیرنده سلب داخلی باشد.',
          rawOutput: output,
          troubleshootingTip:
              'لطفاً نسخه جدید برنامه (که حاوی گیرنده حذف است) را نصب کنید تا سلب دسترسی با یک کلیک انجام شود.',
        );
      }

      return AdbActionResult(
        success: false,
        title: 'عدم امکان سلب دسترسی',
        message: 'خروجی: $output',
        rawOutput: output,
      );
    } catch (e) {
      return AdbActionResult(
        success: false,
        title: 'خطای سیستمی',
        message: e.toString(),
        rawOutput: e.toString(),
      );
    } finally {
      _setBusy(false);
    }
  }

  /// Installs APK with full runtime permissions:
  /// `adb install -r -d -g "<path>"`
  Future<AdbActionResult> installApk(String serial, String apkPath) async {
    _setBusy(true, 'در حال انتقال و نصب فایل APK روی گوشی...');
    try {
      final res = await runAdb(
        ['install', '-r', '-d', '-g', apkPath],
        deviceSerial: serial,
      );

      final output = (res.stdout.toString() + res.stderr.toString()).trim();

      if (output.contains('Success')) {
        _addLog(
          'نصب موفق APK',
          'برنامه مفاد وان پلاس با تمام دسترسی‌ها با موفقیت نصب شد.',
          LogType.success,
        );
        await refreshDevices();
        return AdbActionResult(
          success: true,
          title: 'نصب با موفقیت انجام شد',
          message: 'برنامه با موفقیت نصب و تمام دسترسی‌های سیستمی اعطا گردید.',
          rawOutput: output,
        );
      }

      if (output.contains('INSTALL_FAILED_ALREADY_EXISTS')) {
        return AdbActionResult(
          success: false,
          title: 'برنامه قبلاً نصب شده',
          message: 'نسخه دیگری از برنامه نصب است.',
          rawOutput: output,
        );
      }

      if (output.contains('INSTALL_FAILED_USER_RESTRICTED')) {
        return AdbActionResult(
          success: false,
          title: 'نصب توسط کاربر محدود شده',
          message:
              'در شیائومی لطفاً گزینه Install via USB را در بخش Developer Options فعال کنید.',
          rawOutput: output,
          troubleshootingTip:
              'Developer Options > Install via USB را فعال کنید و پیام پاپ‌آپ روی گوشی را تأیید نمایید.',
        );
      }

      return AdbActionResult(
        success: false,
        title: 'خطا در نصب APK',
        message: output,
        rawOutput: output,
      );
    } catch (e) {
      return AdbActionResult(
        success: false,
        title: 'خطای فرآیند نصب',
        message: e.toString(),
        rawOutput: e.toString(),
      );
    } finally {
      _setBusy(false);
    }
  }

  /// Uninstalls target package
  Future<AdbActionResult> uninstallApp(String serial) async {
    _setBusy(true, 'در حال حذف برنامه از گوشی...');
    try {
      // First ensure device owner & admin are cleared so DELETE_FAILED_DEVICE_POLICY_MANAGER never happens
      await runAdb([
        'shell',
        'am',
        'broadcast',
        '-a',
        targetClearAction,
        '-n',
        targetClearReceiver,
      ], deviceSerial: serial);
      await Future.delayed(const Duration(milliseconds: 500));

      final res = await runAdb(['uninstall', targetPackage], deviceSerial: serial);
      final output = (res.stdout.toString() + res.stderr.toString()).trim();
      await refreshDevices();
      return AdbActionResult(
        success: output.contains('Success'),
        title: output.contains('Success') ? 'حذف برنامه موفق بود' : 'خطا در حذف',
        message: output,
        rawOutput: output,
      );
    } finally {
      _setBusy(false);
    }
  }

  /// Automated 1-Click Setup:
  /// Installs APK -> Verifies -> Sets Device Owner
  Future<AdbActionResult> performOneClickSetup(
      String serial, String apkPath) async {
    _setBusy(true, 'آغاز راه‌اندازی هوشمند خودکار...');
    try {
      // Step 1: Install APK
      _busyMessage = 'مرحله ۱ از ۲: در حال نصب فایل APK...';
      notifyListeners();
      final installRes = await installApk(serial, apkPath);
      if (!installRes.success &&
          !installRes.rawOutput.contains('ALREADY_EXISTS')) {
        return installRes;
      }

      // Step 2: Set Device Owner
      _busyMessage = 'مرحله ۲ از ۲: در حال فعال‌سازی دسترسی Device Owner...';
      notifyListeners();
      final ownerRes = await setDeviceOwner(serial);
      return ownerRes;
    } finally {
      _setBusy(false);
    }
  }

  /// Open phone Account Settings page
  Future<void> openAccountSettings(String serial) async {
    await runAdb(
      ['shell', 'am', 'start', '-a', 'android.settings.SYNC_SETTINGS'],
      deviceSerial: serial,
    );
  }

  /// Open phone Developer Options page
  Future<void> openDeveloperSettings(String serial) async {
    await runAdb(
      ['shell', 'am', 'start', '-a', 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS'],
      deviceSerial: serial,
    );
  }

  /// Reboot device
  Future<void> rebootDevice(String serial) async {
    await runAdb(['reboot'], deviceSerial: serial);
    await refreshDevices();
  }

  /// Restart ADB server
  Future<void> restartAdbServer() async {
    _setBusy(true, 'در حال راه‌اندازی مجدد سرور ADB...');
    try {
      await Process.run(_effectiveAdbPath, ['kill-server']);
      await Future.delayed(const Duration(milliseconds: 500));
      await Process.run(_effectiveAdbPath, ['start-server']);
      await refreshDevices();
      _addLog('راه‌اندازی ADB', 'سرور ADB با موفقیت مجدداً راه‌اندازی شد.', LogType.success);
    } catch (e) {
      _addLog('خطا در ریستارت ADB', e.toString(), LogType.error);
    } finally {
      _setBusy(false);
    }
  }

  /// Run arbitrary custom ADB command
  Future<String> runRawCommand(String command, {String? deviceSerial}) async {
    var clean = command.trim();
    if (clean.startsWith('adb ')) {
      clean = clean.substring(4).trim();
    }
    final parts = clean.split(RegExp(r'\s+'));
    final res = await runAdb(parts, deviceSerial: deviceSerial);
    return (res.stdout.toString() + res.stderr.toString()).trim();
  }

  void _setBusy(bool busy, [String message = '']) {
    _isBusy = busy;
    _busyMessage = message;
    notifyListeners();
  }
}
