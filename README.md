# MyPengaduan Mobile App

Aplikasi mobile Flutter untuk sistem pengaduan masyarakat yang terintegrasi dengan backend Laravel. studi kasus rt 5 gang annur 2

## 📱 Features

- ✅ **Authentication** - Login, Register, Logout
- ✅ **Complaint Management** - List, Create, View complaints
- ✅ **Notifications** - Real-time push notifications via FCM
- ✅ **Dashboard** - User statistics and quick actions
- ✅ **Profile Management** - View and manage user profile

---

## 🚀 Setup & Installation

### Prerequisites

1. **Flutter SDK** (3.5.1 or higher)
2. **Android Studio** / VS Code with Flutter extensions
3. **Firebase Account** for push notifications
4. **Backend API** running (Laravel MyPengaduan)

### Installation Steps

#### 1. Clone & Install Dependencies

```bash
cd c:\Aplikasi-Mobile\mypengaduan_app
flutter pub get
```

#### 2. Configure Firebase

##### Option A: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

Ini akan otomatis membuat file `firebase_options.dart` dengan konfigurasi yang benar.

##### Option B: Manual Configuration

1. Buat project di [Firebase Console](https://console.firebase.google.com/)
2. Download `google-services.json` untuk Android dan letakkan di folder `android/app/`
3. Update file `lib/firebase_options.dart` dengan credentials Anda

#### 3. Configure API Base URL

Edit file `lib/config/app_config.dart` atau jalankan dengan environment variable:

```bash
flutter run --dart-define=BASE_URL=http://192.168.1.100:8000/api/
```

#### 4. Accept Android Licenses

```bash
flutter doctor --android-licenses
```

---

## 🏃 Running the App

```bash
# Run on connected device/emulator
flutter run

# Build APK
flutter build apk --release
```

---

## 📂 Project Structure

```
lib/
├── config/           # Configuration files
├── models/           # Data models
├── services/         # API & FCM services
├── providers/        # State management
├── screens/          # UI screens
└── main.dart        # Entry point
```

---

## 🔧 Default Users

- **Admin**: admin@example.com / password
- **User**: user@example.com / password

---

## 📚 Documentation

Lihat folder dokumentasi untuk panduan lengkap:
- Backend API integration
- Firebase setup
- Testing guide

---

**Version**: 1.0.0  
**Flutter**: 3.5.1+  
**Platform**: Android & iOS
