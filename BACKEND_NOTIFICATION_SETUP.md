# 🔔 Backend Notification Setup Guide

## ✅ STATUS: Backend Notification API Sudah Siap!

Backend Laravel sudah memiliki implementasi lengkap untuk notifikasi. Berikut adalah dokumentasi API yang tersedia:

---

## 📋 API Endpoints yang Tersedia

### 1️⃣ Get Notifications (Pagination)
```
GET /api/notifications
```

**Query Parameters:**
- `page` - Nomor halaman (default: 1)
- `per_page` - Item per halaman (default: 15)
- `status` - Filter: 'read' atau 'unread'
- `type` - Filter by notification type

**Response:**
```json
{
  "success": true,
  "message": "Notifications loaded successfully",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "type": "complaint_created",
        "title": "Pengaduan Baru",
        "body": "Pengaduan baru dari User",
        "data": {
          "complaint_id": 45,
          "user_id": 10
        },
        "is_read": false,
        "read_at": null,
        "created_at": "2026-02-03T10:30:00.000000Z",
        "updated_at": "2026-02-03T10:30:00.000000Z"
      }
    ],
    "per_page": 15,
    "total": 50,
    "last_page": 4
  },
  "unread_count": 10
}
```

### 2️⃣ Mark Notification as Read
```
POST /api/notifications/{id}/read
```

**Response:**
```json
{
  "success": true,
  "message": "Notification marked as read",
  "data": {
    "id": 1,
    "is_read": true,
    "read_at": "2026-02-03T10:35:00.000000Z"
  }
}
```

### 3️⃣ Mark All Notifications as Read
```
POST /api/notifications/read-all
```

**Response:**
```json
{
  "success": true,
  "message": "All notifications marked as read",
  "data": null
}
```

### 4️⃣ Get Notification Settings
```
GET /api/notification-settings
```

**Response:**
```json
{
  "success": true,
  "message": "Notification settings loaded successfully",
  "data": {
    "id": 1,
    "user_id": 123,
    "complaint_created": true,
    "complaint_status_changed": true,
    "announcement_created": true,
    "admin_response": true,
    "comment_added": true,
    "push_enabled": true
  }
}
```

### 5️⃣ Update Notification Settings
```
PUT /api/notification-settings
```

**Request Body:**
```json
{
  "complaint_created": true,
  "complaint_status_changed": true,
  "announcement_created": true,
  "admin_response": true,
  "comment_added": true,
  "push_enabled": true
}
```

---

## 1️⃣ Device Token Endpoint (SUDAH ADA)

**Endpoint yang dibutuhkan Flutter:**
```
POST /api/device-tokens
```

**Request Body:**
```json
{
  "device_token": "FCM_TOKEN_STRING",
  "device_type": "android",
  "device_name": "Mobile Device",
  "app_version": "1.0.0"
}
```

**Response Expected:**
```json
{
  "success": true,
  "message": "Device token registered successfully",
  "data": {
    "id": 1,
    "user_id": 123,
    "device_token": "FCM_TOKEN_STRING",
    "device_type": "android"
  }
}
```

### 📝 Backend Controller Example:

```php
// app/Http/Controllers/Api/DeviceTokenController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeviceToken;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DeviceTokenController extends Controller
{
    use ApiResponse;

    public function store(Request $request)
    {
        $request->validate([
            'device_token' => 'required|string',
            'device_type' => 'required|in:android,ios,web',
            'device_name' => 'nullable|string',
            'app_version' => 'nullable|string',
        ]);

        try {
            $user = Auth::user();

            // Update or create device token
            $deviceToken = DeviceToken::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'device_token' => $request->device_token,
                ],
                [
                    'device_type' => $request->device_type,
                    'device_name' => $request->device_name,
                    'app_version' => $request->app_version,
                    'is_active' => true,
                    'last_used_at' => now(),
                ]
            );

            return $this->success($deviceToken, 'Device token registered successfully');

        } catch (\Exception $e) {
            return $this->serverError('Failed to register device token', $e);
        }
    }
}
```

### 📝 Migration:

```php
// database/migrations/xxxx_create_device_tokens_table.php
Schema::create('device_tokens', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('device_token')->unique();
    $table->enum('device_type', ['android', 'ios', 'web']);
    $table->string('device_name')->nullable();
    $table->string('app_version')->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamp('last_used_at')->nullable();
    $table->timestamps();
});
```

### 📝 Routes:

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/device-tokens', [DeviceTokenController::class, 'store']);
});
```

---

---

## 📱 Backend Controller Implementation

### NotificationController.php (Sudah Ada)

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FcmNotification;
use App\Models\NotificationSetting;
use App\Traits\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    use ApiResponse;

    /**
     * Get User Notifications
     * GET /api/notifications
     */
    public function index(Request $request)
    {
        try {
            $user = Auth::user();
            $query = FcmNotification::where('user_id', $user->id);

            // Filter by read status
            if ($request->has('status')) {
                if ($request->status === 'unread') {
                    $query->unread();
                } elseif ($request->status === 'read') {
                    $query->read();
                }
            }

            // Filter by type
            if ($request->filled('type')) {
                $query->where('type', $request->type);
            }

            $notifications = $query->orderBy('created_at', 'desc')
                ->paginate($request->get('per_page', 15));

            // Transform notifications for Android
            $notifications->getCollection()->transform(function ($notification) {
                return [
                    'id' => $notification->id,
                    'type' => $notification->type,
                    'title' => $notification->title,
                    'body' => $notification->body,
                    'data' => $notification->data,
                    'is_read' => $notification->is_read,
                    'read_at' => $notification->read_at ? $notification->read_at->format('Y-m-d\TH:i:s.u\Z') : null,
                    'created_at' => $notification->created_at->format('Y-m-d\TH:i:s.u\Z'),
                    'updated_at' => $notification->updated_at->format('Y-m-d\TH:i:s.u\Z'),
                ];
            });

            // Get unread count
            $unreadCount = FcmNotification::where('user_id', $user->id)
                ->unread()
                ->count();

            return $this->successWithPagination(
                $notifications,
                'Notifications loaded successfully',
                [],
                200,
                ['unread_count' => $unreadCount]
            );

        } catch (\Exception $e) {
            return $this->serverError('Failed to load notifications', $e);
        }
    }

    /**
     * Mark notification as read
     * POST /api/notifications/{id}/read
     */
    public function markAsRead($id)
    {
        try {
            $notification = FcmNotification::where('user_id', Auth::id())
                ->where('id', $id)
                ->first();

            if (!$notification) {
                return $this->notFound('Notification not found');
            }

            $notification->markAsRead();

            $data = [
                'id' => $notification->id,
                'is_read' => $notification->is_read,
                'read_at' => $notification->read_at->format('Y-m-d\TH:i:s.u\Z'),
            ];

            return $this->success($data, 'Notification marked as read');

        } catch (\Exception $e) {
            return $this->serverError('Failed to mark notification as read', $e);
        }
    }

    /**
     * Mark all notifications as read
     * POST /api/notifications/read-all
     */
    public function markAllAsRead()
    {
        try {
            FcmNotification::where('user_id', Auth::id())
                ->unread()
                ->update([
                    'is_read' => true,
                    'read_at' => now(),
                ]);

            return $this->success(null, 'All notifications marked as read');

        } catch (\Exception $e) {
            return $this->serverError('Failed to mark all notifications as read', $e);
        }
    }

    /**
     * Get notification settings
     * GET /api/notification-settings
     */
    public function getSettings()
    {
        $settings = Auth::user()->notificationSettings;

        if (!$settings) {
            $settings = NotificationSetting::create([
                'user_id' => Auth::id(),
                'complaint_created' => true,
                'complaint_status_changed' => true,
                'announcement_created' => true,
                'admin_response' => true,
                'comment_added' => true,
                'push_enabled' => true,
            ]);
        }

        return $this->success($settings, 'Notification settings loaded successfully');
    }

    /**
     * Update notification settings
     * PUT /api/notification-settings
     */
    public function updateSettings(Request $request)
    {
        $request->validate([
            'complaint_created' => 'boolean',
            'complaint_status_changed' => 'boolean',
            'announcement_created' => 'boolean',
            'admin_response' => 'boolean',
            'comment_added' => 'boolean',
            'push_enabled' => 'boolean',
        ]);

        $settings = Auth::user()->notificationSettings;

        if (!$settings) {
            $settings = new NotificationSetting(['user_id' => Auth::id()]);
        }

        $settings->fill($request->all());
        $settings->save();

        return $this->success($settings, 'Notification settings updated successfully');
    }
}
```

### Routes (api.php) - Sudah Ada

```php
Route::middleware('auth:sanctum')->group(function () {
    // Notification routes
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::post('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/read-all', [NotificationController::class, 'markAllAsRead']);
    });

    // Notification Settings routes
    Route::prefix('notification-settings')->group(function () {
        Route::get('/', [NotificationController::class, 'getSettings']);
        Route::put('/', [NotificationController::class, 'updateSettings']);
    });
});
```

---

## 2️⃣ FcmNotification Model (Sudah Ada)

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FcmNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'body',
        'data',
        'is_read',
        'read_at',
    ];

    protected $casts = [
        'data' => 'array',
        'is_read' => 'boolean',
        'read_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function markAsRead()
    {
        $this->update([
            'is_read' => true,
            'read_at' => now(),
        ]);
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public function scopeRead($query)
    {
        return $query->where('is_read', true);
    }
}
```

---

## 3️⃣ Cara Mengirim Notifikasi ke User

### Saat Complaint Status Changed

```php
// Di ComplaintController atau Service
public function updateStatus($complaintId, $newStatus)
{
    $complaint = Complaint::findOrFail($complaintId);
    $complaint->update(['status' => $newStatus]);

    // Kirim notifikasi ke user yang buat complaint
    FcmNotification::create([
        'user_id' => $complaint->user_id,
        'type' => 'complaint_status_changed',
        'title' => 'Status Pengaduan Diperbarui',
        'body' => "Pengaduan Anda '{$complaint->title}' sekarang berstatus: {$newStatus}",
        'data' => [
            'complaint_id' => $complaint->id,
            'status' => $newStatus,
        ],
        'is_read' => false,
    ]);

    // Opsional: Kirim FCM push notification real-time
    // $this->sendFcmPushNotification($complaint->user_id, ...);
}
```

### Saat Admin Reply Complaint

```php
// Di CommentController atau ReplyController
public function storeReply(Request $request, $complaintId)
{
    $complaint = Complaint::findOrFail($complaintId);
    
    $comment = Comment::create([
        'complaint_id' => $complaintId,
        'user_id' => Auth::id(),
        'comment' => $request->comment,
    ]);

    // Notifikasi ke pembuat complaint
    FcmNotification::create([
        'user_id' => $complaint->user_id,
        'type' => 'admin_response',
        'title' => 'Admin Menanggapi Pengaduan',
        'body' => "Admin memberikan tanggapan pada pengaduan '{$complaint->title}'",
        'data' => [
            'complaint_id' => $complaint->id,
            'comment_id' => $comment->id,
        ],
        'is_read' => false,
    ]);

    return $this->success($comment, 'Reply sent successfully');
}
```

### Saat Announcement Created

```php
// Di AnnouncementController
public function store(Request $request)
{
    $announcement = Announcement::create($request->validated());

    // Kirim notifikasi ke semua user
    $users = User::where('role', 'user')->get();
    
    foreach ($users as $user) {
        FcmNotification::create([
            'user_id' => $user->id,
            'type' => 'announcement_created',
            'title' => 'Pengumuman Baru',
            'body' => $announcement->title,
            'data' => [
                'announcement_id' => $announcement->id,
            ],
            'is_read' => false,
        ]);
    }

    return $this->success($announcement, 'Announcement created');
}
```

---

---

## ✅ Testing API Endpoints

### 1. Get Notifications
```bash
curl -X GET "http://your-backend.test/api/notifications?page=1&per_page=15" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### 2. Mark as Read
```bash
curl -X POST "http://your-backend.test/api/notifications/1/read" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### 3. Mark All as Read
```bash
curl -X POST "http://your-backend.test/api/notifications/read-all" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### 4. Get Notification Settings
```bash
curl -X GET "http://your-backend.test/api/notification-settings" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### 5. Update Notification Settings
```bash
curl -X PUT "http://your-backend.test/api/notification-settings" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "complaint_created": true,
    "complaint_status_changed": true,
    "announcement_created": true,
    "admin_response": true,
    "comment_added": true,
    "push_enabled": true
  }'
```

---

## 📲 Flutter App Integration (Sudah Ada)

Flutter app Anda sudah memiliki implementasi lengkap untuk notifikasi:

### Files yang Sudah Ada:
- ✅ `lib/models/notification_model.dart` - Model notifikasi
- ✅ `lib/services/notification_service.dart` - Service untuk API calls
- ✅ `lib/providers/notification_provider.dart` - State management
- ✅ `lib/screens/notifications/notification_list_screen.dart` - UI notifikasi
- ✅ `lib/services/fcm_service.dart` - Firebase Cloud Messaging

### Fitur yang Sudah Diimplementasi:
- ✅ Load notifications dengan pagination
- ✅ Mark notification sebagai read
- ✅ Mark all notifications sebagai read
- ✅ Unread count badge
- ✅ Pull to refresh
- ✅ Filter by status (read/unread)
- ✅ FCM token registration
- ✅ Push notification handling

---

## 🔔 Cara Kerja Notifikasi

### 1. User Login
```
Flutter App → Backend: Login
Backend → Flutter: Token + User Data
Flutter → Backend: Register FCM Token (POST /api/device-tokens)
```

### 2. Event Terjadi (Contoh: Complaint Status Changed)
```
Admin Update Status → Backend
Backend: Insert ke table fcm_notifications
Backend (Optional): Kirim FCM Push Real-time
```

### 3. User Buka Notifikasi Screen
```
Flutter → Backend: GET /api/notifications
Backend → Flutter: List Notifications
Flutter: Display notifications
```

### 4. User Tap Notification
```
User Tap → Flutter: Mark as Read (POST /api/notifications/{id}/read)
Backend: Update is_read = true
Flutter: Navigate to detail screen
```

---

## 🚀 Next Steps

### 1. Pastikan Table fcm_notifications Ada
```sql
CREATE TABLE fcm_notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    type VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    data JSON NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 2. Test Insert Notification Manual
```php
// Di tinker atau test controller
use App\Models\FcmNotification;

FcmNotification::create([
    'user_id' => 1, // ID user yang akan menerima
    'type' => 'test',
    'title' => 'Test Notification',
    'body' => 'This is a test notification',
    'data' => ['test_key' => 'test_value'],
    'is_read' => false,
]);
```

### 3. Cek di Flutter App
```
1. Buka app
2. Login sebagai user dengan ID yang sama
3. Buka Notification screen
4. Notifikasi test harus muncul
```

---

## 🎯 Kesimpulan

**Backend Anda sudah lengkap!** Yang perlu dilakukan:

1. ✅ **API Endpoints sudah ada** - NotificationController sudah implement semua endpoint
2. ✅ **Model sudah ada** - FcmNotification model dengan scopes
3. ✅ **Routes sudah ada** - `/api/notifications/*` endpoints
4. ✅ **Flutter app sudah siap** - Service, Provider, UI sudah ada

**Tinggal pastikan:**
- 🔲 Table `fcm_notifications` sudah ada di database
- 🔲 Data notifikasi sudah masuk ke table
- 🔲 Flutter app bisa hit endpoint dengan bearer token yang valid

**Test sekarang:**
```bash
# 1. Insert notification manual via tinker
php artisan tinker
> FcmNotification::create(['user_id' => 1, 'type' => 'test', 'title' => 'Test', 'body' => 'Body', 'is_read' => false]);

# 2. Test API endpoint
curl -X GET "http://localhost:8000/api/notifications" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 3. Buka app Flutter → Notification screen
```

Jika masih ada masalah, share screenshot error atau response dari API! 🚀
