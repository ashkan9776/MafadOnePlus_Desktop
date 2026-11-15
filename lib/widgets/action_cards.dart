import 'package:flutter/material.dart';
import '../services/adb_service.dart';
import '../services/apk_manager.dart';
import '../theme/app_theme.dart';

class ActionCards extends StatelessWidget {
  final AdbService adbService;
  final ApkManager apkManager;
  final VoidCallback onShowAccounts;

  const ActionCards({
    super.key,
    required this.adbService,
    required this.apkManager,
    required this.onShowAccounts,
  });

  @override
  Widget build(BuildContext context) {
    final dev = adbService.selectedDevice;
    final bool isReady = dev != null && dev.isReady;
    final bool isBusy = adbService.isBusy;

    return Column(
      children: [
        // 1. One-Click Automated Setup Hero Banner
        _buildOneClickHeroCard(context, dev, isReady, isBusy),

        const SizedBox(height: 16),

        // 2. Dual Action Row: Set Owner & Remove Admin
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Set Device Owner Card
            Expanded(
              child: _buildSetOwnerCard(context, dev, isReady, isBusy),
            ),

            const SizedBox(width: 16),

            // Remove Active Admin Card
            Expanded(
              child: _buildRemoveAdminCard(context, dev, isReady, isBusy),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOneClickHeroCard(
      BuildContext context, dynamic dev, bool isReady, bool isBusy) {
    final bool hasAccounts = dev != null && dev.hasAccounts;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'راه‌اندازی خودکار با یک کلیک (Smart 1-Click Setup)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'نصب بسته APK + اعطای تمام دسترسی‌ها + تنظیم کامل Device Owner در یک مرحله',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: (!isReady || isBusy)
                    ? null
                    : () async {
                        if (hasAccounts) {
                          _showAccountsWarningDialog(context);
                          return;
                        }
                        final apkPath =
                            await apkManager.getEffectiveApkPath();
                        if (apkPath != null) {
                          final res = await adbService.performOneClickSetup(
                              dev!.serial, apkPath);
                          if (context.mounted) {
                            _showResultDialog(context, res);
                          }
                        }
                      },
                icon: const Icon(Icons.flash_on_rounded, size: 20),
                label: const Text(
                  'شروع راه‌اندازی کامل',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),

          if (hasAccounts) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'توجه: ${dev.accounts.length} حساب کاربری روی گوشی فعال است. اندروید تا زمان حذف موقت حساب‌ها اجازه راه‌اندازی نخواهد داد.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onShowAccounts,
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 14, color: AppTheme.warning),
                    label: const Text('مشاهده و راهنما',
                        style: TextStyle(fontSize: 11, color: AppTheme.warning)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetOwnerCard(
      BuildContext context, dynamic dev, bool isReady, bool isBusy) {
    final bool isAlreadyOwner = dev != null && dev.isDeviceOwner;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlreadyOwner
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'فعال‌سازی Device Owner',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'اجرای دستور سیستمی اعطای بالاترین سطح مالکیت به برنامه مفاد وان پلاس:',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'adb shell dpm set-device-owner ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!isReady || isBusy)
                  ? null
                  : () async {
                      if (dev != null && dev.hasAccounts) {
                        _showAccountsWarningDialog(context);
                        return;
                      }
                      final res = await adbService.setDeviceOwner(dev!.serial);
                      if (context.mounted) {
                        _showResultDialog(context, res);
                      }
                    },
              icon: Icon(
                isAlreadyOwner
                    ? Icons.check_circle_rounded
                    : Icons.shield_rounded,
                size: 18,
              ),
              label: Text(
                isAlreadyOwner
                    ? 'اعطا مجدد / بروزرسانی دسترسی'
                    : 'اعطای دسترسی Device Owner',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveAdminCard(
      BuildContext context, dynamic dev, bool isReady, bool isBusy) {
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
                  color: AppTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppTheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'سلب دسترسی ادمین / حذف',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'حذف دسترسی ادمین سیستمی جهت اجازه دادن به حذف یا لغو نظارت برنامه:',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'adb shell dpm remove-active-admin ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.warning,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (!isReady || isBusy)
                      ? null
                      : () => _confirmRemoveAdmin(context, dev!.serial),
                  icon: const Icon(Icons.remove_moderator_rounded,
                      size: 16, color: AppTheme.warning),
                  label: const Text(
                    'سلب ادمین',
                    style: TextStyle(fontSize: 12, color: AppTheme.warning),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (!isReady || isBusy)
                      ? null
                      : () => _confirmUninstall(context, dev!.serial),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppTheme.error),
                  label: const Text(
                    'حذف کامل برنامه',
                    style: TextStyle(fontSize: 12, color: AppTheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemoveAdmin(BuildContext context, String serial) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('سلب دسترسی ادمین'),
        content: const Text(
          'آیا از لغو دسترسی ادمین برنامه مطمئن هستید؟ این کار اختیارات نظارتی را غیرفعال می‌کند.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              adbService.removeDeviceAdmin(serial);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.black87,
            ),
            child: const Text('تأیید و سلب'),
          ),
        ],
      ),
    );
  }

  void _confirmUninstall(BuildContext context, String serial) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('حذف کامل برنامه از گوشی'),
        content: const Text(
          'آیا می‌خواهید اپلیکیشن مفاد وان پلاس (ir.akhtardanesh.mafadoneplus) به طور کامل از گوشی حذف (Uninstall) شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              adbService.uninstallApp(serial);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('حذف برنامه'),
          ),
        ],
      ),
    );
  }

  void _showAccountsWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            SizedBox(width: 10),
            Text('خطای وجود حساب‌های کاربری (Accounts)'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سیستم عامل اندروید طبق ضوابط امنیتی به هیچ برنامه‌ای اجازه فعال‌سازی Device Owner را در صورتی که اکانتی (جیمیل، واتساپ، تلگرام و...) ثبت شده باشد، نمی‌دهد.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 12),
            Text(
              'راهکار:\n۱. به بخش تنظیمات گوشی > حساب‌ها بروید.\n۲. موقتاً حساب‌ها را حذف نمایید.\n۳. این دکمه را مجدداً بزنید تا دسترسی فعال شود.\n۴. پس از فعال‌سازی می‌توانید اکانت‌هایتان را مجدداً وارد نمایید.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (adbService.selectedDevice != null) {
                adbService
                    .openAccountSettings(adbService.selectedDevice!.serial);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black87,
            ),
            child: const Text('باز کردن تنظیمات حساب‌ها در گوشی'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, AdbActionResult res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Icon(
              res.success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: res.success ? AppTheme.primary : AppTheme.error,
            ),
            const SizedBox(width: 10),
            Text(res.title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(res.message, style: const TextStyle(height: 1.5)),
              if (res.troubleshootingTip != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          res.troubleshootingTip!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMain,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'خروجی خام ADB:',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  res.rawOutput.isEmpty ? '(خروجی بدون متن)' : res.rawOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black87,
            ),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }
}
