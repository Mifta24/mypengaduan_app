# Firebase Cloud Messaging (FCM) Integration Guide

## ✅ Status Implementasi

Firebase Cloud Messaging sudah **FULLY IMPLEMENTED** dan siap digunakan!

## 🎯 Fitur yang Sudah Tersedia

### 1. **FCM Service** ([fcm_service.dart](lib/services/fcm_service.dart))
- ✅ Inisialisasi otomatis saat app startup
- ✅ Request notification permission
- ✅ Get & register FCM token ke backend
- ✅ Handle foreground messages (show local notification)
- ✅ Handle background messages
- ✅ Handle notification tap (navigasi otomatis)
- ✅ Token refresh handling
- ✅ Topic subscription support

### 2. **Notification Service** ([notification_service.dart](lib/services/notification_service.dart))
- ✅ `POST /device-tokens` - Register FCM token
- ✅ `GET /notifications` - List notifikasi
- ✅ `POST /notifications/{id}/read` - Mark as read
- ✅ `POST /notifications/read-all` - Mark all as read

### 3. **Background Message Handler** ([main.dart](lib/main.dart))
- ✅ Top-level background handler terdaftar
- ✅ Handle notification saat app terminated

### 4. **Navigation dari Notification**
- ✅ Tap notification → auto navigate ke halaman terkait
- ✅ Support untuk berbagai tipe notifikasi:
  - `complaint_created` → Detail complaint
  - `complaint_updated` → Detail complaint
  - `complaint_status_changed` → Detail complaint
  - `comment_added` → Detail complaint
  - `announcement_created` → Announcements list
  - Default → Notifications list

---

## 🚀 Cara Testing

### **1. Test pada Real Device (Recommended)**

FCM hanya bekerja pada **real device** (tidak bekerja di emulator).

#### Setup:
```bash
# Build dan install ke device
flutter run --release
```

#### Get FCM Token:
Saat app pertama kali dibuka, FCM token akan:
1. Otomatis di-generate
2. Disimpan ke local storage
3. Dikirim ke backend API `/device-tokens`
4. Log di console: `FCM Token: [your-token]`

#### Test Notification dari Backend:
Backend Anda dapat mengirim push notification menggunakan Firebase Admin SDK:

```javascript
// Example using Node.js Firebase Admin SDK
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./path-to-serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification
const message = {
  notification: {
    title: 'Pengaduan Baru',
    body: 'Ada pengaduan baru di RT 001',
  },
  data: {
    type: 'complaint_created',
    complaint_id: '123',
  },
  token: 'USER_FCM_TOKEN_FROM_DATABASE'
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.log('Error sending message:', error);
  });
```

### **2. Test menggunakan Firebase Console**

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project: **mypengaduan**
3. Menu **Cloud Messaging**
4. Klik **Send your first message**
5. Isi form:
   - **Notification title**: Test Notifikasi
   - **Notification text**: Ini adalah test push notification
6. Klik **Next** → **Test on device**
7. Masukkan FCM token (dari log app)
8. Klik **Test**

### **3. Test dengan Postman/cURL**

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "Hello from Postman!"
    },
    "data": {
      "type": "complaint_created",
      "complaint_id": "123"
    }
  }'
```

**Note:** Server Key ada di Firebase Console → Project Settings → Cloud Messaging → Server key

---

## 📱 Notification Scenarios

### **Scenario 1: App di Foreground**
- ✅ Local notification muncul di top
- ✅ User tap → navigate ke halaman terkait

### **Scenario 2: App di Background**
- ✅ System notification muncul
- ✅ User tap → app terbuka → navigate ke halaman terkait

### **Scenario 3: App Terminated**
- ✅ System notification muncul
- ✅ User tap → app launch → navigate ke halaman terkait

---

## 🔧 Backend API Requirements

### **Register Device Token**

```http
POST /api/device-tokens
Authorization: Bearer {token}
Content-Type: application/json

{
  "device_token": "FCM_TOKEN_HERE",
  "device_type": "android",
  "device_name": "Mobile Device",
  "app_version": "1.0.0"
}
```

### **Send Notification from Backend**

Backend harus menyimpan FCM token user dan mengirim push notification dengan format:

```json
{
  "notification": {
    "title": "Judul Notifikasi",
    "body": "Isi pesan notifikasi"
  },
  "data": {
    "type": "complaint_created",
    "complaint_id": "123",
    "other_data": "value"
  },
  "token": "USER_FCM_TOKEN"
}
```

**Tipe Notifikasi yang Didukung:**
- `complaint_created` - Pengaduan baru dibuat
- `complaint_updated` - Pengaduan diupdate
- `complaint_status_changed` - Status pengaduan berubah
- `comment_added` - Komentar baru pada pengaduan
- `announcement_created` - Pengumuman baru

---

## 🔐 Security

1. **FCM Token disimpan dengan aman** menggunakan `shared_preferences`
2. **Token dikirim ke backend dengan Bearer authentication**
3. **Notification permission diminta sesuai platform guidelines**

---

## 🐛 Troubleshooting

### FCM Token tidak muncul?
- Pastikan Firebase sudah diinisialisasi
- Cek `google-services.json` sudah benar
- Test pada **real device** (bukan emulator)
- Cek permission notification sudah granted

### Notification tidak muncul?
- Cek notification permission (Settings → Apps → MyPengaduan → Notifications)
- Pastikan backend mengirim format yang benar
- Cek log untuk error messages
- Test dengan Firebase Console terlebih dahulu

### Navigation tidak bekerja?
- Pastikan `type` dan data terkait (e.g., `complaint_id`) dikirim di payload
- Cek log untuk navigation errors
- Delay 500ms sudah cukup untuk app loading

---

## 📝 Next Steps

Jika backend sudah support Firebase Admin SDK:

1. ✅ Register FCM token saat user login
2. ✅ Simpan token di database (table: device_tokens)
3. ✅ Send notification saat event terjadi:
   - Pengaduan baru dibuat
   - Status pengaduan berubah
   - Komentar baru ditambahkan
   - Pengumuman baru dari admin
4. ✅ Handle token refresh/update
5. ✅ Delete token saat user logout

---

## ✨ Features

- 🔔 Real-time push notifications
- 📱 Local notifications untuk foreground messages
- 🚀 Auto navigation ke halaman terkait
- 🔄 Token auto-refresh handling
- 📊 Topic subscription support (for broadcasting)
- 💾 Token persistence across app restarts

**Status: READY FOR PRODUCTION** 🎉
