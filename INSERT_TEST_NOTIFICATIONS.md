# 🧪 Insert Test Notifications

## 📊 Problem: Data Kosong

Backend merespons dengan sukses tapi `data: []` (array kosong).

**Artinya: Tidak ada notifikasi di database untuk user yang login!**

---

## ✅ Solusi: Insert Test Data

### 1️⃣ Cek User ID yang Login

Jalankan app dan lihat log console:
```
👤 [NotificationService] Current user: ID=123, Name=John Doe, Role=user
```

**Catat ID user tersebut!** (misal: ID=5)

---

### 2️⃣ Insert Notifikasi Manual via Database

Buka database MySQL/PostgreSQL dan jalankan:

```sql
-- Ganti 5 dengan ID user yang login di app
INSERT INTO fcm_notifications (
    user_id, 
    type, 
    title, 
    body, 
    data, 
    is_read, 
    created_at, 
    updated_at
) VALUES 
-- Notification 1: Test Notification
(5, 'system', 'Test Notifikasi', 'Ini adalah notifikasi test untuk memastikan fitur berfungsi', NULL, 0, NOW(), NOW()),

-- Notification 2: Complaint Created
(5, 'complaint_created', 'Pengaduan Baru', 'Pengaduan baru telah dibuat dan sedang diproses', '{"complaint_id": 1}', 0, NOW(), NOW()),

-- Notification 3: Status Update
(5, 'complaint_status_changed', 'Status Pengaduan Diperbarui', 'Pengaduan Anda telah diperbarui menjadi: Sedang Diproses', '{"complaint_id": 1, "status": "processing"}', 0, NOW(), NOW()),

-- Notification 4: Admin Response
(5, 'admin_response', 'Admin Menanggapi', 'Admin telah memberikan tanggapan pada pengaduan Anda', '{"complaint_id": 1, "comment_id": 10}', 1, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),

-- Notification 5: Announcement
(5, 'announcement_created', 'Pengumuman Baru', 'Ada pengumuman penting dari sistem', '{"announcement_id": 5}', 0, NOW(), NOW());
```

---

### 3️⃣ Insert via Laravel Tinker

Alternatif: Gunakan Laravel Tinker

```bash
php artisan tinker
```

```php
use App\Models\FcmNotification;
use App\Models\User;

// Ganti dengan email user yang login di app
$user = User::where('email', 'user@example.com')->first();

// Atau langsung pakai ID
$userId = 5; // Ganti dengan ID user

// Insert test notifications
FcmNotification::create([
    'user_id' => $userId,
    'type' => 'system',
    'title' => 'Test Notifikasi',
    'body' => 'Ini adalah notifikasi test',
    'data' => null,
    'is_read' => false,
]);

FcmNotification::create([
    'user_id' => $userId,
    'type' => 'complaint_status_changed',
    'title' => 'Status Pengaduan Diperbarui',
    'body' => 'Pengaduan Anda telah diperbarui',
    'data' => ['complaint_id' => 1, 'status' => 'processing'],
    'is_read' => false,
]);

FcmNotification::create([
    'user_id' => $userId,
    'type' => 'admin_response',
    'title' => 'Admin Menanggapi',
    'body' => 'Admin memberikan tanggapan',
    'data' => ['complaint_id' => 1],
    'is_read' => false,
]);

echo "✅ 3 notifications inserted for user ID: $userId\n";
```

---

### 4️⃣ Verifikasi Data Berhasil

Cek database:
```sql
-- Cek notifikasi untuk user tertentu
SELECT * FROM fcm_notifications WHERE user_id = 5 ORDER BY created_at DESC;

-- Cek total notifikasi
SELECT COUNT(*) as total FROM fcm_notifications WHERE user_id = 5;

-- Cek unread count
SELECT COUNT(*) as unread FROM fcm_notifications WHERE user_id = 5 AND is_read = 0;
```

---

### 5️⃣ Test di Flutter App

1. **Restart app** atau **pull to refresh** di notification screen
2. **Lihat log console** - seharusnya:
   ```
   ✅ [NotificationProvider] Received 3 notifications
   📊 Metadata: currentPage=1, total=3
   🔔 Unread count: 3
   ```
3. **Notifikasi muncul di screen!** 🎉

---

## 🎯 Automatic: Create Notifications from Backend Events

Setelah test manual berhasil, tambahkan auto-create di backend events:

### Saat Complaint Created:
```php
// Di ComplaintController@store
FcmNotification::create([
    'user_id' => $complaint->user_id,
    'type' => 'complaint_created',
    'title' => 'Pengaduan Dibuat',
    'body' => "Pengaduan Anda '{$complaint->title}' telah dibuat",
    'data' => ['complaint_id' => $complaint->id],
    'is_read' => false,
]);
```

### Saat Status Changed:
```php
// Di ComplaintController@updateStatus
FcmNotification::create([
    'user_id' => $complaint->user_id,
    'type' => 'complaint_status_changed',
    'title' => 'Status Diperbarui',
    'body' => "Status pengaduan: {$newStatus}",
    'data' => ['complaint_id' => $complaint->id, 'status' => $newStatus],
    'is_read' => false,
]);
```

### Saat Admin Reply:
```php
// Di CommentController@store
FcmNotification::create([
    'user_id' => $complaint->user_id,
    'type' => 'admin_response',
    'title' => 'Admin Menanggapi',
    'body' => 'Admin memberikan tanggapan',
    'data' => ['complaint_id' => $complaint->id, 'comment_id' => $comment->id],
    'is_read' => false,
]);
```

---

## 🐛 Troubleshooting

### Masih Kosong Setelah Insert?

1. **Cek user_id benar:**
   - Log di app: `ID=5`
   - Database: `WHERE user_id = 5`
   - Harus match!

2. **Cek table name:**
   ```sql
   SHOW TABLES LIKE '%notification%';
   -- Pastikan table 'fcm_notifications' ada
   ```

3. **Cek struktur table:**
   ```sql
   DESCRIBE fcm_notifications;
   ```

4. **Cek data benar-benar ada:**
   ```sql
   SELECT * FROM fcm_notifications LIMIT 10;
   ```

---

## ✅ Expected Result

Setelah insert data, app akan menampilkan notifikasi seperti ini:

```
🔔 Notifikasi (3)

📱 Test Notifikasi
   Ini adalah notifikasi test
   🕐 Baru saja

📋 Status Pengaduan Diperbarui  
   Pengaduan Anda telah diperbarui
   🕐 Baru saja

💬 Admin Menanggapi
   Admin memberikan tanggapan
   🕐 Baru saja
```

Selamat mencoba! 🚀
