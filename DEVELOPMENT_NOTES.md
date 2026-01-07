# Development Notes - MyPengaduan Flutter App

## 📋 Project Status

✅ **Completed:**
- Project structure setup
- All dependencies installed
- Models created (User, Auth, Notification, Complaint)
- Services implemented (Auth, Notification, Complaint, FCM)
- Providers implemented (Auth, Complaint)
- UI Screens created (Login, Register, Home, Dashboard, Notifications, Complaints)
- Firebase configuration template
- Main app integration

---

## 🎯 Current Implementation

### ✅ Phase 1: Core Features (COMPLETED)

1. **Authentication System**
   - Login screen dengan form validation
   - Register screen dengan complete fields
   - Secure token storage (flutter_secure_storage)
   - Auto-login check on app start
   - Logout functionality

2. **State Management**
   - Provider pattern implementation
   - AuthProvider untuk authentication state
   - ComplaintProvider untuk complaint management
   - Loading states & error handling

3. **API Integration**
   - Dio HTTP client setup
   - Bearer token authentication
   - Error handling & retry logic
   - Pagination support
   - Models untuk API responses

4. **Firebase FCM**
   - FCM service implementation
   - Local notifications setup
   - Background message handling
   - Token registration with backend
   - Notification click handling

5. **UI Screens**
   - Splash screen dengan auto-navigate
   - Login & Register forms
   - Home screen dengan bottom navigation
   - Dashboard dengan statistics
   - Complaint list dengan filter
   - Notification list dengan pagination
   - Profile screen

---

## 🚧 Phase 2: Next Features to Implement

### Priority: HIGH

1. **Create Complaint Screen**
   ```dart
   // lib/screens/complaints/create_complaint_screen.dart
   - Form dengan category dropdown
   - Title, description, location fields
   - Date picker untuk report date
   - Image picker untuk attachments
   - Validation & submit
   ```

2. **Complaint Detail Screen**
   ```dart
   // lib/screens/complaints/complaint_detail_screen.dart
   - Show complete complaint info
   - Display attachments (images)
   - Show status history
   - Admin responses (if any)
   ```

3. **Announcement Screen**
   ```dart
   // lib/screens/announcements/announcement_list_screen.dart
   // lib/screens/announcements/announcement_detail_screen.dart
   - List announcements
   - Show urgent announcements
   - Comment system
   ```

### Priority: MEDIUM

4. **Edit Profile Screen**
   ```dart
   // lib/screens/profile/edit_profile_screen.dart
   - Update name, phone, address
   - Change password
   - Avatar upload
   ```

5. **Notification Settings**
   ```dart
   // lib/screens/settings/notification_settings_screen.dart
   - Enable/disable notification types
   - Sound preferences
   ```

6. **Search & Filter**
   ```dart
   // Enhanced complaint list with:
   - Search by title/description
   - Filter by category
   - Filter by status
   - Sort by date
   ```

### Priority: LOW

7. **Offline Mode**
   ```dart
   // lib/services/cache_service.dart
   - Local database (sqflite)
   - Cache API responses
   - Sync when online
   ```

8. **Image Preview**
   ```dart
   // lib/widgets/image_preview.dart
   - Full screen image viewer
   - Zoom & pan
   - Gallery mode
   ```

---

## 🔧 Configuration Needed

### 1. Firebase Setup

**Status**: Template created, needs configuration

**Steps:**
1. Run `flutterfire configure`
2. Or manually update `lib/firebase_options.dart`
3. Add `google-services.json` to `android/app/`
4. Add `GoogleService-Info.plist` to `ios/Runner/`

**Files to update:**
- [lib/firebase_options.dart](lib/firebase_options.dart) ← Replace with actual credentials

### 2. API Base URL

**Status**: Default set to local IP

**Current:** `http://192.168.1.100:8000/api/`

**To change:**
- Edit [lib/config/app_config.dart](lib/config/app_config.dart)
- Or use environment variable:
  ```bash
  flutter run --dart-define=BASE_URL=http://YOUR_IP:8000/api/
  ```

### 3. Backend Requirements

**Must be running:**
- Laravel server: `php artisan serve --host=0.0.0.0 --port=8000`
- Queue worker: `php artisan queue:work`
- Database migrations ran
- Seeders executed (for default users)

---

## 🧪 Testing Checklist

### Pre-Testing Setup
- [ ] Backend API running
- [ ] Firebase configured
- [ ] Device/Emulator connected
- [ ] Same network (device & backend)

### Authentication
- [ ] Login with valid credentials
- [ ] Login with invalid credentials (error handling)
- [ ] Register new user
- [ ] Auto-login on app restart
- [ ] Logout functionality

### Complaints
- [ ] Load complaints list
- [ ] Filter by status
- [ ] Pagination (load more)
- [ ] View complaint detail
- [ ] Create new complaint (TODO)

### Notifications
- [ ] Load notifications list
- [ ] Mark single as read
- [ ] Mark all as read
- [ ] Pagination
- [ ] Receive push notification (when backend sends)

### UI/UX
- [ ] Loading states visible
- [ ] Error messages shown
- [ ] Pull to refresh works
- [ ] Navigation flows smooth
- [ ] Back button handling

---

## 📱 Build & Deploy

### Debug Build
```powershell
flutter build apk --debug
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build
```powershell
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Install to Device
```powershell
flutter install
```

---

## 🐛 Known Issues

### 1. Firebase Not Configured
**Symptom**: App crashes on start with Firebase error
**Solution**: Run `flutterfire configure` or update `firebase_options.dart`

### 2. Network Connection Failed
**Symptom**: All API calls fail
**Solution**: 
- Check backend is running
- Verify IP address in `app_config.dart`
- Check device and server on same network
- Check firewall not blocking port 8000

### 3. Token Expired
**Symptom**: 401 Unauthorized errors
**Solution**: Logout and login again to get new token

---

## 📝 Code Guidelines

### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

### File Organization
```
lib/
├── config/      # App-wide configuration
├── models/      # Data models
├── services/    # Business logic & API calls
├── providers/   # State management
├── screens/     # UI screens
├── widgets/     # Reusable widgets
└── utils/       # Helper functions
```

### State Management Rules
- Use Provider for global state (Auth, Complaints)
- Use setState for local widget state
- Keep providers focused (single responsibility)

### API Service Pattern
```dart
class XxxService {
  final Dio _dio;
  final AuthService _authService;
  
  Future<ApiResponse> methodName() async {
    try {
      final options = await _getOptions();
      final response = await _dio.get('endpoint', options: options);
      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Handle error
    }
  }
}
```

---

## 🚀 Performance Tips

1. **Images**: Use `cached_network_image` untuk images dari API
2. **Lists**: Use `ListView.builder` untuk long lists
3. **State**: Minimize rebuilds dengan `Consumer` widget
4. **API**: Implement debouncing untuk search
5. **Navigation**: Use named routes untuk better management

---

## 📚 Resources

### Documentation
- [Flutter Docs](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Firebase Flutter](https://firebase.flutter.dev/)

### Backend API Docs
- Check: `C:\laragon\www\mypengaduan\docs\android_setup\`
- FLUTTER_INTEGRATION_GUIDE.md
- ANDROID_INTEGRATION_GUIDE.md
- API_TESTING_GUIDE.md

---

## 📊 Project Stats

- **Total Files Created**: 20+
- **Lines of Code**: ~3,000+
- **Dependencies**: 20 packages
- **Screens**: 7
- **Models**: 5
- **Services**: 4
- **Providers**: 2

---

## ✅ Completion Status

```
✅ Project Setup (100%)
✅ Dependencies (100%)
✅ Configuration (80% - needs Firebase)
✅ Models (100%)
✅ Services (100%)
✅ Providers (100%)
✅ UI Screens (70% - needs create/detail)
🚧 Testing (0% - needs implementation)
🚧 Build (0% - needs APK generation)
```

---

**Last Updated**: January 6, 2026  
**Status**: Ready for Development & Testing  
**Next Step**: Configure Firebase and start testing!
