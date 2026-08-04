# 🌐 Integrasi API (Backend Laravel)

Aplikasi ini adalah klien dari backend **MyPengaduan Laravel API**. Semua komunikasi HTTP memakai [`dio`](https://pub.dev/packages/dio), token disimpan dengan `flutter_secure_storage`.

> Lihat juga: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## ⚙️ Konfigurasi Dasar

Konfigurasi terpusat di [`lib/config/app_config.dart`](../lib/config/app_config.dart):

```dart
AppConfig.baseUrl            // default: https://mypengaduan.miftahaldi.my.id/api/
AppConfig.connectionTimeout  // 60 detik
AppConfig.receiveTimeout     // 60 detik
AppConfig.defaultPerPage     // 15 item per halaman (pagination)
```

Base URL bisa di-override saat development tanpa mengubah kode:

```bash
flutter run --dart-define=BASE_URL=http://192.168.1.100:8000/api/
```

Setiap *service* membuat instance `Dio` sendiri dengan `baseUrl` dari `AppConfig.baseUrl` dan header default `Accept: application/json`.

---

## 🔑 Autentikasi & Token

- Token disimpan di **Secure Storage** dengan key `AppConfig.tokenKey` (`auth_token`), bukan `shared_preferences`, karena bersifat sensitif.
- Data user (hasil login/profile) di-cache sebagai JSON string dengan key `AppConfig.userKey` agar bisa langsung dipakai saat splash tanpa perlu hit API (lihat `AuthProvider.checkAuthStatus()`).
- Setiap request yang butuh autentikasi mengirim header:
  ```dart
  Options(headers: {'Authorization': 'Bearer $token'})
  ```
- `AuthService` menangani **register** (multipart, termasuk upload foto KTP), **login**, **get/update profile** (multipart jika upload avatar), **delete avatar**, **forgot/verify-otp/reset password**, **change password**, **logout**, dan **logout-all** (logout dari semua device).
- File diunggah dengan `FormData` + `MultipartFile.fromFile()`. Khusus update profile dengan avatar, request dikirim via **POST** (bukan PUT) karena PHP hanya mengisi `$_FILES` pada POST — backend punya alias POST untuk endpoint ini.

---

## 📡 Daftar Endpoint per Service

### `AuthService` — prefix `auth/`
| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `auth/login` | Login |
| POST | `auth/register` | Register (multipart, foto KTP) |
| GET | `auth/profile` | Ambil profile |
| PUT / POST | `auth/profile` | Update profile (POST jika upload avatar) |
| DELETE | `auth/profile/avatar` | Hapus avatar |
| POST | `auth/forgot-password` | Kirim OTP reset password |
| POST | `auth/verify-otp` | Verifikasi OTP |
| POST | `auth/reset-password` | Set password baru |
| PUT | `auth/change-password` | Ganti password (saat login) |
| POST | `auth/logout` / `auth/logout-all` | Logout satu/semua sesi |

### `ComplaintService` — pengaduan milik user
CRUD pengaduan (list, detail, create, update, delete), termasuk endpoint pendukung filter & status. Lihat [`lib/services/complaint_service.dart`](../lib/services/complaint_service.dart) untuk detail.

Endpoint `GET public/complaints` dan `GET public/complaints/{id}` menampilkan
pengaduan dengan visibilitas **Publik** kepada seluruh pengguna yang sudah
login. Keduanya tetap wajib mengirim header `Authorization: Bearer <token>`;
kata “public” mengacu pada cakupan data antarwarga, bukan akses tanpa
autentikasi. Identitas pelapor tidak disertakan dalam respons endpoint ini.

### `AdminService` — prefix `admin/`
| Area | Endpoint |
|---|---|
| Dashboard | `admin/dashboard`, `admin/dashboard/quick-stats` |
| Pengaduan | `admin/complaints` (GET/POST/PUT), `admin/complaints/{id}` (GET/PUT/DELETE), `admin/complaints/{id}/status`, `admin/complaints/{id}/response`, `admin/complaints/{id}/restore`, `admin/complaints/{id}/force-delete`, `admin/complaints/bulk-update`, `admin/complaints/statistics`, `admin/complaints/attachments/{id}` |
| Kategori | `admin/categories` (GET/POST), `admin/categories/{id}` (GET/PUT/DELETE), `admin/categories/active`, `admin/categories/{id}/toggle-status` |
| Pengumuman | `admin/announcements` (GET/POST), `admin/announcements/{id}` (GET/PUT/DELETE), `admin/announcements/{id}/publish`, `/unpublish`, `/toggle-status`, `/toggle-sticky` |
| User | `admin/users` (GET), `admin/users/{id}` (GET/DELETE), `admin/users/{id}/verify-user`, `/reject-verification`, `/verify-email`, `/unverify-email`, `/change-role`, `/reset-password` |
| Laporan | `admin/reports/overview` |

### `AnnouncementService` — pengumuman publik
`announcements/urgent`, `announcements/bookmarked`, `announcements/{idOrSlug}`, `announcements/{id}/bookmark`, `announcements/{id}/comments`.

### `NotificationService`
`device-tokens` (GET, untuk daftar token FCM terdaftar), `device-tokens/{id}` (DELETE), `notification-settings` (GET/PUT).

### `ReportsService`
Statistik & export laporan (PDF via `pdf`, Excel via `excel`) — diorkestrasi oleh `ReportsProvider`, dipakai di tab **Laporan & Statistik** admin.

---

## 📦 Format Response Standar

Backend mengembalikan format konsisten yang dimodelkan oleh [`ApiResponse`](../lib/models/api_response.dart) dan [`AuthResponse`](../lib/models/auth_response.dart):

```json
{
  "success": true,
  "message": "...",
  "data": { /* object atau array */ }
}
```

Saat error (`DioException` dengan response dari server), service akan tetap mem-parsing body error tersebut ke model yang sama (bukan generic exception), supaya UI bisa menampilkan `message` dari backend. Hanya error tanpa response (mis. tidak ada koneksi internet) yang dilempar sebagai `Exception('Network error: ...')`.

---

## ➕ Menambah Endpoint Baru

1. Tambahkan method baru di service yang relevan (atau buat service baru jika domainnya baru), ikuti pola try/catch `DioException` yang sudah ada di file lain agar konsisten.
2. Tambahkan method di provider terkait yang memanggil service tersebut dan mengatur `isLoading` / `notifyListeners()`.
3. Panggil method provider dari screen via `Provider.of<XProvider>(context, listen: false).methodBaru()`.
4. Jika endpoint butuh model data baru, tambahkan class di `lib/models/` dengan `fromJson`/`toJson`.
