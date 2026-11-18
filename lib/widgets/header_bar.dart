import 'package:flutter/material.dart';
import '../services/adb_service.dart';
import '../models/device_info.dart';
import '../theme/app_theme.dart';

class HeaderBar extends StatelessWidget {
  final AdbService adbService;
  final VoidCallback onToggleConsole;
  final bool isConsoleOpen;
  final VoidCallback onOpenGuide;

  const HeaderBar({
    super.key,
    required this.adbService,
    required this.onToggleConsole,
    required this.isConsoleOpen,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // App Logo and Title
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text(
                    'مفاد وان پلاس',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      'Desktop Pro',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'مدیریت دسترسی مالکیت دستگاه (Device Owner) و نصب مستقیم APK',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),

          const Spacer(),

          // ADB Status Badge
          _buildAdbStatusBadge(),

          const SizedBox(width: 12),

          // Device Dropdown if > 1 device
          if (adbService.devices.length > 1) ...[
            _buildDeviceDropdown(),
            const SizedBox(width: 12),
          ],

          // Refresh Button
          IconButton(
            tooltip: 'بروزرسانی دستگاه‌ها (Refresh)',
            onPressed: adbService.isRefreshing
                ? null
                : () => adbService.refreshDevices(),
            icon: adbService.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              padding: const EdgeInsets.all(10),
            ),
          ),

          const SizedBox(width: 8),

          // Restart ADB server button
          IconButton(
            tooltip: 'راه‌اندازی مجدد سرور ADB',
            onPressed: () => adbService.restartAdbServer(),
            icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.warning),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              padding: const EdgeInsets.all(10),
            ),
          ),

          const SizedBox(width: 8),

          // Guide / Help Button
          IconButton(
            tooltip: 'راهنمای گام‌به‌گام و رفع خطاهای اندروید',
            onPressed: onOpenGuide,
            icon: const Icon(Icons.help_outline_rounded,
                color: AppTheme.secondary),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceLight,
              padding: const EdgeInsets.all(10),
            ),
          ),

          const SizedBox(width: 8),

          // Console Toggle Button
          ElevatedButton.icon(
            onPressed: onToggleConsole,
            icon: Icon(
              isConsoleOpen
                  ? Icons.terminal_rounded
                  : Icons.terminal_outlined,
              size: 18,
              color: isConsoleOpen ? Colors.black87 : AppTheme.textMain,
            ),
            label: Text(
              'ترمینال و لاگ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isConsoleOpen ? Colors.black87 : AppTheme.textMain,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isConsoleOpen ? AppTheme.primary : AppTheme.surfaceLight,
              foregroundColor:
                  isConsoleOpen ? Colors.black87 : AppTheme.textMain,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isConsoleOpen
                      ? AppTheme.primary
                      : AppTheme.border,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdbStatusBadge() {
    final bool available = adbService.isAdbAvailable;
    final int count = adbService.devices.length;

    Color color;
    String text;
    IconData icon;

    if (!available) {
      color = AppTheme.error;
      text = 'ADB در دسترس نیست';
      icon = Icons.error_outline_rounded;
    } else if (count == 0) {
      color = AppTheme.warning;
      text = 'در انتظار اتصال گوشی...';
      icon = Icons.usb_rounded;
    } else {
      color = AppTheme.primary;
      text = '$count دستگاه متصل';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
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

  Widget _buildDeviceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DeviceInfo>(
          value: adbService.selectedDevice,
          dropdownColor: AppTheme.surfaceLight,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
          items: adbService.devices.map((device) {
            return DropdownMenuItem<DeviceInfo>(
              value: device,
              child: Text(
                device.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMain,
                ),
              ),
            );
          }).toList(),
          onChanged: (device) {
            if (device != null) {
              adbService.selectDevice(device);
            }
          },
        ),
      ),
    );
  }
}
