# Firebase Setup Checklist — New Project

> **After switching to client's Firebase project, follow these steps in order.**
> This ensures all services are enabled, configured, and tested before the app goes live.

---

## Phase 1 — Authentication Setup

### Step 1.1 — Enable Email/Password Authentication
1. Go to **Firebase Console → Authentication → Sign-in method**
2. Click on **Email/Password**
3. Toggle **Enable** to ON
4. Toggle **Email enumeration protection** to ON (recommended for security)
5. Click **Save**
6. ✅ Staff and customers can now log in with email + password

### Step 1.2 — Enable Phone Authentication (for customer login)
1. Go to **Firebase Console → Authentication → Sign-in method**
2. Click on **Phone**
3. Toggle **Enable** to ON
4. **Important:** Under "Phone numbers", add the country code for Sri Lanka:
   - Click **+ Add phone number** or select from list
   - Select **Sri Lanka (+94)**
   - Click **Save**
5. ✅ Customers can now use phone OTP for login

### Step 1.3 — Add Test Phone Numbers (optional, for development)
1. In the Phone sign-in method panel, find **"Phone numbers for testing (optional)"**
2. Click **+ Add phone number**
3. Enter a test number: `+94771234567` (or any Sri Lankan number)
4. Enter a test SMS code: `123456`
5. Click **Save**
6. ✅ You can now test phone login in the Flutter app without waiting for real SMS

---

## Phase 2 — Firestore Database Setup

### Step 2.1 — Create Firestore Database
1. Go to **Firebase Console → Firestore Database**
2. Click **Create database**
3. Select **Start in test mode** (we'll replace with security rules immediately)
4. Click **Next**
5. Select region: **asia-south1** (closest to Sri Lanka)
6. Click **Enable**
7. ✅ Firestore is now ready and accessible

### Step 2.2 — Apply Security Rules
1. In Firestore, go to **Rules** tab
2. **Delete all default test-mode rules**
3. Paste the entire content from `REMAINING_WORK.md` Task 3 (the production rules with `isOwner()`, `isAdmin()`, etc.)
4. Click **Publish**
5. ✅ Shop data is now protected — only authenticated users can read their own data, only admins can manage menu/orders

### Step 2.3 — Create Composite Index (auto-triggered)
1. Open the Flutter app and run `flutter pub get && flutter run`
2. Navigate to any admin screen (orders dashboard or menu management)
3. If a composite index is missing, Flutter will show an error with a clickable **auto-create index** link
4. **Click the link** — it will open Firebase Console and create the index automatically
5. Wait ~1-2 minutes for the index to build
6. Refresh the app — error should be gone
7. ✅ Orders can now be queried by status + date efficiently

**Note:** This index is for the `menuItems` collection: `available ASC, createdAt DESC` (allows filtering available items and sorting by creation date)

---

## Phase 3 — Firebase Storage Setup (Image Upload)

### Step 3.1 — Enable Firebase Storage
1. Go to **Firebase Console → Storage**
2. Click **Get started**
3. Start in **Production mode** (rules are set by default, very restrictive)
4. Click **Next**
5. Select region: **asia-south1** (same as Firestore)
6. Click **Done**
7. ✅ Storage is now ready (but locked down by default)

### Step 3.2 — Update Storage Security Rules
1. In Storage, go to **Rules** tab
2. Replace the default rules with:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /menuItems/{itemId}/{filename} {
      allow read: if true;  // anyone can view menu item images
      allow write: if request.auth != null &&
                      get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
      // only admins can upload/delete images
    }
  }
}
```
3. Click **Publish**
4. ✅ Images are now readable by all, writable only by admins

---

## Phase 4 — User Data Setup

### Step 4.1 — Create Admin Account in Firebase Auth
1. Go to **Firebase Console → Authentication → Users**
2. Click **+ Add user**
3. Email: `admin@beruwalapeizza.com` (or your email)
4. Password: Create a strong password
5. Click **Add user**
6. ✅ Admin account created in Firebase

### Step 4.2 — Create Admin User Document in Firestore
1. Go to **Firebase Console → Firestore Database**
2. Click **Start collection**
3. Collection name: `users`
4. Click **Next**
5. Document ID: **Copy the UID from the admin user you just created** (found in Authentication → Users table)
6. Click **Save**
7. Add these fields:
   ```
   name (String): "Admin"
   phone (String): "+94771234567" (or leave empty)
   role (String): "admin"
   createdAt (Timestamp): Set to current date/time
   ```
8. Click **Save**
9. ✅ Admin profile is now complete and app recognizes the admin role

### Step 4.3 — Verify Admin Access
1. Run the Flutter app
2. On Splash Screen, tap the app logo **5 times** (hidden staff access)
3. Use the admin email/password to log in
4. You should see **Orders**, **Menu**, **Settings** tabs
5. ✅ Admin is fully operational

---

## Phase 5 — Initialize Shop Settings (One-time)

### Step 5.1 — Create Initial Shop Settings Document (Optional)
This step is optional but recommended — it pre-populates the shop hours so the admin doesn't start from scratch.

1. Go to **Firebase Console → Firestore Database**
2. Click **Start collection**
3. Collection name: `settings`
4. Click **Next**
5. Document ID: `shopSettings`
6. Add these fields manually:
   ```
   isManuallyClosedNow (Boolean): false
   estimatedWaitMinutes (Number): 30
   weeklyHours (Map):
     monday (Map):
       isClosedAllDay (Boolean): false
       open (String): "09:00"
       close (String): "22:00"
     tuesday (Map):
       isClosedAllDay (Boolean): false
       open (String): "09:00"
       close (String): "22:00"
     [repeat for all 7 days...]
     sunday (Map):
       isClosedAllDay (Boolean): false
       open (String): "09:00"
       close (String): "22:00"
   ```
7. Click **Save**
8. ✅ Shop settings initialized (can be edited in-app via admin Settings tab)

**Alternative:** Skip this step. The first time an admin saves settings from the app's Settings tab, this document will be created automatically.

---

## Phase 6 — Android App Signing (Critical for Production)

### Step 6.1 — Update Android Package Name (if different)
1. Confirm the package name is still `com.beruwala.pizza` in:
   - `android/app/build.gradle.kts` (check `namespace` and `applicationId`)
   - Firebase Console → Project settings → App configuration
2. If you changed the package name, regenerate `google-services.json` via FlutterFire CLI

### Step 6.2 — Generate SHA Fingerprints (for physical device testing)
1. Open terminal in project root
2. Run:
   ```bash
   ./gradlew signingReport
   ```
3. Copy the **SHA-1** and **SHA-256** fingerprints from the output
4. Go to **Firebase Console → Project settings → App configuration (Android)**
5. Under "Fingerprints", paste both:
   - SHA-1 fingerprint
   - SHA-256 fingerprint
6. Click **Save**
7. ✅ Firebase will now recognize your app on physical Android devices

---

## Phase 7 — Blaze Plan Upgrade (if not already on Blaze)

### Step 7.1 — Upgrade to Blaze Plan
1. Go to **Firebase Console → Blaze plan**
2. Click **Upgrade to Blaze**
3. Follow the payment/billing setup
4. Confirm plan is now **Blaze (Pay as you go)**
5. ✅ You can now use:
   - Phone OTP (Firebase Auth)
   - Firebase Storage (image uploads)
   - Cloud Functions (FCM notifications, if implemented)

**Cost note:** Beruwala Pizza with ~20-50 orders/day will likely cost **$0-2/month** because Firebase has generous free tiers even on Blaze.

---

## Phase 8 — Environment Configuration

### Step 8.1 — Update Firebase Config Files via FlutterFire
If you haven't already, regenerate the Firebase config for both platforms:

```bash
flutterfire configure
```

Select the client's Firebase project from the list.

This updates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

✅ The app now points to the client's Firebase project

---

## Phase 9 — Testing Checklist

### Step 9.1 — Test Customer Flow
- [ ] Customer can sign up with email/password
- [ ] Customer can browse menu
- [ ] Customer can add items to cart
- [ ] Customer can place an order (checkout)
- [ ] Order confirmation screen shows order number
- [ ] Customer can view "My Orders" list
- [ ] Customer can track order in real-time

### Step 9.2 — Test Admin Flow
- [ ] Admin can log in with email/password
- [ ] Admin can view all orders in dashboard
- [ ] Admin can filter orders by status
- [ ] Admin can click an order and see details
- [ ] Admin can update order status (received → preparing → ready → delivered)
- [ ] Admin can manage menu (add/edit/delete items)
- [ ] Admin can toggle item availability
- [ ] Admin can set shop hours in Settings
- [ ] Admin can toggle "Closed Now"

### Step 9.3 — Test Shop Hours
- [ ] Set shop hours to a closed time (e.g. close at 2pm, test at 3pm)
- [ ] Home screen shows orange "We're closed" banner
- [ ] Checkout button is disabled with warning text
- [ ] After reopening, banner disappears and button works
- [ ] ✅ Real-time stream updates work

### Step 9.4 — Test on Physical Devices
- [ ] Test on physical Android phone (not emulator)
- [ ] Firebase Authentication recognizes the device (SHA fingerprints)
- [ ] All screens load and respond normally
- [ ] No crashes or errors in Flutter logs

---

## Phase 10 — Pre-Launch Final Checks

### Step 10.1 — Data Backup
1. Go to **Firebase Console → Firestore Database**
2. Click **⋮ (menu) → Export**
3. Choose a Cloud Storage bucket (create one if needed)
4. This backs up all Firestore data periodically
5. ✅ Data is protected

### Step 10.2 — Enable Firestore Backups (Optional)
1. Go to **Firebase Console → Firestore Database → Backups**
2. Create a backup schedule (e.g. daily backups)
3. ✅ Automated recovery available if data is corrupted

### Step 10.3 — Monitor Performance
1. Go to **Firebase Console → Performance**
2. Enable Performance Monitoring (if not already on)
3. This tracks app load times, network latency, etc.
4. ✅ You'll get alerts if the app becomes slow

### Step 10.4 — Set Up Analytics (Optional)
1. Go to **Firebase Console → Analytics**
2. Confirm it's enabled
3. The app will start tracking user sessions, screen views, etc.
4. ✅ You can see how customers use the app

---

## Phase 11 — Production Deployment

### Step 11.1 — Build and Release
```bash
flutter clean
flutter build apk --release
# or
flutter build appbundle --release  # for Google Play Store
```

### Step 11.2 — Deploy to Play Store (if needed)
- Requires Google Play Developer account ($25 one-time)
- Upload the `.aab` (app bundle) file
- Follow Play Store submission guidelines

### Step 11.3 — Distribute to Customers
- Share APK directly (if not on Play Store)
- Or provide Play Store link

---

## Quick Reference — Firestore Collections Schema

After setup, your Firestore should have these collections:

```
users/
  {uid}/
    name: String
    phone: String
    role: String ("customer" | "admin")
    createdAt: Timestamp
    fcmToken: String (optional)

menuItems/
  {itemId}/
    name: String
    category: String
    description: String
    imageUrl: String (Firebase Storage URL)
    available: Boolean
    prices: { small, medium, large }
    createdAt: Timestamp

orders/
  {orderId}/
    orderNumber: Number
    customerId: String
    customerName: String
    customerPhone: String
    type: String ("delivery" | "pickup")
    address: String
    status: String ("received" | "preparing" | "ready" | "delivered")
    note: String
    items: Array [ { itemId, name, size, quantity, price } ]
    subtotal: Number
    deliveryFee: Number
    total: Number
    createdAt: Timestamp
    updatedAt: Timestamp

settings/
  shopSettings/
    isManuallyClosedNow: Boolean
    estimatedWaitMinutes: Number
    weeklyHours: { monday, tuesday, ... sunday }
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "PERMISSION_DENIED" in Firestore | Check security rules are published correctly. Ensure user is authenticated. |
| Phone OTP not sending | Confirm SMS country (Sri Lanka +94) is enabled in Firebase Console. Blaze plan required. |
| Images not uploading | Enable Firebase Storage, apply security rules, ensure Blaze plan. |
| App crashes on login | Check SHA fingerprints added to Firebase Console. Regenerate `google-services.json`. |
| Orders not showing in dashboard | Verify Firestore composite index is created. Check security rules allow admin read. |
| Shop hours not updating | Ensure `settings/shopSettings` document exists in Firestore. Refresh app to reload stream. |

---

## Summary

✅ **After completing all phases, the app is ready for the client to use.** The checklist covers:
- User authentication (email + phone)
- Database (Firestore) with security
- File storage (images)
- Initial data (admin user, shop settings)
- Testing
- Deployment readiness

**Estimated time:** 30-45 minutes for complete setup.
