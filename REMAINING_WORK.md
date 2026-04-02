# Beruwala Pizza — Remaining Work Instructions

> **Who this is for:** Any AI agent or developer completing the remaining MVP features.
> **Read this fully before writing any code.**
> **Do not guess — every file path, provider name, field name, and route is spelled out exactly.**

---

## Current App Status (What Is Already Built)

These screens are **complete and working**. Do NOT rewrite them:

| Screen | File | Status |
|---|---|---|
| Splash | `lib/screens/splash_screen.dart` | ✅ Done |
| Home (menu grid) | `lib/screens/customer/home_screen.dart` | ✅ Done |
| Item Detail | `lib/screens/customer/item_detail_screen.dart` | ✅ Done |
| Cart | `lib/screens/customer/cart_screen.dart` | ✅ Done |
| Checkout | `lib/screens/customer/checkout_screen.dart` | ✅ Done |
| Customer Login | `lib/screens/customer/phone_entry_screen.dart` | ✅ Done (email/password workaround) |
| OTP Screen | `lib/screens/customer/otp_screen.dart` | ✅ Built (bypassed until Blaze plan) |
| Order Confirmation | `lib/screens/customer/order_confirmation_screen.dart` | ✅ Done |
| Order Tracking | `lib/screens/customer/order_tracking_screen.dart` | ✅ Done |
| Account | `lib/screens/customer/account_screen.dart` | ⚠️ Partial — missing name display + My Orders |
| Staff Login | `lib/screens/admin/staff_login_screen.dart` | ✅ Done |
| Orders Dashboard | `lib/screens/admin/orders_dashboard_screen.dart` | ✅ Done |
| Order Detail (admin) | `lib/screens/admin/order_detail_screen.dart` | ✅ Done |
| Menu Management | `lib/screens/admin/menu_management_screen.dart` | ✅ Done |
| Add Item | `lib/screens/admin/add_item_screen.dart` | ✅ Done |
| Edit Item | `lib/screens/admin/edit_item_screen.dart` | ✅ Done |

---

## Task List (Priority Order)

1. **[P1] My Orders Screen** — new screen, new route, new provider, account screen update
2. **[P2] Account Screen fix** — show user name from Firestore, not just email
3. **[P3] Firestore Security Rules** — replace test-mode rules with production rules
4. **[P4] Phone OTP Restoration** — instructions for when Firebase Blaze plan is enabled
5. **[P5] FCM Push Notifications** — notify customer when admin changes order status

Complete tasks **in order**. Do not skip ahead.

---

---

# TASK 1 — My Orders Screen

## What needs to happen (overview)

The customer can see their past orders in the Account tab. Currently the Account screen (`lib/screens/customer/account_screen.dart`) has no orders list. We need to:

1. Add a new Riverpod provider for customer orders
2. Add a new named route
3. Create a new screen file `my_orders_screen.dart`
4. Update the Account screen to show a "My Orders" tile

---

## Step 1.1 — Add provider to `lib/providers/order_provider.dart`

Open `lib/providers/order_provider.dart`. It currently looks like:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'menu_provider.dart';

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllOrders();
});

final selectedOrderStatusFilter = StateProvider<String?>((ref) => null);

final filteredOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final statusFilter = ref.watch(selectedOrderStatusFilter);
  final orders = ref.watch(allOrdersProvider);

  return orders.whenData((list) {
    if (statusFilter == null) return list;
    return list.where((o) => o.status == statusFilter).toList();
  });
});
```

**Add this new provider at the bottom of that file** (do not remove existing code):

```dart
// Customer's own orders — keyed by their Firebase uid
final customerOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, customerId) {
  return ref.watch(firestoreServiceProvider).getOrdersByCustomer(customerId);
});
```

**Why `StreamProvider.family`?** Because the provider needs to accept a parameter (the customer's uid). Different customers have different uids so it needs to be dynamic.

---

## Step 1.2 — Add route to `lib/utils/app_routes.dart`

Open `lib/utils/app_routes.dart`. 

**Find this block (route constants section):**
```dart
  static const String staffLogin = '/staff-login';
  static const String ordersDashboard = '/orders-dashboard';
  static const String orderDetail = '/order-detail';
  static const String menuManagement = '/menu-management';
  static const String addItem = '/add-item';
  static const String editItem = '/edit-item';
```

**Add one line** after `editItem`:
```dart
  static const String myOrders = '/my-orders';
```

**Then find the imports at the top** of the file:
```dart
import '../screens/admin/edit_item_screen.dart';
```

**Add this import** after it:
```dart
import '../screens/customer/my_orders_screen.dart';
```

**Then find the routes map** — find this entry near the end:
```dart
        editItem: (_) => const EditItemScreen(),
```

**Add one line** after it:
```dart
        myOrders: (_) => const MyOrdersScreen(),
```

---

## Step 1.3 — Create `lib/screens/customer/my_orders_screen.dart`

Create this file exactly as written. Do not change any class names or import paths:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../widgets/status_badge.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    // If somehow opened while logged out, show message
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please log in to view your orders.')),
      );
    }

    // Watch the stream of this customer's orders using their uid
    final ordersAsync = ref.watch(customerOrdersProvider(user.uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 72,
                    color: AppColors.textGrey.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textGrey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your past orders will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final order; // OrderModel

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.orderTracking,
          arguments: order.id, // pass the orderId String
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: order number + status badge
              Row(
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),

              // Items list (short)
              Text(
                order.items
                    .map((item) =>
                        '${item.quantity}× ${item.name} (${item.size[0].toUpperCase()})')
                    .join(', '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Bottom row: date + total
              Row(
                children: [
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${AppConstants.currencySymbol} ${order.total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Note on `_OrderCard`:** The `order` field type is declared as `final order;` (no type annotation) to keep the file self-contained without needing to know the exact import path for `OrderModel`. If the linter complains, change it to `final OrderModel order;` and add `import '../../models/order_model.dart';` at the top.

---

## Step 1.4 — Update `lib/screens/customer/account_screen.dart`

This file has a `_LoggedInView` widget that currently only shows an email and a logout button. We need to add a "My Orders" list tile.

**Open `lib/screens/customer/account_screen.dart`.**

**Find this import section at the top:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
```

**Add this import** (just one new line):
```dart
// No new import needed — all providers already imported
```

(No new imports needed for Step 1.4.)

**Find the `AccountScreen` build method.** It currently reads:
```dart
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: user == null
            ? _GuestView(
                onLogin: () =>
                    Navigator.pushNamed(context, AppRoutes.phoneEntry),
              )
            : _LoggedInView(
                email: user.email ?? '',
                onLogout: () async {
                  await ref.read(authServiceProvider).signOut();
                },
              ),
      ),
    );
```

**Replace that entire `_LoggedInView(...)` call** with this:
```dart
            : _LoggedInView(
                email: user.email ?? '',
                uid: user.uid,
                onLogout: () async {
                  await ref.read(authServiceProvider).signOut();
                },
              ),
```

The only change is adding `uid: user.uid,` as a new named parameter.

**Find the `_LoggedInView` class.** It currently starts with:
```dart
class _LoggedInView extends StatelessWidget {
  final String email;
  final VoidCallback onLogout;
  const _LoggedInView({required this.email, required this.onLogout});
```

**Replace the entire `_LoggedInView` class** with this new version:

```dart
class _LoggedInView extends ConsumerWidget {
  final String email;
  final String uid;
  final VoidCallback onLogout;

  const _LoggedInView({
    required this.email,
    required this.uid,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the user's name from Firestore
    // userModelProvider is defined in lib/providers/auth_provider.dart
    // It returns AsyncValue<UserModel?> — UserModel has fields: uid, name, phone, role
    final userModel = ref.watch(userModelProvider);
    final displayName = userModel.valueOrNull?.name ?? '';
    final displayPhone = userModel.valueOrNull?.phone ?? '';

    return Column(
      children: [
        const SizedBox(height: 20),

        // Avatar with first letter of name or email
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary,
          child: Text(
            displayName.isNotEmpty
                ? displayName[0].toUpperCase()
                : (email.isNotEmpty ? email[0].toUpperCase() : 'U'),
            style: const TextStyle(
              fontSize: 32,
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Show name if available, fallback to email
        Text(
          displayName.isNotEmpty ? displayName : email,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),

        if (displayPhone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            displayPhone,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGrey,
                ),
          ),
        ],

        const SizedBox(height: 32),
        const Divider(),

        // My Orders tile
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined,
              color: AppColors.primary),
          title: const Text('My Orders'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, AppRoutes.myOrders),
        ),

        const Divider(),

        // Logout tile
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: onLogout,
        ),
      ],
    );
  }
}
```

**Important:** `_LoggedInView` changed from `StatelessWidget` to `ConsumerWidget` because it now uses `ref.watch`. Make sure the `extends` keyword says `ConsumerWidget` and the `build` method has `WidgetRef ref` as the second parameter.

---

---

# TASK 2 — Account Screen: Show User Name

This is already handled by Task 1 Step 1.4. The `userModelProvider` that already exists in `lib/providers/auth_provider.dart` returns `AsyncValue<UserModel?>`. `UserModel` has a `.name` field (String) and a `.phone` field (String).

No separate work needed if Task 1 is completed.

---

---

# TASK 3 — Firestore Security Rules

## What is this?

Firestore is currently in **test mode** which means anyone can read/write anything. Before the app goes live, replace the rules with proper ones.

## Where to apply this

Go to **Firebase Console → Firestore Database → Rules tab**.

Delete everything and paste this:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper functions ──────────────────────────────────────────

    function isLoggedIn() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isLoggedIn() && request.auth.uid == uid;
    }

    function isAdmin() {
      return isLoggedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // ── users collection ─────────────────────────────────────────
    // Customers can read/write their own doc.
    // Admins can read any user doc.

    match /users/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid);
      allow delete: if false; // no one can delete user docs
    }

    // ── menuItems collection ─────────────────────────────────────
    // Anyone can read available menu items (including guests).
    // Only admins can create/update/delete.

    match /menuItems/{itemId} {
      allow read: if true; // public read — customers and guests
      allow create, update, delete: if isAdmin();
    }

    // ── orders collection ─────────────────────────────────────────
    // Customers can create orders and read their own orders.
    // Admins can read all orders and update status.
    // No one can delete orders.

    match /orders/{orderId} {
      allow read: if isAdmin() ||
        (isLoggedIn() && resource.data.customerId == request.auth.uid);
      allow create: if isLoggedIn();
      allow update: if isAdmin() ||
        (isLoggedIn() && resource.data.customerId == request.auth.uid);
      allow delete: if false;
    }

  }
}
```

**Click "Publish".**

## Notes
- Guests (not logged in) can browse menu items but cannot place orders or read orders.
- Customers can only see their own orders.
- Only admins (users with `role: "admin"` in Firestore) can update order status or manage menu.

---

---

# TASK 4 — Phone OTP Restoration (Do This When Blaze Plan Is Enabled)

## Background

The app currently uses **email + password** for customer login because Firebase phone OTP requires the Blaze (paid) plan. The provider code for phone OTP is **already built** (`phoneAuthProvider` in `lib/providers/auth_provider.dart`). When the Blaze plan is active, follow these steps to restore real phone login.

## Step 4.1 — Enable Phone Sign-in in Firebase Console

1. Go to **Firebase Console → Authentication → Sign-in method**
2. Click **Phone** and toggle it on
3. Save

## Step 4.2 — Restore `lib/screens/customer/phone_entry_screen.dart`

The current file is a temporary email/password screen. Replace the **entire file** with this phone OTP version:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone =
        '${AppConstants.countryCode}${_phoneController.text.trim()}';

    // This calls FirebaseAuth.verifyPhoneNumber behind the scenes.
    // Provider is in lib/providers/auth_provider.dart — class PhoneAuthNotifier.
    await ref.read(phoneAuthProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(phoneAuthProvider);

    // When OTP is sent, navigate to OTP screen
    ref.listen(phoneAuthProvider, (_, next) {
      if (next.otpState == OtpState.sent) {
        Navigator.pushNamed(
          context,
          AppRoutes.otp,
          arguments: _phoneController.text.trim(),
        );
      }
      // Auto-verified (e.g. on emulator or same device)
      if (next.otpState == OtpState.verified) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    });

    final isSending = otpState.otpState == OtpState.sending;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Enter your phone number',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send you a verification code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '${AppConstants.countryCode} ',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => v == null || v.trim().length < 9
                    ? 'Enter a valid Sri Lankan mobile number (9 digits)'
                    : null,
              ),
              if (otpState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  otpState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSending ? null : _sendOtp,
                  child: isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Send Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Step 4.3 — Verify `lib/screens/customer/otp_screen.dart` works

The OTP screen already exists. It should receive a `String` phone number as route argument and use `phoneAuthProvider.notifier.verifyOtp(smsCode)`. If it doesn't, here is what it should look like:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otp = '';

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    await ref.read(phoneAuthProvider.notifier).verifyOtp(_otp);
  }

  @override
  Widget build(BuildContext context) {
    // The phone number string passed from PhoneEntryScreen
    final phone = ModalRoute.of(context)!.settings.arguments as String;
    final otpState = ref.watch(phoneAuthProvider);

    ref.listen(phoneAuthProvider, (_, next) {
      if (next.otpState == OtpState.verified) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    });

    final isVerifying = otpState.otpState == OtpState.verifying;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Enter Code')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sent to ${AppConstants.countryCode}$phone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                  ),
            ),
            const SizedBox(height: 32),
            PinCodeTextField(
              appContext: context,
              length: 6,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 56,
                fieldWidth: 48,
                activeFillColor: AppColors.white,
                inactiveFillColor: AppColors.white,
                selectedFillColor: AppColors.white,
                activeColor: AppColors.primary,
                inactiveColor:
                    AppColors.textGrey.withValues(alpha: 0.4),
                selectedColor: AppColors.primary,
              ),
              enableActiveFill: true,
              onChanged: (value) => _otp = value,
              onCompleted: (_) => _verify(),
            ),
            if (otpState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                otpState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isVerifying ? null : _verify,
                child: isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Step 4.4 — Remove email/password sign-in method from Firebase Console

1. Go to **Firebase Console → Authentication → Sign-in method**
2. Disable **Email/Password** (or leave it only for admin staff login)

> **Important:** Staff login (`lib/screens/admin/staff_login_screen.dart`) uses email/password. If you disable it, staff cannot log in. Best option: Keep Email/Password enabled for admin, and also enable Phone for customers. Both can be active at the same time.

---

---

# TASK 5 — FCM Push Notifications (Post-MVP, Nice to Have)

## What this does

When an admin updates an order status (e.g. "received" → "preparing"), the customer's phone gets a push notification saying "Your order is being prepared!"

## Requirements

- Firebase Blaze plan (FCM sending from server requires Cloud Functions, which needs Blaze)
- OR use Firebase Admin SDK via a backend (not Flutter — Flutter cannot send FCM to other devices directly for security reasons)

## Recommended approach (simplest)

Use **Firebase Cloud Functions** (Node.js) that trigger on Firestore writes to the `orders` collection.

### Step 5.1 — Install Firebase CLI and create functions

```bash
npm install -g firebase-tools
firebase login
cd beruwala_pizza   # project root
firebase init functions  # choose JavaScript, install dependencies
```

### Step 5.2 — Write the function in `functions/index.js`

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onOrderStatusChange = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if status actually changed
    if (before.status === after.status) return null;

    const customerId = after.customerId;
    if (!customerId) return null;

    // Map status to human-readable message
    const messages = {
      preparing: "Your order is being prepared!",
      ready: "Your order is ready for pickup / out for delivery!",
      delivered: "Your order has been delivered. Enjoy!",
    };

    const message = messages[after.status];
    if (!message) return null;

    // Get customer's FCM token from Firestore users/{uid}
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(customerId)
      .get();

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    // Send the notification
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Beruwala Pizza",
        body: message,
      },
      data: {
        orderId: context.params.orderId,
        status: after.status,
      },
    });

    return null;
  });
```

### Step 5.3 — Save FCM token in Flutter app

In `lib/services/notification_service.dart` (create this file):

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    // Request permission (iOS requires this, Android auto-grants)
    await _messaging.requestPermission();

    // Get the FCM token for this device
    final token = await _messaging.getToken();
    if (token == null) return;

    // Save token to Firestore users/{userId}/fcmToken
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });
    });
  }
}
```

### Step 5.4 — Call `NotificationService.initialize` after login

In `lib/screens/customer/phone_entry_screen.dart` (whichever version is active), after a successful sign-in, call:

```dart
await NotificationService().initialize(user.uid);
```

### Step 5.5 — Add `fcmToken` field to Firestore `users` schema

The `users/{uid}` document needs a new optional field:
```
fcmToken: String  // device push token, updated on login
```

This field does not need to be in `UserModel` — it's only used by Cloud Functions. But do NOT add it to `UserModel.toFirestore()` as that would overwrite it on every profile update.

### Step 5.6 — Deploy

```bash
firebase deploy --only functions
```

---

---

# Reference: Key Files and What They Do

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry. Wraps in ProviderScope, initializes Firebase |
| `lib/utils/app_routes.dart` | All named routes and their builders |
| `lib/utils/app_constants.dart` | All constants: statuses, categories, currency, collection names |
| `lib/utils/app_colors.dart` | Color palette |
| `lib/providers/auth_provider.dart` | `authStateProvider`, `authServiceProvider`, `userModelProvider`, `phoneAuthProvider` |
| `lib/providers/menu_provider.dart` | `firestoreServiceProvider`, `menuItemsProvider`, `searchedMenuItemsProvider` |
| `lib/providers/cart_provider.dart` | `cartProvider`, `cartSubtotalProvider`, `cartItemCountProvider` |
| `lib/providers/order_provider.dart` | `allOrdersProvider`, `filteredOrdersProvider`, `customerOrdersProvider` (to be added) |
| `lib/services/firestore_service.dart` | All Firestore reads/writes — do NOT change method signatures |
| `lib/services/auth_service.dart` | Firebase Auth methods |
| `lib/models/order_model.dart` | `OrderModel` (id, orderNumber, customerId, status, items, total, ...) |
| `lib/models/user_model.dart` | `UserModel` (uid, name, phone, role) |
| `lib/widgets/status_badge.dart` | Reusable colored badge for order status |

---

# Reference: All Named Routes

| Constant | String | Screen | Args |
|---|---|---|---|
| `AppRoutes.splash` | `/` | SplashScreen | none |
| `AppRoutes.home` | `/home` | CustomerShell | none |
| `AppRoutes.itemDetail` | `/item-detail` | ItemDetailScreen | `MenuItemModel` object |
| `AppRoutes.cart` | `/cart` | CustomerShell | none |
| `AppRoutes.checkout` | `/checkout` | CheckoutScreen | none |
| `AppRoutes.phoneEntry` | `/phone-entry` | PhoneEntryScreen | none |
| `AppRoutes.otp` | `/otp` | OtpScreen | `String` phone number (digits only, no country code) |
| `AppRoutes.orderConfirmation` | `/order-confirmation` | OrderConfirmationScreen | `Map<String,dynamic>` with keys: `orderId` (String), `orderNumber` (int), `total` (double), `type` (String) |
| `AppRoutes.orderTracking` | `/order-tracking` | OrderTrackingScreen | `String` orderId |
| `AppRoutes.myOrders` | `/my-orders` | MyOrdersScreen | none |
| `AppRoutes.staffLogin` | `/staff-login` | StaffLoginScreen | none |
| `AppRoutes.ordersDashboard` | `/orders-dashboard` | AdminShell | none |
| `AppRoutes.orderDetail` | `/order-detail` | OrderDetailScreen | `OrderModel` object |
| `AppRoutes.menuManagement` | `/menu-management` | AdminShell | none |
| `AppRoutes.addItem` | `/add-item` | AddItemScreen | none |
| `AppRoutes.editItem` | `/edit-item` | EditItemScreen | `MenuItemModel` object |

---

# Reference: Firestore Collections

### `orders/{orderId}`
```
orderNumber: int         // 1001, 1002, ...
customerId:  String      // Firebase Auth uid
customerName: String
customerPhone: String    // "+94771234567"
type: String             // "delivery" | "pickup"
address: String          // empty string if pickup
status: String           // "received" | "preparing" | "ready" | "delivered"
note: String             // optional customer note
items: Array of {
  itemId: String
  name: String
  size: String           // "small" | "medium" | "large"
  quantity: int
  price: double          // price per unit at time of order
}
subtotal: double
deliveryFee: double      // 300.0 for delivery, 0 for pickup
total: double
createdAt: Timestamp
updatedAt: Timestamp
```

### `users/{uid}`
```
name: String
phone: String            // "+94771234567"
role: String             // "customer" | "admin"
createdAt: Timestamp
fcmToken: String         // optional, added in Task 5
```

### `menuItems/{itemId}`
```
name: String
category: String         // "Pizza" | "Sides" | "Drinks" | "Desserts"
description: String
imageUrl: String         // Firebase Storage URL or "" if no image
available: Boolean
prices: Map {
  small: double
  medium: double
  large: double
}
createdAt: Timestamp
```

---

# Reference: Color Constants (`lib/utils/app_colors.dart`)

```dart
AppColors.primary    = Color(0xFF8B1A1A)   // deep red
AppColors.accent     = Color(0xFFF5C518)   // golden yellow
AppColors.background = Color(0xFFFFF8F0)   // cream
AppColors.white      = Color(0xFFFFFFFF)
AppColors.textDark   = Color(0xFF1A1A1A)
AppColors.textGrey   = Color(0xFF888888)
AppColors.success    = Color(0xFF2E7D32)   // green
AppColors.warning    = Color(0xFFE65100)   // orange
AppColors.info       = Color(0xFF1565C0)   // blue
```

---

# Reference: Status String Constants (`lib/utils/app_constants.dart`)

```dart
AppConstants.statusReceived   = 'received'
AppConstants.statusPreparing  = 'preparing'
AppConstants.statusReady      = 'ready'
AppConstants.statusDelivered  = 'delivered'
AppConstants.currencySymbol   = 'Rs.'
AppConstants.currency         = 'LKR'
AppConstants.countryCode      = '+94'
AppConstants.deliveryFee      = 300.0
```

---

# Common Patterns Used in This Codebase

### Reading route arguments
```dart
// String argument
final orderId = ModalRoute.of(context)!.settings.arguments as String;

// Map argument
final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
final orderId = args['orderId'] as String;

// Object argument
final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
```

### Watching a StreamProvider
```dart
final ordersAsync = ref.watch(someStreamProvider);
ordersAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
  data: (items) => ListView(...),
);
```

### Watching a family StreamProvider
```dart
// provider declared as: StreamProvider.family<X, String>
final result = ref.watch(myFamilyProvider(someId));
```

### Navigation patterns
```dart
// Push a screen
Navigator.pushNamed(context, AppRoutes.myOrders);

// Push with args
Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: orderId);

// Replace all screens (go home, clear history)
Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
```

### Checking login guard
```dart
final user = ref.read(authStateProvider).valueOrNull;
if (user == null) {
  Navigator.pushNamed(context, AppRoutes.phoneEntry);
  return;
}
```

### Safe setState after async (avoid "called after dispose" error)
```dart
try {
  await someAsyncWork();
  if (!mounted) return;  // ALWAYS check mounted before setState or navigation
  setState(() => _loading = false);
} catch (e) {
  if (!mounted) return;
  setState(() => _loading = false);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

---

# Temporary Workarounds Active in the Codebase

| Workaround | File | What to Do When Fixed |
|---|---|---|
| Email/password instead of phone OTP | `lib/screens/customer/phone_entry_screen.dart` | Follow Task 4 above |
| Menu items saved with empty `imageUrl` | `lib/screens/admin/add_item_screen.dart` | Enable Firebase Storage (Blaze plan), `StorageService` is already built in `lib/services/storage_service.dart` |

---

# Final Checklist Before Launch

- [ ] Task 1: My Orders screen built and account screen updated
- [ ] Task 3: Firestore security rules applied (replace test-mode rules)
- [ ] Firebase Blaze plan enabled
- [ ] Task 4: Phone OTP flow restored
- [ ] Firebase Storage working (images upload from Add/Edit Item screens)
- [ ] Admin account created manually in Firebase Console (Authentication → Add user, then Firestore `users/{uid}` with `role: "admin"`)
- [ ] Composite Firestore index created for `menuItems` (available ASC + createdAt DESC) — click the auto-create link in Flutter error output on first run
- [ ] App tested on physical Android device (not emulator) for phone OTP
- [ ] Task 5 (optional): FCM push notifications deployed
