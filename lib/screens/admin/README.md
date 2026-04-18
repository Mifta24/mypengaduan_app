# Admin Module Structure

Struktur folder admin sudah dibagi per fitur, dengan design system sederhana agar visual konsisten antar tab.

## 📁 Struktur Folder

```
lib/screens/admin/
├── dashboard/
│   └── admin_dashboard_screen.dart
├── home/
│   └── home_tab.dart
├── complaints/
│   ├── complaints_tab.dart
│   └── resolve_complaint_screen.dart
├── users/
│   └── users_tab.dart
├── announcements/
│   ├── announcements_tab.dart
│   ├── add_announcement_screen.dart
│   ├── edit_announcement_screen.dart
│   └── announcement_detail_screen.dart
├── categories/
│   ├── categories_tab.dart
│   ├── add_category_screen.dart
│   ├── edit_category_screen.dart
│   └── category_detail_screen.dart
├── reports/
│   └── reports_tab.dart
└── profile/
     └── admin_profile_screen.dart
```

## 🎨 Admin Design System (Current)

Theme utama:
- `lib/theme/app_theme.dart`

Reusable admin widgets:
- `lib/widgets/admin/admin_section_header.dart`
- `lib/widgets/admin/admin_filter_panel.dart`
- `lib/widgets/admin/admin_empty_state.dart`
- `lib/widgets/admin/admin_status_badge.dart`
- `lib/widgets/admin/admin_info_card.dart`

## ✅ Aturan Konsistensi UI Admin

1. **Header section**
    - Gunakan `AdminSectionHeader` untuk judul + subtitle + ikon.

2. **Search/filter area**
    - Bungkus dengan `AdminFilterPanel`.

3. **Card list/grid item**
    - Gunakan `AdminInfoCard` untuk border, radius, padding, dan tap behavior yang seragam.

4. **Status chip/badge**
    - Gunakan `AdminStatusBadge`.

5. **Empty state**
    - Gunakan `AdminEmptyState`.

6. **Action visual**
    - Style tombol/menu mengikuti `AppTheme` (`popupMenuTheme`, button themes, iconButtonTheme, snackbarTheme).

## 🔄 State Management Pattern

Mayoritas tab admin memakai:
- `AutomaticKeepAliveClientMixin`
- cache memory sederhana (`_hasLoadedDataGlobally` + list/map cache)
- `RefreshIndicator` untuk force refresh

## 🚀 Navigation Overview

```
AdminDashboardScreen
├─ Home
├─ Aduan
├─ User
├─ Info
├─ Kategori
└─ Laporan
```

FAB konteks:
- Tab Info → tambah pengumuman
- Tab Kategori → tambah kategori

## 📦 Dependensi Utama Modul Admin

- `admin_service.dart` untuk API admin
- `auth_provider.dart` / provider lain untuk state lintas modul
- Material 3 + theme terpusat (`AppTheme`)
