# MyPengaduan Mobile App

Aplikasi mobile Flutter untuk sistem pengaduan masyarakat yang terintegrasi dengan backend Laravel. Studi kasus: RT 05 Gang Annur II.

## 📱 Features

- ✅ **Authentication** - Login, Register (verifikasi KTP), Forgot/Reset Password, Logout
- ✅ **Complaint Management** - List, Create, Edit, Detail, status tracking pengaduan
- ✅ **Announcements** - Pengumuman dari RT/admin, bookmark & komentar
- ✅ **Notifications** - Real-time push notification via Firebase Cloud Messaging (FCM)
- ✅ **Dashboard** - Statistik & quick actions untuk user
- ✅ **Profile Management** - Lihat & edit profile, ganti password
- ✅ **Admin Panel** - Kelola pengaduan, kategori, pengumuman, user, dan laporan/statistik

## 🛠️ Tech Stack

| Kategori | Library |
|---|---|
| Framework | Flutter 3.5.1+ |
| State Management | [provider](https://pub.dev/packages/provider) (`ChangeNotifier`) |
| Routing | [go_router](https://pub.dev/packages/go_router) |
| HTTP Client | [dio](https://pub.dev/packages/dio) |
| Storage | `flutter_secure_storage` (token), `shared_preferences` (preferensi) |
| Push Notification | `firebase_messaging` + `flutter_local_notifications` |
| Fonts | `google_fonts` (Nunito) |
| Export Laporan | `pdf`, `excel` |

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
├── config/           # Konfigurasi (base URL API, storage keys, dll)
├── models/           # Data models (JSON ⇄ Dart object)
├── services/         # API client (Dio) & integrasi FCM
├── providers/        # State management (ChangeNotifier)
├── routes/           # GoRouter & auth guard
├── theme/            # Design system terpusat
├── screens/          # UI per fitur (user & admin)
├── widgets/          # Komponen UI reusable
└── main.dart         # Entry point
```

Detail lengkap tiap layer dan alur datanya ada di [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🔧 Default Users

- **Admin**: admin@example.com / password
- **User**: user@example.com / password

---

## 📚 Documentation

Dokumentasi lebih detail tersedia di folder [`docs/`](docs/):

| Dokumen | Isi |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Struktur project, tanggung jawab tiap layer, alur data, alur autentikasi & push notification |
| [docs/THEME.md](docs/THEME.md) | Design system: palet warna, tipografi, style komponen, cara mengubah tema |
| [docs/ROUTING.md](docs/ROUTING.md) | Daftar route, auth guard, transisi halaman, cara menambah route baru |
| [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md) | Konfigurasi API, alur token, daftar endpoint per service, format response |
| [docs/QUICK_START.md](docs/QUICK_START.md) | Cara menjalankan app, hot reload, troubleshooting, tips kustomisasi |
| [lib/screens/admin/README.md](lib/screens/admin/README.md) | Struktur & aturan konsistensi UI khusus modul Admin |

---

**Version**: 1.0.0  
**Flutter**: 3.5.1+  
**Platform**: Android & iOS
