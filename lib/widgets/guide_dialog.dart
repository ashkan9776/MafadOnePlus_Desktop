import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GuideDialog extends StatelessWidget {
  const GuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.menu_book_rounded, color: AppTheme.secondary),
          SizedBox(width: 12),
          Text(
            'راهنمای جامع راه‌اندازی و رفع خطاهای Device Owner',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: '۱. پیش‌نیاز اتصال و شناسایی گوشی',
                content:
                    '• به تنظیمات گوشی > درباره تلفن (About phone) بروید.\n• روی گزینه «شماره ساخت» (Build number) هفت بار متوالی ضربه بزنید تا حالت توسعه‌دهنده (Developer Options) فعال شود.\n• به گزینه‌های توسعه‌دهنده رفته و «اشکال‌زدایی USB» (USB Debugging) را روشن کنید.\n• پس از اتصال کابل، پیام تأیید اثر انگشت رایانه (RSA fingerprint) روی گوشی ظاهر می‌شود؛ تیک Always allow را بزنید و OK کنید.',
                icon: Icons.usb_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: '۲. رفع خطای اکانت‌ها (Accounts Detected)',
                content:
                    'ارور: "Not allowed to set the device owner because there are already some accounts on the device"\n\n'
                    'علت: طبق پروتکل امنیتی گوگل و اندروید، برای اعطای دسترسی Device Owner (مدیریت کل گوشی)، نباید هیچ اکانتی (جیمیل، واتساپ، تلگرام، اینستاگرام، سامسونگ اکانت و...) ثبت شده باشد.\n\n'
                    'راه‌حل: با دکمه «تنظیمات اکانت‌ها» در همین برنامه به صفحه حساب‌های گوشی بروید و تمام حساب‌ها را موقتاً حذف کنید. به محض زدن دکمه «فعال‌سازی Device Owner»، می‌توانید بدون هیچ مشکلی دوباره وارد تمام حساب‌هایتان شوید.',
                icon: Icons.account_circle_rounded,
                color: AppTheme.warning,
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: '۳. نکات اختصاصی گوشی‌های شیائومی (MIUI / HyperOS)',
                content:
                    'در شیائومی علاوه بر USB Debugging، باید گزینه زیر نیز حتماً فعال باشد:\n'
                    '• USB debugging (Security settings)\n'
                    '• Install via USB\n\n'
                    'نکته: فعال کردن این گزینه نیازمند ورود به حساب Mi Account و وجود سیم‌کارت در گوشی شیائومی است.',
                icon: Icons.phone_android_rounded,
                color: AppTheme.secondary,
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: '۴. نکات گوشی‌های سامسونگ',
                content:
                    'در برخی گوشی‌های سامسونگ، در صورت فعال بودن قابلیت‌های زیر ممکن است خطا ایجاد شود:\n'
                    '• Dual Messenger (پیام‌رسان دوتایی) در تنظیمات پیشرفته\n'
                    '• پوشه امن (Secure Folder) و Samsung Knox\n'
                    'در صورت بروز خطا، موقتاً Dual Messenger را غیرفعال کنید.',
                icon: Icons.security_rounded,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 14),
              _buildSection(
                title: '۵. دستورات دستی جهت استفاده در ترمینال',
                content:
                    'فعال‌سازی Device Owner:\n'
                    'adb shell dpm set-device-owner ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver\n\n'
                    'سلب دسترسی ادمین:\n'
                    'adb shell dpm remove-active-admin ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver\n\n'
                    'نصب کامل APK:\n'
                    'adb install -r -d -g app-release.apk',
                icon: Icons.terminal_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black87,
          ),
          child: const Text('متوجه شدم'),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMain,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
