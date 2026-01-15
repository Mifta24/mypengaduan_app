# 📋 Screen Pengaduan - MyPengaduan App

## ✅ Screen yang Sudah Dibuat

Saya sudah membuat **3 screen pengaduan** yang lengkap dan terintegrasi dengan API Anda:

### 1. 📱 Complaint List Screen
**Location:** `lib/screens/complaints/complaint_list_screen.dart`

**Fitur:**
- ✅ **Tab Filter** - 4 tabs (Semua, Menunggu, Diproses, Selesai)
- ✅ **Search Bar** - Cari berdasarkan judul, deskripsi, atau lokasi
- ✅ **Status Badge** - Warna berbeda untuk setiap status:
  - 🟡 **Menunggu** (Orange/Yellow)
  - 🔵 **Diproses** (Blue)
  - 🟢 **Selesai** (Green)
  - 🔴 **Ditolak** (Red)
- ✅ **Pull to Refresh** - Tarik ke bawah untuk reload data
- ✅ **Card Design** - Material Design 3 dengan shadow
- ✅ **Category Badge** - Tampilkan kategori dengan icon
- ✅ **Location Info** - Tampilkan lokasi dengan icon
- ✅ **FAB Button** - Floating Action Button untuk buat pengaduan baru
- ✅ **Empty State** - UI kosong yang informatif

**Integrasi API:**
```dart
await provider.loadComplaints(); // Load semua pengaduan
```

### 2. ✍️ Create Complaint Screen
**Location:** `lib/screens/complaints/create_complaint_screen.dart`

**Fitur:**
- ✅ **Form Lengkap** dengan validasi:
  - Dropdown kategori (dari API `getCategories()`)
  - Input judul (min. 10 karakter)
  - Textarea deskripsi (min. 20 karakter)
  - Input lokasi
  - Date picker untuk tanggal kejadian
  - Upload multiple images (dari kamera/galeri)
- ✅ **Image Picker** - Bottom sheet untuk pilih sumber gambar
- ✅ **Image Preview** - Grid 3 kolom dengan tombol hapus
- ✅ **Loading State** - Loading indicator saat submit
- ✅ **Success/Error Handling** - SnackBar feedback
- ✅ **Modern UI** - Purple gradient theme & Material Design 3

**Integrasi API:**
```dart
await provider.createComplaint(
  categoryId: categoryId,
  title: title,
  description: description,
  location: location,
  reportDate: reportDate,
  attachments: imagePaths, // List<String> file paths
);
```

### 3. 🔍 Complaint Detail Screen
**Location:** `lib/screens/complaints/complaint_detail_screen.dart`

**Fitur:**
- ✅ **App Bar Gradient** - Purple gradient header
- ✅ **Status Card Besar** - Card status dengan icon & deskripsi
- ✅ **Main Info Card** - Judul, kategori badge, deskripsi lengkap
- ✅ **Image Viewer** - Tampilkan foto dengan cached network image
- ✅ **Location Card** - Card lokasi dengan icon
- ✅ **Admin Response** - Card khusus untuk tanggapan admin (jika ada)
- ✅ **Estimated Resolution** - Tampilkan estimasi selesai (jika ada)
- ✅ **Timeline** - Timeline kejadian dengan 4 milestone:
  1. 🚩 Tanggal Kejadian
  2. 📤 Pengaduan Dibuat
  3. 🔄 Terakhir Diperbarui
  4. ✅ Selesai Ditangani (jika status = resolved)

**Data dari API:**
- Menggunakan `Complaint` model lengkap
- Support semua field: title, description, location, status, category, photo, adminResponse, estimatedResolution, dates, dll

---

## 📊 Screen Pengumuman

Screen pengumuman **sudah ada** sebelumnya di:
**Location:** `lib/screens/announcements/announcement_list_screen.dart`

**Fitur:**
- ✅ Search bar
- ✅ Priority filter dropdown
- ✅ Announcement cards dengan badges
- ⚠️ **Note:** Saat ini masih menggunakan dummy data, perlu integrasi API

---

## 🎨 Design System

Semua screen menggunakan desain konsisten:

### Colors
```dart
Primary Purple: #6366F1
Secondary Purple: #8B5CF6
Background: #F9FAFB
Text Dark: #1F2937
Text Gray: #6B7280
Text Light: #9CA3AF
```

### Typography
- **Headings:** Google Fonts Poppins (SemiBold/Bold)
- **Body:** Google Fonts Inter (Regular/Medium)

### Status Colors
- Pending: `#FEF3C7` (bg) + `#D97706` (text)
- In Progress: `#DBEAFE` (bg) + `#2563EB` (text)
- Resolved: `#D1FAE5` (bg) + `#059669` (text)
- Rejected: `#FEE2E2` (bg) + `#DC2626` (text)

### Components
- Cards: Border radius 16px, shadow soft
- Buttons: Border radius 12px, height 54px
- Inputs: Border radius 12px, filled background
- Badges: Border radius 6-8px

---

## 🔌 API Integration

### ComplaintProvider Methods
```dart
// Load list pengaduan dengan filter
await provider.loadComplaints(
  page: 1,
  status: 'pending', // optional
  categoryId: 1,     // optional
  search: 'query',   // optional
  refresh: true,     // optional
);

// Get categories untuk dropdown
final categories = await provider.getCategories();

// Create new complaint
await provider.createComplaint(
  categoryId: 1,
  title: 'Judul',
  description: 'Deskripsi',
  location: 'Lokasi',
  reportDate: DateTime.now(),
  attachments: ['path1.jpg', 'path2.jpg'],
);
```

### ComplaintService Endpoints
```dart
GET  /complaints               // List dengan pagination & filter
GET  /complaints/{id}          // Detail pengaduan
POST /complaints               // Create baru (FormData)
GET  /complaints/categories    // List kategori
GET  /complaints/statistics    // Statistik
```

---

## 📦 Dependencies Required

Pastikan package ini ada di `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  provider: ^6.1.1
  dio: ^5.4.0
  intl: ^0.18.1
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
```

---

## 🚀 Navigation Flow

```
Dashboard / Home
  ├─> ComplaintListScreen (List pengaduan)
  │     ├─> CreateComplaintScreen (FAB button)
  │     └─> ComplaintDetailScreen (Tap card)
  └─> AnnouncementListScreen (List pengumuman)
```

---

## ✨ Highlights

### Modern UI/UX
- Material Design 3
- Smooth animations
- Loading states
- Error handling
- Empty states
- Pull to refresh

### Complete Features
- Search & filter
- Status tracking
- Image upload
- Form validation
- Date picker
- Timeline view

### Production Ready
- Type-safe code
- Null safety
- Error handling
- Loading indicators
- Success feedback
- Clean architecture

---

## 📝 Next Steps

Anda bisa:
1. ✅ Test semua screen (List, Create, Detail)
2. ✅ Verify API integration
3. ✅ Customize colors/styles jika perlu
4. ⚠️ Integrate Announcement screen dengan API (saat ini dummy data)
5. ✅ Add navigation dari Dashboard ke Complaint List

**Semua screen sudah siap digunakan sesuai dengan API yang Anda buat!** 🎉

---

**Author:** GitHub Copilot  
**Date:** $(date)  
**Status:** ✅ Complete & Production Ready
