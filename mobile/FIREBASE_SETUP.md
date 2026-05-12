# Firebase Setup Guide — SaveBite

## Prerequisites
- A Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Package name: `com.savebite.savebite`

## Android Setup

### 1. Download `google-services.json`
1. Open Firebase Console → Project Settings → General
2. Click "Add app" → Android
3. Package name: `com.savebite.savebite`
4. Download `google-services.json`
5. Place it at: `mobile/android/app/google-services.json`

### 2. Verify Gradle Config (already done)
- `settings.gradle.kts`: `com.google.gms.google-services` plugin registered ✅
- `app/build.gradle.kts`: `com.google.gms.google-services` plugin applied ✅

### 3. Enable Cloud Messaging in Firebase Console
1. Firebase Console → Cloud Messaging
2. Enable the API if not already enabled

## iOS Setup (when needed)

### 1. Download `GoogleService-Info.plist`
1. Firebase Console → Add app → iOS
2. Bundle ID: `com.savebite.savebite`
3. Download `GoogleService-Info.plist`
4. Place it at: `mobile/ios/Runner/GoogleService-Info.plist`

### 2. Enable Push Notifications capability
1. Open Xcode → Runner → Signing & Capabilities
2. Add "Push Notifications" capability
3. Add "Background Modes" → check "Remote notifications"

### 3. Upload APNs Key to Firebase
1. Apple Developer → Keys → Create new key with APNs
2. Upload `.p8` key to Firebase Console → Cloud Messaging → APNs

## Testing

```bash
# Run on Android emulator
flutter run

# Send test notification via Firebase Console:
# Cloud Messaging → "Send your first message" → Target: token
```

## Backend Integration

The backend stores FCM tokens via `PUT /api/v1/auth/me/fcm-token`.
When sending notifications, the backend should use the Firebase Admin SDK
to send to the stored `fcm_token` on the `users` table.

### Example Laravel FCM sender (future):
```php
// Using kreait/firebase-php
$messaging = app('firebase.messaging');
$message = CloudMessage::withTarget('token', $user->fcm_token)
    ->withNotification(['title' => $title, 'body' => $body])
    ->withData(['type' => 'order_status', 'id' => $orderId]);
$messaging->send($message);
```
