# 🧪 Test Notification API

## 🔍 Kemungkinan Masalah

Dari log error, ada **TIMEOUT** yang artinya:
1. ❌ Backend tidak merespons dalam 60 detik
2. ❌ Endpoint mungkin tidak ada atau salah
3. ❌ Backend sedang down/error

---

## ✅ Langkah Testing

### 1️⃣ Cek Endpoint di Browser/Postman

**Test URL:**
```
https://mypengaduan.miftahaldi.my.id/api/notifications?page=1&per_page=15
```

**Headers yang dibutuhkan:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Accept: application/json
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Notifications loaded successfully",
  "data": {
    "current_page": 1,
    "data": [...],
    "per_page": 15,
    "total": 10
  },
  "unread_count": 5
}
```

---

### 2️⃣ Cara Mendapat Token dari App

Tambahkan log di `auth_service.dart`:

```dart
Future<String?> getToken() async {
  final token = await _storage.read(key: AppConfig.tokenKey);
  print('🔑 Current Token: $token');
  return token;
}
```

Atau cek di secure storage via debug:
- Run app
- Login
- Lihat log untuk token
- Copy token

---

### 3️⃣ Test dengan cURL

```bash
# Ganti YOUR_TOKEN dengan token dari app
curl -X GET "https://mypengaduan.miftahaldi.my.id/api/notifications?page=1&per_page=15" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -v
```

**Cek response:**
- ✅ Status 200 = OK
- ❌ Status 404 = Endpoint tidak ada
- ❌ Status 401 = Token invalid/expired
- ❌ Status 500 = Server error
- ❌ Timeout = Server tidak merespons

---

## 🔧 Solusi Berdasarkan Error

### Jika 404 (Not Found):
**Endpoint belum ada di backend!** Pastikan routes ada:

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::post('notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('notifications/read-all', [NotificationController::class, 'markAllAsRead']);
});
```

### Jika 401 (Unauthorized):
Token expired atau invalid. Coba:
1. Logout dari app
2. Login lagi
3. Coba lagi

### Jika 500 (Server Error):
Cek Laravel logs:
```bash
tail -f storage/logs/laravel.log
```

### Jika Timeout:
1. **Server lambat** - Cek performa database query
2. **Server down** - Restart server
3. **Network issue** - Cek koneksi

---

## 🚀 Quick Fix: Manual Test Data

Jika endpoint belum ready, tambahkan dummy data untuk testing UI:

```dart
// Di notification_provider.dart - temporary test
Future<void> loadNotifications({...}) async {
  // TEMPORARY: Return dummy data for UI testing
  _notifications = [
    NotificationModel(
      id: 1,
      type: 'complaint_created',
      title: 'Test Notification',
      body: 'This is a test notification',
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  _unreadCount = 1;
  _isLoading = false;
  notifyListeners();
  return;
  
  // ... rest of actual code
}
```

---

## 📊 Check Backend Database

```sql
-- Check if notifications table exists
SHOW TABLES LIKE 'fcm_notifications';

-- Check data
SELECT * FROM fcm_notifications ORDER BY created_at DESC LIMIT 10;

-- Check for specific user
SELECT * FROM fcm_notifications WHERE user_id = YOUR_USER_ID;

-- Check total count
SELECT COUNT(*) FROM fcm_notifications;
```

---

## 🎯 Next Steps

1. ✅ Test endpoint dengan cURL/Postman
2. ✅ Verify token valid
3. ✅ Check backend logs
4. ✅ Verify routes di `api.php`
5. ✅ Check database has data

**Share hasil test untuk diagnosis lebih lanjut!**
