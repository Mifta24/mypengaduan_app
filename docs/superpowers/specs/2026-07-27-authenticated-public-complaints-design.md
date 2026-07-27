# Authenticated Public Complaints

## Goal

Pengaduan berjenis Publik dapat dilihat oleh seluruh pengguna yang sudah
berhasil login. Pengaduan berjenis Privat tetap hanya dapat dilihat oleh
pelapor dan admin. Pengunjung yang belum login tidak dapat membuka daftar atau
detail pengaduan.

## Access Rules

| Actor | Public complaint | Private complaint |
|---|---|---|
| Guest | No access | No access |
| Authenticated user | List and read-only detail | No access unless owner |
| Complaint owner | List and detail | List and detail |
| Admin | Full access | Full access |

Akun yang berhasil login boleh membaca pengaduan Publik meskipun status
verifikasi KTP-nya belum selesai. Verifikasi KTP tetap diperlukan untuk
membuat pengaduan dan tidak digunakan sebagai syarat membaca.

## Flutter Changes

- Hapus tombol **Lihat Pengaduan Publik** dari halaman landing sebelum login.
- Jadikan route daftar dan detail pengaduan publik sebagai protected route.
- Pertahankan akses setelah login melalui
  **Beranda → Aksi Cepat → Pengaduan Publik**.
- Request daftar dan detail publik mengirim token autentikasi.
- Jika sesi tidak valid, router mengarahkan pengguna ke halaman landing/login
  melalui mekanisme autentikasi aplikasi yang sudah ada.

## Backend Changes

- Pindahkan route `GET /api/public/complaints` dan
  `GET /api/public/complaints/{id}` ke middleware `auth:sanctum`.
- Endpoint tetap hanya mengembalikan record dengan
  `visibility = public`.
- Payload tetap tidak menyertakan identitas pelapor seperti `user_id`, nama,
  email, NIK, nomor telepon, dan alamat akun.
- Detail pengaduan Privat melalui endpoint tersebut tetap menghasilkan 404.
- Endpoint pemilik dan admin tidak berubah.

Nama endpoint dipertahankan agar perubahan deployment kecil dan aplikasi lama
yang sudah login tetap kompatibel.

## Error Handling

- Tanpa token atau token kedaluwarsa: backend mengembalikan 401.
- Pengaduan Privat atau ID yang tidak tersedia: backend mengembalikan 404.
- Flutter menampilkan pesan gagal memuat jika request ditolak, tanpa
  memperlihatkan data cache pengaduan kepada guest.

## Verification

- Test backend membuktikan guest menerima 401 untuk daftar dan detail.
- Test backend membuktikan pengguna terautentikasi dapat membaca pengaduan
  Publik.
- Test backend membuktikan pengaduan Privat tidak tersedia melalui endpoint
  publik.
- Test Flutter/model yang ada tetap lulus.
- `dart analyze lib` tidak menghasilkan error baru.

## Deployment

Perubahan ini tidak menambah migration database baru. Setelah pull backend,
jalankan `php artisan optimize:clear` agar cache route lama tidak dipakai.
