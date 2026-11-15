import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/adb_service.dart';
import '../services/apk_manager.dart';
import '../theme/app_theme.dart';

class ApkSelectorCard extends StatefulWidget {
  final ApkManager apkManager;
  final AdbService adbService;

  const ApkSelectorCard({
    super.key,
    required this.apkManager,
    required this.adbService,
  });

  @override
  State<ApkSelectorCard> createState() => _ApkSelectorCardState();
}

class _ApkSelectorCardState extends State<ApkSelectorCard> {
  ApkSourceInfo? _activeInfo;
  ApkSourceInfo? _asInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _isLoading = true);
    final active = await widget.apkManager.getActiveApkInfo();
    final asInfo = await widget.apkManager.getAndroidStudioApkInfo();
    if (mounted) {
      setState(() {
        _activeInfo = active;
        _asInfo = asInfo;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCustomApk() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
      dialogTitle: 'انتخاب فایل APK برنامه مفاد وان پلاس',
    );

    if (files.isNotEmpty && files.first.path != null) {
      widget.apkManager.setCustomApk(files.first.path!);
      await _loadInfo();
    }
  }

  Future<void> _syncFromAndroidStudio() async {
    final ok = await widget.apkManager.syncFromAndroidStudio();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فایل بیلد اندروید استودیو با موفقیت همگام‌سازی شد.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
    await _loadInfo();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDev = widget.adbService.selectedDevice;
    final isDeviceReady = selectedDev != null && selectedDev.isReady;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.android_rounded,
                  color: AppTheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مدیریت و نصب بسته APK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'پوشه دائمی قرارگیری فایل آپدیت یا همگام‌سازی خودکار با Android Studio',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickCustomApk,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('انتخاب فایل دستی...'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),

          // Active APK Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _activeInfo?.title ?? 'app-release.apk',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _activeInfo?.formattedSize ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _activeInfo?.path ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'آخرین تاریخ ویرایش: ${_activeInfo?.formattedDate ?? "-"}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: (!isDeviceReady || widget.adbService.isBusy)
                            ? null
                            : () async {
                                final path = await widget.apkManager
                                    .getEffectiveApkPath();
                                if (path != null) {
                                  widget.adbService.installApk(
                                      selectedDev.serial, path);
                                }
                              },
                        icon: const Icon(Icons.install_mobile_rounded,
                            size: 18),
                        label: const Text('نصب روی گوشی'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          // Android Studio Build Auto-Detection Box
          if (_asInfo != null && _asInfo!.exists)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بیلد خروجی پروژه Android Studio شناسایی شد',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Text(
                          'حجم: ${_asInfo!.formattedSize} | آخرین بیلد: ${_asInfo!.formattedDate}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _syncFromAndroidStudio,
                    icon: const Icon(Icons.sync_rounded,
                        size: 14, color: AppTheme.accent),
                    label: const Text(
                      'کپی در پروژه دسکتاپ',
                      style: TextStyle(fontSize: 11, color: AppTheme.accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.accent.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Manual placement info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.textMuted, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مسیر دائمی برای قرار دادن دستی آپدیت‌ها: assets/apk/app-release.apk (برنامه به صورت خودکار نسخه جدید را تشخیص می‌دهد)',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
