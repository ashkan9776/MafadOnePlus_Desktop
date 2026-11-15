import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/device_info.dart';
import '../services/adb_service.dart';
import '../theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  final DeviceInfo? device;
  final AdbService adbService;
  final VoidCallback onShowAccounts;

  const DeviceCard({
    super.key,
    required this.device,
    required this.adbService,
    required this.onShowAccounts,
  });

  @override
  Widget build(BuildContext context) {
    if (device == null) {
      return _buildDisconnectedState();
    }

    if (device!.isUnauthorized) {
      return _buildUnauthorizedState();
    }

    return _buildConnectedCard(context);
  }

  Widget _buildDisconnectedState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'دستگاهی متصل نیست',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'گوشی اندرویدی خود را با کابل USB متصل کرده و مطمئن شوید که USB Debugging روشن است.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepItem('۱', 'اتصال کابل USB'),
              const SizedBox(width: 12),
              _buildStepItem('۲', 'فعال‌سازی USB Debugging'),
              const SizedBox(width: 12),
              _buildStepItem('۳', 'تأیید پیام روی گوشی'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppTheme.primary,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthorizedState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: AppTheme.warning,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'دستگاه متصل است اما نیاز به اجازه دسترسی دارد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'شناسه دستگاه: ${device!.serial}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لطفاً صفحه گوشی را روشن کرده و در کادر باز شده تیک «Always allow from this computer» را بزنید و سپس OK را انتخاب کنید.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMain, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedCard(BuildContext context) {
    final d = device!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: d.isDeviceOwner
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.border,
          width: d.isDeviceOwner ? 1.5 : 1,
        ),
        boxShadow: d.isDeviceOwner
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header: Icon + Name + Serial + Battery
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: d.isDeviceOwner
                      ? AppTheme.primaryGradient
                      : const LinearGradient(
                          colors: [AppTheme.surfaceLight, Color(0xFF2D3748)],
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: d.isDeviceOwner ? Colors.black87 : AppTheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            d.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (d.isDeviceOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OWNER ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'شناسه: ${d.serial}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          tooltip: 'کپی سریال',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppTheme.textMuted,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: d.serial));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('شناسه سریال کپی شد'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'اندروید ${d.androidVersion} (API ${d.sdkInt})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Battery Pill
              if (d.batteryLevel >= 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        d.isCharging
                            ? Icons.battery_charging_full_rounded
                            : Icons.battery_std_rounded,
                        size: 18,
                        color: d.batteryLevel < 20
                            ? AppTheme.error
                            : AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${d.batteryLevel}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Status Badges Grid
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // 1. App Installation Badge
              _buildStatusBadge(
                label: d.isAppInstalled
                    ? 'اپلیکیشن مفاد وان پلاس نصب است'
                    : 'اپلیکیشن هنوز نصب نشده است',
                icon: d.isAppInstalled
                    ? Icons.check_circle_rounded
                    : Icons.cancel_outlined,
                isPositive: d.isAppInstalled,
              ),

              // 2. Device Owner Badge
              _buildStatusBadge(
                label: d.isDeviceOwner
                    ? 'دسترسی مالکیت دستگاه (Device Owner) فعال است'
                    : (d.isActiveAdmin
                        ? 'ادمین فعال است (اما Device Owner کامل نیست)'
                        : 'دسترسی Device Owner فعال نیست'),
                icon: d.isDeviceOwner
                    ? Icons.verified_user_rounded
                    : Icons.admin_panel_settings_outlined,
                isPositive: d.isDeviceOwner,
                isWarning: !d.isDeviceOwner && d.isActiveAdmin,
              ),

              // 3. Accounts Badge
              _buildAccountBadge(d),
            ],
          ),

          const SizedBox(height: 18),

          // Quick Device Action Buttons
          Row(
            children: [
              _buildQuickActionBtn(
                label: 'تنظیمات اکانت‌ها',
                icon: Icons.manage_accounts_rounded,
                tooltip: 'باز کردن صفحه حساب‌های گوشی برای بررسی و پاکسازی موقت',
                onTap: () => adbService.openAccountSettings(d.serial),
              ),
              const SizedBox(width: 10),
              _buildQuickActionBtn(
                label: 'تنظیمات توسعه‌دهندگان',
                icon: Icons.developer_mode_rounded,
                tooltip: 'باز کردن Developer Options در گوشی',
                onTap: () => adbService.openDeveloperSettings(d.serial),
              ),
              const SizedBox(width: 10),
              _buildQuickActionBtn(
                label: 'ریستارت گوشی',
                icon: Icons.restart_alt_rounded,
                tooltip: 'راه‌اندازی مجدد گوشی (adb reboot)',
                onTap: () => _confirmReboot(context, d.serial),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required IconData icon,
    required bool isPositive,
    bool isWarning = false,
  }) {
    final color = isPositive
        ? AppTheme.primary
        : (isWarning ? AppTheme.warning : AppTheme.error);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBadge(DeviceInfo d) {
    final count = d.accounts.length;
    final hasAcc = count > 0;
    final color = hasAcc ? AppTheme.warning : AppTheme.primary;

    return InkWell(
      onTap: onShowAccounts,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAcc ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              hasAcc
                  ? '$count حساب کاربری در گوشی یافت شد (نیاز به حذف موقت)'
                  : 'بدون اکانت (آماده برای فعال‌سازی Device Owner)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (hasAcc) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: AppTheme.warning),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15, color: AppTheme.textMuted),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.border),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _confirmReboot(BuildContext context, String serial) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('راه‌اندازی مجدد گوشی'),
        content: const Text('آیا می‌خواهید گوشی را ریستارت (Reboot) کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              adbService.rebootDevice(serial);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.black87,
            ),
            child: const Text('ریستارت'),
          ),
        ],
      ),
    );
  }
}
