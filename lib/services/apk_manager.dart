import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ApkSourceInfo {
  final String path;
  final String title;
  final int fileSizeBytes;
  final DateTime? lastModified;
  final bool exists;

  ApkSourceInfo({
    required this.path,
    required this.title,
    required this.fileSizeBytes,
    required this.lastModified,
    required this.exists,
  });

  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 MB';
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    if (lastModified == null) return 'نامشخص';
    final d = lastModified!;
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class ApkManager extends ChangeNotifier {
  static const String defaultAndroidStudioBuildPath =
      '/home/ashkan/StudioProjects/Mafad_One_Plus/app/build/outputs/apk/release/app-release.apk';

  String? _customApkPath;
  String? _extractedAssetApkPath;
  bool _preferAndroidStudioBuild = true;

  String? get customApkPath => _customApkPath;
  bool get preferAndroidStudioBuild => _preferAndroidStudioBuild;

  set preferAndroidStudioBuild(bool value) {
    _preferAndroidStudioBuild = value;
    notifyListeners();
  }

  void setCustomApk(String? path) {
    _customApkPath = path;
    notifyListeners();
  }

  void resetToDefault() {
    _customApkPath = null;
    notifyListeners();
  }

  /// Gets information about the currently active APK that would be installed.
  Future<ApkSourceInfo> getActiveApkInfo() async {
    final activePath = await getEffectiveApkPath();
    if (activePath == null) {
      return ApkSourceInfo(
        path: '',
        title: 'هیچ فایلی یافت نشد',
        fileSizeBytes: 0,
        lastModified: null,
        exists: false,
      );
    }

    final file = File(activePath);
    if (!await file.exists()) {
      return ApkSourceInfo(
        path: activePath,
        title: p.basename(activePath),
        fileSizeBytes: 0,
        lastModified: null,
        exists: false,
      );
    }

    final stat = await file.stat();
    return ApkSourceInfo(
      path: activePath,
      title: p.basename(activePath),
      fileSizeBytes: stat.size,
      lastModified: stat.modified,
      exists: true,
    );
  }

  /// Gets info about the Android Studio build if available.
  Future<ApkSourceInfo?> getAndroidStudioApkInfo() async {
    final file = File(defaultAndroidStudioBuildPath);
    if (await file.exists()) {
      final stat = await file.stat();
      return ApkSourceInfo(
        path: defaultAndroidStudioBuildPath,
        title: 'بیلد Android Studio (Mafad_One_Plus)',
        fileSizeBytes: stat.size,
        lastModified: stat.modified,
        exists: true,
      );
    }
    return null;
  }

  /// Resolves the absolute path to the APK ready for `adb install`.
  Future<String?> getEffectiveApkPath() async {
    // 1. If user picked a custom APK file and it exists
    if (_customApkPath != null && _customApkPath!.isNotEmpty) {
      final f = File(_customApkPath!);
      if (await f.exists()) return f.path;
    }

    // 2. If Android Studio build exists and preferred
    if (_preferAndroidStudioBuild) {
      final asFile = File(defaultAndroidStudioBuildPath);
      if (await asFile.exists()) {
        return asFile.path;
      }
    }

    // 3. Fallback to bundled asset APK
    if (_extractedAssetApkPath != null && await File(_extractedAssetApkPath!).exists()) {
      return _extractedAssetApkPath;
    }

    try {
      final tempDir = await getApplicationSupportDirectory();
      final targetFile = File(p.join(tempDir.path, 'bundled_mafad_release.apk'));

      // Extract asset byte stream to target file
      final byteData = await rootBundle.load('assets/apk/app-release.apk');
      await targetFile.create(recursive: true);
      await targetFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
      _extractedAssetApkPath = targetFile.path;
      return _extractedAssetApkPath;
    } catch (e) {
      debugPrint('Error extracting bundled asset APK: $e');
    }

    // 4. Try workspace asset path directly as fallback on desktop
    final localAsset = File('assets/apk/app-release.apk');
    if (await localAsset.exists()) {
      return localAsset.absolute.path;
    }

    return null;
  }

  /// Syncs / copies Android Studio build APK to the desktop project assets
  Future<bool> syncFromAndroidStudio() async {
    try {
      final source = File(defaultAndroidStudioBuildPath);
      if (!await source.exists()) return false;

      final target = File('assets/apk/app-release.apk');
      await target.parent.create(recursive: true);
      await source.copy(target.path);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error copying APK: $e');
      return false;
    }
  }
}
