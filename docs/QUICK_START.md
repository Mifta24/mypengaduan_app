# 🚀 Quick Start - MyPengaduan Android

## Cara Menjalankan Aplikasi dengan Desain Baru

### 1️⃣ Install Dependencies

```bash
flutter pub get
```

### 2️⃣ Run Aplikasi

#### Untuk Android Emulator
```bash
flutter run
```

#### Untuk Android Device (USB Debugging)
```bash
flutter run -d <device-id>
```

#### Untuk Chrome (Web Testing)
```bash
flutter run -d chrome
```

### 3️⃣ Hot Reload
Setelah aplikasi berjalan, Anda bisa melakukan perubahan dan tekan:
- **`r`** untuk hot reload
- **`R`** untuk hot restart
- **`q`** untuk quit

---

## 🎯 Fitur yang Bisa Dicoba

### ✅ Landing Screen
1. Jalankan aplikasi (jika belum login)
2. Lihat animasi fade & slide yang smooth
3. Scroll untuk melihat fitur-fitur
4. Tap tombol "Daftar Sekarang" atau "Masuk"

### ✅ Splash Screen
1. Restart aplikasi
2. Lihat animasi splash screen dengan gradient
3. Loading indicator yang modern

### ✅ Dashboard
1. Login ke aplikasi
2. Lihat statistics cards dengan gradients
3. Tap pada quick actions
4. Pull down untuk refresh
5. Perhatikan animasi pada cards

### ✅ Profile Screen
1. Tap icon "Profil" di bottom navigation
2. Lihat profile header dengan gradient
3. Scroll untuk melihat settings
4. Tap "Logout" untuk melihat confirmation dialog

---

## 🎨 Preview Screens

### Flow Aplikasi:
```
Splash Screen 
    ↓
Landing Screen (if not logged in)
    ↓
Login Screen
    ↓
Home Screen (Dashboard)
    ├─ Dashboard Tab
    ├─ Keluhan Tab
    ├─ Notifikasi Tab
    └─ Profil Tab
```

---

## 🔧 Troubleshooting

### Error: Google Fonts
Jika ada error terkait Google Fonts, pastikan koneksi internet aktif pada first run.

### Error: Firebase
Pastikan file `google-services.json` ada di folder `android/app/`

### Error: Build
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📱 Test Devices

Desain ini sudah dioptimalkan untuk:
- ✅ Android Phone (5" - 6.7")
- ✅ Android Tablet
- ✅ Web Browser (responsive)

---

## 💡 Tips

1. **Gunakan Android Emulator** dengan API Level 30+ untuk hasil terbaik
2. **Enable "Show layout bounds"** di Developer Options untuk melihat spacing
3. **Test dengan Dark Mode** device untuk memastikan kontras yang baik
4. **Test dengan font size besar** untuk accessibility

---

## 🎯 Key Improvements dari Desain Sebelumnya

| Aspek | Sebelumnya | Sekarang |
|-------|-----------|----------|
| Splash | Basic loading | Animated gradient splash |
| Landing | Tidak ada | Modern landing dengan features |
| Dashboard | Simple cards | Gradient cards dengan animation |
| Profile | Basic list | Premium profile dengan gradient header |
| Navigation | Standard | Enhanced dengan shadow dan colors |
| Colors | Basic blue | Rich gradient palette |
| Animations | Minimal | Smooth fade, scale, slide |
| Typography | Default | Google Fonts (Poppins & Inter) |

---

## 🎨 Customize Desain

### Ubah Warna Gradient
Edit di file yang relevan:
```dart
// Ubah gradient colors
gradient: LinearGradient(
  colors: [
    const Color(0xFF6366F1), // Ganti dengan warna favorit
    const Color(0xFF8B5CF6), // Ganti dengan warna favorit
  ],
)
```

### Ubah Fonts
Edit di `lib/main.dart`:
```dart
textTheme: GoogleFonts.robotoTextTheme(), // Ganti font
```

### Ubah Border Radius
Cari dan replace nilai border radius:
```dart
borderRadius: BorderRadius.circular(20), // Ubah nilai
```

---

## 📞 Support

Jika ada pertanyaan atau issue, silakan buat issue di repository atau hubungi developer.

---

**Happy Coding! 🚀**
