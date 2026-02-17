# Admin Module Structure

Struktur folder admin telah dirapihkan dan diorganisir berdasarkan fitur/modul.

## 📁 Struktur Folder

```
lib/screens/admin/
├── dashboard/
│   └── admin_dashboard_screen.dart    # Main admin dashboard dengan navigation
│
├── home/
│   └── home_tab.dart                  # Tab dashboard dengan statistik
│
├── complaints/
│   └── complaints_tab.dart            # Tab management pengaduan
│
├── users/
│   └── users_tab.dart                 # Tab management pengguna
│
└── announcements/
    ├── announcements_tab.dart         # Tab management pengumuman
    ├── add_announcement_screen.dart   # Screen tambah pengumuman
    └── edit_announcement_screen.dart  # Screen edit pengumuman
```

## 📋 Deskripsi Modul

### 1. **dashboard/**
Main screen admin yang menampilkan navigation bar dan mengatur routing antar tab.
- AdminDashboardScreen: Container utama dengan bottom navigation

### 2. **home/**
Tab pertama yang menampilkan statistik dan overview sistem.
- Quick stats: Total pengaduan, pending, processing, selesai
- User statistics
- Announcement statistics
- Pull to refresh untuk update data

### 3. **complaints/**
Management pengaduan dari user.
- List semua pengaduan
- Search & filter by status
- Update status (pending, processing, resolved, rejected)
- Detail pengaduan

### 4. **users/**
Management user dan role.
- List semua user
- Search & filter by role
- Verify user email & KTP
- Change user role (admin/user)
- View user details

### 5. **announcements/**
Management pengumuman untuk user.
- List semua pengumuman
- Search & filter by status
- CRUD operations (Create, Read, Update, Delete)
- Toggle status (aktif/nonaktif)
- Publish announcement
- Set priority (low, normal, high, urgent)
- Pin announcement (sticky)

## 🔄 State Management

Semua tab menggunakan:
- `AutomaticKeepAliveClientMixin` untuk maintain state saat switch tab
- `_hasLoadedData` flag untuk prevent reload berulang
- Pull to refresh untuk manual data update

## 🎨 UI Features

- Material 3 design dengan Card components
- Color-coded badges untuk status
- Icon-based menu actions
- Empty states dengan icons
- Loading indicators
- Error handling dengan SnackBar
- Search & filter capabilities
- Floating Action Button (FAB) untuk create actions

## 📦 Dependencies

- `admin_service.dart` - Service layer untuk API calls
- `auth_provider.dart` - Authentication state management
- Material Design 3 components

## 🚀 Navigation Flow

```
AdminDashboardScreen
├─→ Tab 0: AdminHomeTab (Statistics)
├─→ Tab 1: AdminComplaintsTab (Pengaduan)
├─→ Tab 2: AdminUsersTab (Pengguna)
└─→ Tab 3: AdminAnnouncementsTab (Pengumuman)
    ├─→ FAB → AddAnnouncementScreen
    └─→ Edit → EditAnnouncementScreen
```

## 📝 Import Paths

Update import statements:
```dart
// Old
import '../admin/admin_dashboard_screen.dart';

// New
import '../admin/dashboard/admin_dashboard_screen.dart';
```

## ✨ Features

- ✅ Organized folder structure
- ✅ Separation of concerns
- ✅ Reusable components
- ✅ Clean architecture
- ✅ Easy to maintain and extend
- ✅ Clear navigation hierarchy
- ✅ Modular design
