# 🔥 FIREBASE SETUP — Complete Step-by-Step Guide

> **Start here if you just created a new Firebase project.**
> Follow each step exactly in order. Estimated time: **45-60 minutes**.

---

## **STEP 1: Open Firebase Console**

1. Go to: **firebase.google.com**
2. Click **Go to console**
3. Select your **beruwala-pizza** project

✅ Ready to start.

---

## **STEP 2: Add Android App**

1. Click the **Android icon** (or "Add app")
2. **Package name:** `com.beruwala.pizza`
3. **App nickname (optional):** `Beruwala Pizza Android`
4. Click **Register app**
5. **Download google-services.json**
6. Save it to: `android/app/google-services.json` in your Flutter project
7. Click **Next** twice, then **Continue to console**

✅ Android app registered.
C:\Users\hp\Documents\GitHub\beruwala_pizza\beruwala_pizza.iml
---

## **STEP 3: Add iOS App**

1. Click the **iOS icon** (or "Add app")
2. **Bundle ID:** `com.beruwala.pizza`
3. **App nickname (optional):** `Beruwala Pizza iOS`
4. **App Store ID:** Leave empty
5. Click **Register app**
6. **Download GoogleService-Info.plist**
7. Save it to: `ios/Runner/GoogleService-Info.plist` in your Flutter project
8. Click **Next** twice, then **Continue to console**

✅ iOS app registered.

---

## **STEP 4: Enable Email/Password Authentication**

1. In Firebase Console, click **Authentication** (left sidebar)
2. Click **Get started** (or go to **Sign-in method**)
3. Click on **Email/Password**
4. Toggle **Enable** → **ON**
5. Toggle **Email enumeration protection** → **ON** (security)
6. Click **Save**

✅ Email/Password auth enabled.

---

## **STEP 5: Enable Phone Authentication**

1. Still in **Authentication → Sign-in method**
2. Click **Phone**
3. Toggle **Enable** → **ON**
4. Under "Phone numbers", click **+ Add phone number**
5. Select **Sri Lanka (+94)** from the list
6. Click **Save**

✅ Phone auth enabled.

---

## **STEP 6: Add Test Phone Number** (for development)

1. Still in the **Phone sign-in method** panel
2. Find **"Phone numbers for testing (optional)"**
3. Click **+ Add phone number**
4. **Phone number:** `+94771234567`
5. **SMS code:** `123456`
6. Click **Save**

✅ Test phone login ready.

---

## **STEP 7: Create Firestore Database**

1. In Firebase Console, click **Firestore Database** (left sidebar)
2. Click **Create database**
3. Select **Start in test mode**
4. Click **Next**
5. Select region: **asia-south1** (closest to Sri Lanka)
6. Click **Enable**
7. Wait ~30 seconds for creation

✅ Firestore database created.

---

## **STEP 8: Apply Firestore Security Rules**

1. In Firestore, click the **Rules** tab
2. **Select all the default text** and delete it
3. **Paste this entire security rules code:**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isOwner() {
      return request.auth.uid == resource.data.customerId || 
             request.auth.uid == resource.id;
    }
    
    function isAdmin() {
      return get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    function isAuthenticated() {
      return request.auth != null;
    }

    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if false;
    }

    // Menu items
    match /menuItems/{itemId} {
      allow read: if true;
      allow create, update, delete: if isAdmin();
    }

    // Orders
    match /orders/{orderId} {
      allow read: if isOwner() || isAdmin();
      allow create: if isAuthenticated();
      allow update: if isAdmin();
      allow delete: if false;
    }

    // Settings
    match /settings/{document=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

4. Click **Publish**

✅ Security rules applied.

---

## **STEP 9: Enable Firebase Storage**

1. In Firebase Console, click **Storage** (left sidebar)
2. Click **Get started**
3. Select **Production mode**
4. Click **Next**
5. Select region: **asia-south1**
6. Click **Done**
7. Wait ~30 seconds

✅ Firebase Storage created.

---

## **STEP 10: Apply Storage Security Rules**

1. In Storage, click the **Rules** tab
2. Select all and delete the default rules
3. **Paste this code:**

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /menuItems/{itemId}/{filename} {
      allow read: if true;
      allow write: if request.auth != null &&
                      get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

4. Click **Publish**

✅ Storage rules applied.

---

## **STEP 11: Create Admin Account**

1. In Firebase Console, click **Authentication**
2. Go to **Users** tab
3. Click **+ Add user**
4. **Email:** `admin@beruwalapizza.com`
5. **Password:** Create a strong password (write it down!)
   - Example: `Admin@BeruwalaPizza2026!`
6. Click **Add user**

✅ Admin user created. **Now copy the UID from the user list** (the long ID next to the email). You'll need it in the next step.

---

## **STEP 12: Create Admin Profile in Firestore**

1. In Firebase Console, click **Firestore Database**
2. Click **+ Start collection**
3. **Collection name:** `users`
4. Click **Next**
5. **Document ID:** Paste the UID you copied in Step 11
6. Click **Save**
7. Now add fields. Click **+ Add field** for each:

   **Field 1:**
   - Name: `name`
   - Type: String
   - Value: `Admin`
   
   **Field 2:**
   - Name: `phone`
   - Type: String
   - Value: `+94771234567`
   
   **Field 3:**
   - Name: `role`
   - Type: String
   - Value: `admin`
   
   **Field 4:**
   - Name: `createdAt`
   - Type: Timestamp
   - Click **Set server timestamp**

8. Click **Save**

✅ Admin profile created.

---

## **STEP 13: Create Shop Settings Document** (optional but recommended)

1. Still in Firestore, click **+ Start collection**
2. **Collection name:** `settings`
3. Click **Next**
4. **Document ID:** `shopSettings`
5. Click **Save**
6. Add these fields:

   **Field 1:**
   - Name: `isManuallyClosedNow`
   - Type: Boolean
   - Value: `false`
   
   **Field 2:**
   - Name: `estimatedWaitMinutes`
   - Type: Number
   - Value: `30`
   
   **Field 3:**
   - Name: `weeklyHours`
   - Type: Map
   - Add sub-fields for each day (monday-sunday):
   
   For each day (click **+ Add map** inside weeklyHours):
   ```
   monday:
     isClosedAllDay: false (Boolean)
     open: "09:00" (String)
     close: "22:00" (String)
   tuesday:
     isClosedAllDay: false
     open: "09:00"
     close: "22:00"
   wednesday:
     isClosedAllDay: false
     open: "09:00"
     close: "22:00"
   thursday:
     isClosedAllDay: false
     open: "09:00"
     close: "22:00"
   friday:
     isClosedAllDay: false
     open: "09:00"
     close: "22:00"
   saturday:
     isClosedAllDay: false
     open: "09:00"
     close: "22:00"
   sunday:
     isClosedAllDay: false
     open: "09:00"
     close: "22:00"
   ```

7. Click **Save**

✅ Shop settings created.

---

## **STEP 14: Get SHA Fingerprints for Android**

This is needed so Firebase recognizes your Android device.

1. Open **Terminal** in your project root
2. Run:
   ```bash
   ./gradlew signingReport
   ```
3. Look for the output. Copy these two lines:
   - `SHA-1: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`
   - `SHA-256: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

✅ Fingerprints copied.

---

## **STEP 15: Add SHA Fingerprints to Firebase**

1. Go to **Firebase Console → Project Settings** (click gear icon, top left)
2. Click the **Android app** (com.beruwala.pizza)
3. Scroll down to **Fingerprints**
4. Click **+ Add fingerprint**
5. Paste the **SHA-1** fingerprint
6. Click **+ Add fingerprint** again
7. Paste the **SHA-256** fingerprint
8. Click **Save**

✅ Firebase recognizes your Android device.

---

## **STEP 16: Upgrade to Blaze Plan** (if not already)

1. In Firebase Console, click **Billing** (left sidebar, bottom)
2. Click **Upgrade to Blaze** (or **Manage plan**)
3. Follow the payment setup with your card
4. Confirm it says **"Blaze (Pay as you go)"**

✅ Blaze plan active. **Cost:** ~$0-2/month for a small pizza shop.

---

## **STEP 17: Regenerate Flutter Firebase Config**

In your project root terminal, run:

```bash
flutterfire configure
```

1. Select **beruwala-pizza** project from the list
2. Confirm Android and iOS platforms are selected
3. Wait for it to complete

This updates your Flutter app to point to the new Firebase project.

✅ Flutter Firebase config updated.

---

## **STEP 18: Test the App**

1. In terminal, run:
   ```bash
   flutter run
   ```

2. On **Splash Screen**, tap the **app logo 5 times** (hidden staff mode)

3. Log in with:
   - Email: `admin@beruwalapizza.com`
   - Password: (the password you created in Step 11)

4. You should see **Orders | Menu | Settings** tabs

✅ Admin login working!

---

## **Firestore Collections Schema Reference**

After setup, your Firestore should have these collections:

```
users/
  {uid}/
    name: String
    phone: String
    role: String ("customer" | "admin")
    createdAt: Timestamp

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
    paymentStatus: String ("pending" | "paid" | "cash_on_delivery")
    paymentMethod: String ("cash" | "card")
    paymentTransactionId: String (optional)
    createdAt: Timestamp
    updatedAt: Timestamp

settings/
  shopSettings/
    isManuallyClosedNow: Boolean
    estimatedWaitMinutes: Number
    weeklyHours: Map { monday, tuesday, ... sunday }
```

---

## **Troubleshooting**

| Problem | Solution |
|---------|----------|
| "PERMISSION_DENIED" in Firestore | Check security rules are published. Ensure user is authenticated. |
| Phone OTP not sending | Confirm Sri Lanka (+94) is enabled. Blaze plan required. |
| Images not uploading | Enable Firebase Storage, apply security rules, ensure Blaze plan. |
| App crashes on login | Check SHA fingerprints added to Firebase. Regenerate google-services.json. |
| Orders not showing in dashboard | Verify Firestore composite index is created (auto-triggered on first query). |
| Shop hours not updating | Ensure settings/shopSettings document exists. Refresh app to reload stream. |

---

## **Next Steps After Setup**

Once Firebase is fully configured:

1. **Test Customer Flow:**
   - Sign up with email
   - Browse menu
   - Add items to cart
   - Place order
   - View "My Orders"

2. **Test Admin Flow:**
   - Log in as admin
   - View orders dashboard
   - Update order status
   - Manage menu items
   - Configure shop hours

3. **OnePay Payment Gateway:**
   - Get merchant credentials from OnePay
   - Replace test credentials in `lib/utils/app_secrets.dart`
   - Test payment flow with real test cards

4. **Deploy to Production:**
   - Build APK/AAB for Android
   - Build IPA for iOS
   - Distribute to app stores or directly to users

---

**Status:** ✅ Setup complete when all 18 steps are done!
