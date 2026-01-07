# 🚀 Quick Setup Guide - MyPengaduan Flutter App

Panduan singkat untuk setup dan menjalankan aplikasi.

---

## ✅ Checklist Pre-requisites

- [ ] Flutter SDK terinstall (3.5.1+)
- [ ] Android Studio / VS Code dengan Flutter extension
- [ ] Backend Laravel MyPengaduan sudah running
- [ ] Firebase account (untuk push notifications)

---

## 📋 Step by Step Setup

### 1. Install Dependencies

```powershell
cd c:\Aplikasi-Mobile\mypengaduan_app
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in mypengaduan_app...
Resolving dependencies...
Got dependencies!
```

---

### 2. Accept Android Licenses

```powershell
flutter doctor --android-licenses
```

Tekan `y` untuk accept semua licenses.

---

### 3. Setup Firebase

#### Option A: Otomatis (Recommended)

```powershell
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

Pilih:
1. Select atau create Firebase project
2. Select platform: Android (dan iOS jika ingin)
3. File `firebase_options.dart` akan otomatis ter-generate

#### Option B: Manual

1. Buat project di https://console.firebase.google.com/
2. Add Android app dengan package name: `com.example.mypengaduan_app`
3. Download `google-services.json`
4. Letakkan di folder: `android/app/google-services.json`
5. Edit `lib/firebase_options.dart` dengan credentials Anda

---

### 4. Configure Backend API URL

Edit file: `lib/config/app_config.dart`

Ganti IP address dengan IP server backend Anda:

```dart
static const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://192.168.1.100:8000/api/', // <-- Ganti ini
);
```

**Cara cari IP address server:**

```powershell
ipconfig
```

Cari `IPv4 Address` di network adapter yang aktif.

---

### 5. Start Backend Server

Buka terminal baru, jalankan backend:

```powershell
cd C:\laragon\www\mypengaduan
php artisan serve --host=0.0.0.0 --port=8000
```

**Expected Output:**
```
Starting Laravel development server: http://0.0.0.0:8000
```

Biarkan terminal ini tetap berjalan!

---

### 6. Run Flutter App

```powershell
# Connect device atau start emulator terlebih dahulu

# Run app
flutter run
```

**Atau dengan custom API URL:**

```powershell
flutter run --dart-define=BASE_URL=http://192.168.1.100:8000/api/
```

---

## 🧪 Testing

### Login dengan akun default:

**Admin:**
- Email: `admin@example.com`
- Password: `password`

**User:**
- Email: `user@example.com`
- Password: `password`

---

## 🐛 Common Issues & Solutions

### Issue: "DefaultFirebaseOptions not configured"

**Solution:**
```powershell
flutterfire configure
```

### Issue: "Connection refused"

**Causes & Solutions:**

1. **Backend tidak running**
   ```powershell
   cd C:\laragon\www\mypengaduan
   php artisan serve --host=0.0.0.0 --port=8000
   ```

2. **Wrong IP address**
   - Check IP dengan: `ipconfig`
   - Update `lib/config/app_config.dart`

3. **Firewall blocking**
   - Allow port 8000 di Windows Firewall
   - Atau disable Windows Firewall temporarily untuk testing

### Issue: "Android licenses not accepted"

**Solution:**
```powershell
flutter doctor --android-licenses
```

### Issue: "Gradle build failed"

**Solution:**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📱 Build APK

### Debug APK (for testing)
```powershell
flutter build apk --debug
```

### Release APK (for production)
```powershell
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## ✨ Next Steps After Setup

1. **Test Login** - Login dengan user default
2. **Check Dashboard** - Lihat statistik pengaduan
3. **Test Notifications** - Create complaint dari web admin, check notif di app
4. **Explore Features** - Browse complaints, notifications, profile

---

## 📞 Need Help?

1. Check `README.md` untuk dokumentasi lengkap
2. Check backend documentation di `C:\laragon\www\mypengaduan\docs\`
3. Run `flutter doctor` untuk check system setup

---

## 🎯 Development Commands

```powershell
# Check Flutter setup
flutter doctor

# Run app
flutter run

# Run with logs
flutter run -v

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

---

**Happy Coding! 🚀**
