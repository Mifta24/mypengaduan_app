# 🎨 Tema & Design System

Seluruh styling visual aplikasi terpusat di satu file: [`lib/theme/app_theme.dart`](../lib/theme/app_theme.dart). Tujuannya supaya warna, radius, dan style komponen konsisten di semua screen (user & admin) tanpa perlu hardcode ulang di tiap widget.

> Lihat juga: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🌿 Konsep: Dark Forest Green

Identitas visual aplikasi mengangkat tema lingkungan/RT (pengaduan masyarakat di lingkungan RT 05 Gang Annur II) — warna hijau forest sebagai warna utama, dengan splash/landing screen bergradasi gelap dan ikon daun (`Icons.eco_rounded`) sebagai elemen dekoratif.

## 🎨 Palet Warna

### Warna Utama (komponen, button, icon)

| Token | Hex | Kegunaan |
|---|---|---|
| `AppTheme.primary` | `#2E7D32` | Warna utama UI — logo, button, app bar |
| `AppTheme.primaryDark` | `#1B5E20` | Hijau gelap — text utama, variant gelap |
| `AppTheme.primaryLight` | `#4CAF50` | Hijau terang — badge, aksen |
| `AppTheme.accent` | `#66BB6A` | Subtitle, highlight |
| `AppTheme.secondary` | `#1E6B3A` | Hijau forest — logo circle |

### Background Splash/Landing

| Token | Hex | Kegunaan |
|---|---|---|
| `AppTheme.bgDeep` | `#071A0F` | Gradient paling gelap |
| `AppTheme.bgDark` | `#0D2B1A` | Gradient gelap |
| `AppTheme.bgMid` | `#0F3D23` | Gradient sedang |

### Status Colors

| Token | Hex | Arti |
|---|---|---|
| `AppTheme.success` | `#4CAF50` | Pengaduan selesai |
| `AppTheme.warning` | `#D97706` | Pengaduan pending |
| `AppTheme.danger` | `#DC2626` | Pengaduan ditolak |
| `AppTheme.info` | `#1E6B3A` | Info umum |

### Warna Netral (layar terang — home, form, dsb.)

| Token | Hex | Kegunaan |
|---|---|---|
| `AppTheme.surface` | `#F1FDF4` | Background scaffold (hijau sangat pucat) |
| `AppTheme.card` | `#FFFFFF` | Background card |
| `AppTheme.border` | `#A5D6A7` | Border lembut (card, input, divider) |
| `AppTheme.textPrimary` | `#1B5E20` | Teks utama |
| `AppTheme.textSecondary` | `#4B7A5C` | Teks sekunder/label |

### Gradient Helper

```dart
AppTheme.splashGradient  // [bgDeep, bgDark, bgMid] — dipakai di SplashScreen
AppTheme.primaryGradient // [primary, primaryDark]  — dipakai di card/header bergradasi
```

---

## ✍️ Tipografi

Font menggunakan **Google Fonts — Nunito**, di-apply global lewat `GoogleFonts.nunitoTextTheme()` di `AppTheme.light`. Tidak perlu import font manual; `google_fonts` akan men-download & cache font saat pertama dijalankan (butuh koneksi internet di first run).

---

## 🧱 Komponen Ter-styling di `ThemeData`

`AppTheme.light` mengkonfigurasi `ThemeData` Material 3 dengan `ColorScheme.fromSeed(seedColor: primary)`, lalu override komponen berikut agar konsisten di seluruh app:

| Komponen | Style kunci |
|---|---|
| `AppBarTheme` | `centerTitle: true`, elevation 0, background putih, foreground `textPrimary` |
| `CardThemeData` | radius 14, border `AppTheme.border`, elevation 0 |
| `InputDecorationTheme` | filled putih, radius 12, focus border `primary` |
| `ElevatedButtonThemeData` | radius 12, background `primary`, elevation 0 |
| `TextButtonThemeData` / `OutlinedButtonThemeData` | radius 10–12, foreground `primary` |
| `ChipThemeData` | radius 10, border `AppTheme.border` |
| `NavigationBarThemeData` | indicator `primary` 12% alpha, label bold saat selected |
| `PopupMenuThemeData` / `DialogThemeData` | radius 12–14, border `AppTheme.border` |
| `SnackBarThemeData` | floating, radius 12, background `textPrimary` |

### Shared input decoration

Untuk form admin/edit yang butuh style input seragam (filled abu-abu + radius 10 + border warna sesuai state), gunakan helper:

```dart
TextFormField(
  decoration: AppTheme.inputDecoration(
    label: 'Nama Lengkap',
    hint: 'Masukkan nama',
    prefixIcon: const Icon(Icons.person_outline),
  ),
)
```

Ini menjaga semua input box (label, hint, focus/error border) terlihat sama tanpa duplikasi `InputDecoration` di setiap screen.

---

## 🧩 Aturan Konsistensi UI (khusus modul Admin)

Modul admin punya widget reusable tambahan di `lib/widgets/admin/` (`AdminSectionHeader`, `AdminInfoCard`, `AdminStatusBadge`, `AdminEmptyState`, dst). Aturan pemakaiannya didokumentasikan terpisah di [`lib/screens/admin/README.md`](../lib/screens/admin/README.md) supaya tidak duplikat — baca dokumen itu sebelum menambah screen admin baru.

---

## ➕ Cara Mengubah Tema

1. **Ubah warna** → edit konstanta `Color` di bagian atas `AppTheme` (`lib/theme/app_theme.dart`). Karena semua komponen membaca dari token ini, perubahan otomatis terpropagasi ke seluruh app.
2. **Ubah font** → ganti `GoogleFonts.nunitoTextTheme(...)` di method `AppTheme.light` dengan font lain dari package `google_fonts`.
3. **Ubah radius/elevation komponen tertentu** → edit `*ThemeData` yang relevan di `AppTheme.light`, jangan hardcode radius di screen individual.
4. **Tambah token warna baru** → tambahkan sebagai `static const Color` baru di `AppTheme` agar tetap satu sumber kebenaran (single source of truth).
