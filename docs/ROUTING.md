# 🧭 Routing & Navigasi

Aplikasi menggunakan [`go_router`](https://pub.dev/packages/go_router) dengan satu file pusat: [`lib/routes/app_router.dart`](../lib/routes/app_router.dart). File ini juga berisi `SplashScreen` (entry point pertama yang dilihat user).

> Lihat juga: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🚦 Alur Navigasi Utama

```
            SplashScreen ("/")
                  │
       cek token via AuthProvider.checkAuthStatus()
                  │
        ┌─────────┴─────────┐
   belum login          sudah login
        │                     │
   /landing              role == admin?
        │               ┌─────┴─────┐
  /login, /register    ya            tidak
                         │             │
                     /admin          /home
```

- **Splash** (`/`) selalu boleh diakses tanpa redirect — dia mengatur navigasinya sendiri lewat `_initializeApp()` (delay singkat untuk animasi, lalu cek auth status).
- Setelah splash, route guard global (`redirect` di `GoRouter`) mengambil alih untuk seluruh route lain.

## 🔐 Logic Redirect (Auth Guard)

Didefinisikan di `AppRouter.createRouter()` → `redirect:`. Ringkasannya:

| Kondisi | Hasil |
|---|---|
| Route adalah splash (`/`) | Tidak di-redirect, splash urus navigasi sendiri |
| Sudah login & menuju `/home` atau `/admin` | Tidak di-redirect (akses langsung diizinkan) |
| **Belum** login & menuju route selain auth (`/login`, `/register`, `/forgot-password`, `/landing`) | Redirect ke `/landing` |
| **Sudah** login & menuju route auth (`/login`, `/register`, dll) | Redirect ke `/admin` (jika role admin) atau `/home` (jika user biasa) |

Role admin ditentukan dari `authProvider.user?.role == 'admin'`.

---

## 🗺️ Daftar Route

### Publik / Auth

| Path | Nama | Screen |
|---|---|---|
| `/` | `splash` | `SplashScreen` |
| `/landing` | `landing` | `LandingScreen` |
| `/login` | `login` | `LoginScreen` |
| `/register` | `register` | `RegisterScreen` |
| `/forgot-password` | `forgotPassword` | `ForgotPasswordScreen` |

### User (setelah login)

| Path | Nama | Screen |
|---|---|---|
| `/home` | `home` | `HomeScreen` (bottom nav: Dashboard, Keluhan, Notifikasi, Profil) |
| `/create-complaint` | `createComplaint` | `CreateComplaintScreen` |
| `/complaint/:id` | `complaintDetail` | `ComplaintDetailScreen` (param `id` di-parse ke `int`) |
| `/my-complaints` | `myComplaints` | `ComplaintListScreen` |
| `/profile` | `profile` | `ProfileScreen` |
| `/edit-profile` | `editProfile` | `EditProfileScreen` |
| `/announcements/list` | `announcementsList` | `AnnouncementListScreen` |
| `/notifications` | `notifications` | `NotificationListScreen` |
| `/notification-settings` | `notificationSettings` | `NotificationSettingsScreen` |
| `/faq` | `faq` | `FaqScreen` |
| `/contact` | `contact` | `ContactScreen` |

### Admin

| Path | Nama | Screen |
|---|---|---|
| `/admin` | `adminDashboard` | `AdminDashboardScreen` |
| `/admin/profile` | `adminProfile` | `AdminProfileScreen` |
| `/admin/profile/edit` | `adminProfileEdit` | `EditAdminProfileScreen` *(butuh `extra: User`)* |
| `/admin/categories` | `adminCategoriesManage` | `AdminCategoriesTab` |
| `/admin/categories/add` | `adminCategoriesAdd` | `AddCategoryScreen` |
| `/admin/categories/edit` | `adminCategoriesEdit` | `EditCategoryScreen` *(`extra`)* |
| `/admin/categories/detail` | `adminCategoryDetail` | `AdminCategoryDetailScreen` *(`extra: Map`)* |
| `/admin/categories/complaints` | `adminCategoryComplaints` | `CategoryComplaintsScreen` *(`extra: {categoryName, complaints}`)* |
| `/admin/announcements/add` | `adminAnnouncementsAdd` | `AddAnnouncementScreen` |
| `/admin/announcements/edit` | `adminAnnouncementsEdit` | `EditAnnouncementScreen` *(`extra`)* |
| `/admin/announcements/detail` | `adminAnnouncementDetail` | `AdminAnnouncementDetailScreen` *(`extra`)* |
| `/admin/announcements/image` | `adminAnnouncementImage` | `AnnouncementImageViewerScreen` *(`extra: {imageUrl, title}`)* |
| `/admin/complaints/trash` | `adminComplaintsTrash` | `AdminTrashComplaintsScreen` |
| `/admin/complaints/resolve` | `adminComplaintsResolve` | `ResolveComplaintScreen` *(`extra`)* |
| `/admin/reports` | `adminReports` | `AdminReportsTab` |
| `/admin/users/detail` | `adminUserDetail` | `AdminUserDetailScreen` *(`extra: AdminUserDetailArgs`)* |
| `/admin/users/complaints` | `adminUserComplaints` | `AdminUserComplaintsScreen` *(`extra: AdminUserComplaintsArgs`)* |

> Route yang butuh data kompleks (object, map) memakai parameter `extra` pada `context.push()/go()` karena `go_router` hanya mendukung string di path/query params.

---

## 🎬 Transisi Halaman

Ada 3 pola transisi yang dipakai lewat `CustomTransitionPage`:

1. **Fade** — splash, landing, home, admin dashboard.
2. **Slide dari kanan** (`Offset(1,0) → 0`) — kebanyakan halaman user/profile/detail, dan **semua** halaman admin lewat helper `AppRouter._adminSlidePage()`.
3. **Slide dari bawah** (`Offset(0,1) → 0`) — halaman yang sifatnya modal/sheet-like: `createComplaint`, `faq`, `contact`, `forgotPassword`.

## ❌ Error Handling

Route yang tidak ditemukan ditangani oleh `errorBuilder` global → menampilkan halaman "Halaman tidak ditemukan" dengan tombol kembali ke `/landing`.

## ➕ Menambah Route Baru

1. Tambahkan konstanta path baru di `AppRouter` (mis. `static const String myNewPage = '/my-new-page';`).
2. Tambahkan `GoRoute` baru di list `routes:`, pilih `pageBuilder` dengan transisi yang sesuai (lihat 3 pola di atas, atau pakai `_adminSlidePage()` jika ini halaman admin).
3. Jika halaman butuh data non-string, kirim lewat `state.extra` dan navigasi dengan `context.push(AppRouter.myNewPage, extra: data)`.
4. Pastikan guard `redirect` tidak memblokir route baru (route protected otomatis ter-cover selama bukan termasuk `isAuthRoute`).
