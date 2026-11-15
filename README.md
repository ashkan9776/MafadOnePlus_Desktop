# 📱 مفاد وان پلاس | Mafad One Plus Desktop Pro

نرم‌افزار حرفه‌ای و مدرن دسکتاپ (توسعه‌یافته با Flutter) جهت مدیریت و اعطای خودکار دسترسی **Device Owner** (مالکیت دستگاه) و نصب آسان اپلیکیشن **مفاد وان پلاس** بدون نیاز به وارد کردن دستی دستورات پیچیده ADB در ترمینال.

---

## ✨ قابلیت‌ها و امکانات کلیدی

1. **اعطای خودکار دسترسی Device Owner (مالکیت دستگاه)**:
   - اجرای خودکار دستور:
     ```bash
     adb shell dpm set-device-owner ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver
     ```
   - تشخیص هوشمند و راهنمایی گام‌به‌گام خطاهای معروف اندروید (مانند خطای وجود اکانت در گوشی یا تنظیمات امنیتی شیائومی).

2. **سلب دسترسی ادمین و حذف کامل برنامه**:
   - اجرای دستور:
     ```bash
     adb shell dpm remove-active-admin ir.akhtardanesh.mafadoneplus/.MyDeviceAdminReceiver
     ```
   - امکان حذف کامل برنامه (`adb uninstall ir.akhtardanesh.mafadoneplus`).

3. **راه‌اندازی هوشمند ۱ کلیکه (1-Click Auto Setup)**:
   - نصب خودکار بسته APK + اعطای تمام مجوزهای زمان اجرا (`-g`) + تنظیم بلادرنگ دسترسی Device Owner تنها با یک کلیک.

4. **مدیریت هوشمند بسته APK و مسیرهای آپدیت**:
   - **مسیر پیش‌فرض دائمی در پروژه دسکتاپ**: `assets/apk/app-release.apk`
   - **تشخیص خودکار بیلد اندروید استودیو**: برنامه به طور خودکار بیلد خروجی پروژه شما را در مسیر زیر بررسی می‌کند و با یک دکمه همگام‌سازی می‌نماید:
     ```
     /home/ashkan/StudioProjects/Mafad_One_Plus/app/build/outputs/apk/release/app-release.apk
     ```
   - **امکان انتخاب هر فایل APK دلخواه** از کامپیوتر با File Picker نیتیو.

5. **داشبورد مانیتورینگ سخت‌افزار گوشی**:
   - نمایش مدل و برند دستگاه (مانند Samsung, Xiaomi, Google Pixel).
   - نمایش نسخه اندروید و شماره SDK.
   - نمایش درصد باتری و وضعیت شارژ.
   - وضعیت نصب بودن برنامه و وضعیت فعال بودن Device Owner.
   - اسکن خودکار حساب‌های کاربری فعال روی گوشی (`dumpsys account`) با دکمه باز کردن مستقیم صفحه حساب‌ها در گوشی.

6. **ترمینال و لاگ زنده ADB (Live Console)**:
   - مشاهده کامل تمام رویدادها و دستورات ارسال شده با رنگ‌بندی تفکیک‌شده.
   - امکان کپی و پاکسازی لاگ‌ها.
   - خط فرمان مستقیم برای اجرای دستورات سفارشی ADB.

---

## 🚀 نحوه اجرا و استفاده

### اجرای سریع نسخه کامپایل‌شده (Release):
```bash
cd /home/ashkan/Projects/Android/MafadOnePlus_Desktop
./run.sh
```

یا در حالت توسعه:
```bash
flutter run -d linux
```

### خروجی گرفتن برای ویندوز (Windows Build):
این پروژه به صورت چندسکویی نوشته شده و ابزارهای adb برای ویندوز نیز در پوشه assets آن قرار داده شده است:
```bash
flutter build windows --release
```

---

## 📂 ساختار پروژه

```
MafadOnePlus_Desktop/
├── assets/
│   ├── apk/
│   │   └── app-release.apk           # فایل APK پیش‌فرض
│   ├── fonts/
│   │   └── Vazirmatn-*.ttf           # فونت‌های زیبای وزیرمتن
│   └── platform-tools-windows/       # ابزارهای پرتابل ADB برای ویندوز
├── lib/
│   ├── models/                       # مدل‌های دستگاه و لاگ‌ها
│   ├── services/
│   │   ├── adb_service.dart          # هسته مدیریت فرآیندها و دستورات ADB
│   │   └── apk_manager.dart          # مدیریت نسخه‌های APK و همگام‌سازی
│   ├── theme/
│   │   └── app_theme.dart            # تم دارک نئونی و استایل‌های مدرن
│   ├── widgets/                      # کامپوننت‌ها و کارت‌های تعاملی
│   └── main.dart                     # نقطه ورود و پنجره دسکتاپ
└── run.sh                            # اسکریپت اجرای سریع
```
