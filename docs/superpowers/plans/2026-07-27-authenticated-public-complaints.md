# Authenticated Public Complaints Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghapus akses pengaduan publik sebelum login dan mewajibkan autentikasi untuk daftar serta detail pengaduan publik.

**Architecture:** Flutter hanya menampilkan pintu masuk Pengaduan Publik setelah login dan mengirim bearer token pada request daftar/detail. Laravel mempertahankan endpoint yang sama tetapi memasangnya di middleware `auth:sanctum`, sehingga filtering `visibility = public` dan penyembunyian identitas pelapor tetap terpusat di `PublicComplaintController`.

**Tech Stack:** Flutter, GoRouter, Dio, Laravel, Sanctum, PHPUnit.

## Global Constraints

- Pengaduan Publik dapat dibaca semua akun yang berhasil login.
- Pengaduan Privat hanya dapat dibaca pemilik dan admin.
- Guest tidak dapat membuka daftar maupun detail pengaduan.
- Identitas pelapor tidak boleh masuk payload endpoint publik.
- Tidak ada migration database baru.

---

### Task 1: Protect the Flutter Entry Points and API Calls

**Files:**
- Create: `test/authenticated_public_complaints_test.dart`
- Modify: `lib/screens/home/landing_screen.dart`
- Modify: `lib/routes/app_router.dart`
- Modify: `lib/services/complaint_service.dart`

**Interfaces:**
- Consumes: `AuthProvider.isAuthenticated`, `ComplaintService._getOptions()`.
- Produces: protected `AppRouter.publicComplaints` and authenticated `getPublicComplaints()` / `getPublicComplaintDetail()`.

- [ ] **Step 1: Write the failing landing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypengaduan_app/screens/home/landing_screen.dart';

void main() {
  testWidgets('landing does not expose public complaints before login',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Lihat Pengaduan Publik'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the test and confirm the current button makes it fail**

Run:

```bash
flutter test test/authenticated_public_complaints_test.dart
```

Expected: FAIL because `Lihat Pengaduan Publik` is still rendered.

- [ ] **Step 3: Remove guest UI and guest route exemption**

In `landing_screen.dart`, delete the complete `TextButton.icon` block whose
label is `Lihat Pengaduan Publik` and its adjacent spacing.

In `app_router.dart`, remove `isPublicComplaintRoute` and
`isGuestAccessibleRoute`. Restore the protected-route condition to:

```dart
if (!isAuthenticated && !isAuthRoute) {
  debugPrint('Not authenticated, redirecting to landing');
  return landing;
}
```

Keep the `publicComplaints` and `publicComplaintDetail` route definitions so
authenticated users can still navigate from the dashboard.

- [ ] **Step 4: Authenticate public complaint API calls**

In both `getPublicComplaints()` and `getPublicComplaintDetail()`, obtain:

```dart
final options = await _getOptions();
```

Pass `options: options` to `_dio.get(...)`. Update the comments so they state
that the endpoint is read-only for authenticated users.

- [ ] **Step 5: Run focused Flutter verification**

Run:

```bash
flutter test test/authenticated_public_complaints_test.dart test/complaint_visibility_test.dart
dart analyze lib
```

Expected: focused tests PASS and analysis reports no errors introduced by this
change.

### Task 2: Require Sanctum on the Laravel Public Feed

**Files:**
- Modify: `/Users/ftsmiftah/Documents/Projects-Macmini/my-pengaduan/routes/api.php`
- Modify: `/Users/ftsmiftah/Documents/Projects-Macmini/my-pengaduan/tests/Feature/Api/PublicComplaintVisibilityTest.php`

**Interfaces:**
- Consumes: `PublicComplaintController@index`, `PublicComplaintController@show`.
- Produces: authenticated `GET /api/public/complaints` and `GET /api/public/complaints/{id}`.

- [ ] **Step 1: Change the backend tests first**

Add a test that checks both routes return 401 without a token:

```php
public function test_guest_cannot_access_public_complaints(): void
{
    $this->getJson('/api/public/complaints')->assertUnauthorized();
    $this->getJson('/api/public/complaints/1')->assertUnauthorized();
}
```

Add `Sanctum::actingAs($user);` before the existing public-feed and
private-detail requests so those tests continue to validate visibility rules
after authentication.

- [ ] **Step 2: Run the backend test and confirm guest access currently fails the requirement**

Run:

```bash
vendor/bin/phpunit tests/Feature/Api/PublicComplaintVisibilityTest.php
```

Expected: FAIL because guest requests currently reach the public controller.

- [ ] **Step 3: Protect the routes**

Change the public complaint route group to:

```php
Route::middleware(['auth:sanctum', 'throttle:60,1'])
    ->prefix('public/complaints')
    ->group(function () {
        Route::get('/', [PublicComplaintController::class, 'index']);
        Route::get('/{id}', [PublicComplaintController::class, 'show'])
            ->whereNumber('id');
    });
```

- [ ] **Step 4: Format and run backend verification**

Run:

```bash
vendor/bin/pint routes/api.php tests/Feature/Api/PublicComplaintVisibilityTest.php
vendor/bin/phpunit tests/Feature/Api/PublicComplaintVisibilityTest.php
php artisan route:list --path=api/public/complaints
```

Expected: all visibility tests PASS and both routes show the `auth:sanctum`
middleware.

### Task 3: Deployment Handoff

**Files:**
- Modify: `docs/API_INTEGRATION.md`

**Interfaces:**
- Consumes: final Flutter and Laravel behavior.
- Produces: deployment instructions for Plesk.

- [ ] **Step 1: Update endpoint documentation**

Document that `public/complaints` is public in visibility scope but requires an
authenticated bearer token.

- [ ] **Step 2: Run final diff checks**

Run in both repositories:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; only scoped feature files and pre-existing
Flutter formatting changes remain visible.

- [ ] **Step 3: Provide Plesk commands**

After the backend commit is pulled on Plesk, run:

```bash
php artisan optimize:clear
php artisan route:list --path=api/public/complaints
```

No `php artisan migrate` is required for this access-control-only follow-up.
