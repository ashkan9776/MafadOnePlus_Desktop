import 'package:flutter/material.dart';
import '../models/device_info.dart';
import '../services/adb_service.dart';
import '../theme/app_theme.dart';

class AccountsDialog extends StatelessWidget {
  final DeviceInfo device;
  final AdbService adbService;

  const AccountsDialog({
    super.key,
    required this.device,
    required this.adbService,
  });

  @override
  Widget build(BuildContext context) {
    final accounts = device.accounts;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: AppTheme.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'حساب‌های کاربری موجود در گوشی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'طبق قوانین امنیتی اندروید، برای فعال‌سازی Device Owner باید تمام حساب‌های زیر موقتاً از بخش تنظیمات گوشی حذف شوند. بعد از اعطای دسترسی، می‌توانید مجدداً وارد آنها شوید.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMain,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'لیست اکانت‌های شناسایی شده:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: accounts.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'هیچ حسابی یافت نشد! دستگاه آماده فعال‌سازی Device Owner است.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_circle_outlined,
                                size: 18,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  acc,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMain,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('بستن'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            adbService.openAccountSettings(device.serial);
          },
          icon: const Icon(Icons.settings_suggest_rounded, size: 18),
          label: const Text('باز کردن تنظیمات حساب‌ها روی گوشی'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black87,
          ),
        ),
      ],
    );
  }
}
