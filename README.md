# 🍔 Krave — Campus Canteen Pre-ordering Platform

**Krave** is a full-stack, multi-app Flutter platform that revolutionizes campus dining. It connects students, canteen owners, and delivery riders through a seamless ecosystem of pre-ordering, real-time tracking, and intelligent order management — all powered by a serverless Firebase backend.

---

## 📦 Repository Structure

This is a **mono-repo** containing three distinct Flutter applications sharing a common core library:

```
krave/
├── lib/                   # 📱 Main App (Students, Owners, Admins)
├── rider_app/             # 🛵 Rider App (Delivery Riders)
├── functions/             # ☁️  Firebase Cloud Functions (Node.js)
├── admin-portal/          # 🖥️  Admin Web Portal
├── assets/                # 🖼️  Shared Assets
└── firestore.rules        # 🔒  Firestore Security Rules
```

---

## 🌟 Features

### 👤 For Students / Staff
- **Secure Authentication** — Email/Password & **Google Sign-In**
- **Smart Search** — Instantly find canteens or food items
- **Visual Menu** — Browse menus with high-quality images, Veg/Non-Veg indicators, and real-time availability
- **Cart Management** — Add items, adjust quantities, and view a detailed bill before checkout
- **Seamless Payments** — **Razorpay** integration for secure transactions
- **Live Order Tracking** — Real-time status updates:
  - ⏳ **Pending** → 👨‍🍳 **Preparing** → ✅ **Ready** → 🏁 **Completed**
- **Order History** — View past orders and download **PDF invoices**
- **Transfer / Wallet** — Internal money transfer functionality
- **Help & Support** — In-app support screen
- **Profile Management** — Full profile editing with image upload

### 🏪 For Canteen Owners
- **Business Dashboard** — Daily stats: Pending Orders, In-Progress, Revenue, Completed
- **Menu Control** — Add, Edit, Delete items with image upload, categories, and pricing
- **Live Order Management** — Accept orders, update to Preparing/Ready with one tap
- **Store Timings** — Manage opening/closing hours

### 🛵 For Delivery Riders
A **dedicated companion app** (`rider_app/`) with its own onboarding and workflow:
- **Multi-Stage Onboarding** — 6-step KYC & verification flow:
  1. Basic Profile
  2. KYC Documents
  3. Identity Verification
  4. Training Module
  5. Agreement Signing
  6. Success / Activation
- **Home Dashboard** — View and accept available delivery orders
- **Order Detail Screen** — Navigate, complete, or report delivery issues
- **Delivery History** — Track all completed and past deliveries
- **Profile Management** — Manage rider profile with document uploads

### 🛡️ For Admins
- **Canteen Approval** — Review and approve/reject new canteen registrations
- **Revocation** — Remove canteens that violate platform policies
- **Admin Web Portal** — Separate web-based admin panel (`admin-portal/`)

---

## 🛠️ Technical Architecture

### Frontend
| App | Framework | State Management |
|-----|-----------|-----------------|
| Main App | Flutter (Dart) | Provider |
| Rider App | Flutter (Dart) | Provider |
| Admin Portal | Web | — |

### Backend (Serverless Firebase)
| Service | Purpose |
|---------|---------|
| **Firebase Auth** | User authentication (Email/Password + Google) |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Storage** | Image & document uploads |
| **Firebase Messaging** | Push notifications (FCM) |
| **Cloud Functions** | Serverless backend (Node.js 22) |
| **Firebase App Check** | API abuse prevention |

### Third-Party Integrations
| Integration | Purpose |
|-------------|---------|
| **Razorpay** | Payment gateway (order creation + verification) |
| **Google Sign-In** | OAuth authentication |
| **Google Fonts (Outfit)** | Typography |
| **QR Flutter** | QR / Token code generation |

---

## ☁️ Cloud Functions

The `functions/` directory contains the serverless backend logic:

| Function | Trigger | Description |
|----------|---------|-------------|
| `onOrderCreated` | Firestore trigger | Notifies canteen owner via FCM on new order |
| `onOrderStatusUpdate` | Firestore trigger | Notifies user when order status changes |
| `onOwnerCreated` | Firestore trigger | Alerts admins when a new canteen owner registers |
| `onOwnerDelete` | Firestore trigger | Cleans up Auth users on owner document deletion |
| `createRazorpayOrder` | HTTPS Callable | Securely creates a Razorpay payment order |
| `confirmRazorpayPayment` | HTTPS Callable | Verifies payment signature and finalizes transaction |

---

## 📂 Main App — Directory Structure (`lib/`)

```
lib/
├── main.dart
└── src/
    ├── config.dart
    ├── models/
    │   ├── user_model.dart
    │   ├── order_model.dart
    │   ├── canteen_model.dart
    │   └── food_item_model.dart
    ├── services/
    │   ├── auth_service.dart          # Firebase Auth wrapper
    │   ├── firestore_service.dart     # Core Firestore CRUD
    │   ├── cart_provider.dart         # Shopping cart state
    │   ├── user_provider.dart         # User profile state
    │   ├── payment_service.dart       # Razorpay payment logic
    │   ├── storage_service.dart       # Firebase Storage uploads
    │   ├── notification_service.dart  # FCM + local notifications
    │   ├── functions_service.dart     # Cloud Functions callable
    │   ├── pdf_invoice_service.dart   # PDF invoice generation
    │   ├── pdf_service.dart           # Generic PDF utilities
    │   ├── image_search_service.dart  # Image search/fetch
    │   └── watchdog_service.dart      # Background health checks
    ├── screens/
    │   ├── auth/                      # Login & Signup
    │   ├── user/                      # Student screens
    │   │   ├── user_home.dart
    │   │   ├── canteen_menu.dart
    │   │   ├── cart_screen.dart
    │   │   ├── order_tracking.dart
    │   │   ├── order_history.dart
    │   │   ├── profile_screen.dart
    │   │   ├── account_settings.dart
    │   │   ├── transfer_money_screen.dart
    │   │   └── help_support.dart
    │   ├── owner/                     # Canteen owner screens
    │   └── admin/                     # Admin screens
    └── widgets/                       # Reusable UI components
```

---

## 🛵 Rider App — Directory Structure (`rider_app/`)

```
rider_app/
└── lib/
    ├── main.dart
    └── src/
        ├── models/
        ├── providers/
        ├── services/
        ├── theme/
        ├── widgets/
        └── screens/
            ├── login_screen.dart
            ├── home_screen.dart
            ├── order_detail_screen.dart
            ├── history_screen.dart
            ├── profile_screen.dart
            └── onboarding/
                ├── stage1_basic_profile_screen.dart
                ├── stage2_kyc_screen.dart
                ├── stage3_verification_screen.dart
                ├── stage4_training_screen.dart
                ├── stage5_agreement_screen.dart
                └── stage6_success_screen.dart
```

> The Rider App depends on `krave` as a local path package to share models and Firebase config.

---

## 🚀 Installation & Setup

### Prerequisites
- **Flutter SDK** `>=3.9.2 <4.0.0` — verify with `flutter doctor`
- **Node.js** `>=18` — for Cloud Functions
- **Firebase CLI** — `npm install -g firebase-tools`
- **Firebase Account** with a configured project

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/krave.git
cd krave
```

### 2. Install Dependencies

**Main App:**
```bash
flutter pub get
```

**Rider App:**
```bash
cd rider_app && flutter pub get
```

**Cloud Functions:**
```bash
cd functions && npm install
```

### 3. Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable **Authentication** → Email/Password + Google
3. Create **Firestore Database** (Test Mode for dev)
4. Enable **Firebase Storage**
5. Enable **Firebase Cloud Messaging**
6. Register your Android/iOS apps and download config files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

### 4. Environment Variables

Create a `.env` file at the root (already gitignored):
```env
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
```

### 5. Deploy Cloud Functions
```bash
firebase deploy --only functions
```

### 6. Run the Apps

**Main App:**
```bash
flutter run
```

**Rider App:**
```bash
cd rider_app && flutter run
```

---

## 📦 Key Dependencies

### Main App
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.0.0 | Firebase initialization |
| `firebase_auth` | ^5.0.0 | Authentication |
| `cloud_firestore` | ^5.0.0 | Real-time database |
| `firebase_storage` | ^12.0.0 | File/image storage |
| `firebase_messaging` | ^15.0.0 | Push notifications |
| `cloud_functions` | ^5.0.0 | Serverless backend calls |
| `firebase_app_check` | ^0.3.2 | API abuse prevention |
| `provider` | ^6.0.5 | State management |
| `razorpay_flutter` | ^1.3.6 | Payment gateway |
| `google_sign_in` | ^6.2.1 | Google OAuth |
| `qr_flutter` | ^4.1.0 | Token QR code generation |
| `pdf` / `printing` | ^3.10 / ^5.13 | PDF invoice generation |
| `flutter_animate` | ^4.5.0 | Animations |
| `shimmer` | ^3.0.0 | Loading skeletons |
| `google_fonts` | ^6.2.1 | Outfit typography |
| `cached_network_image` | ^3.3.0 | Image caching |
| `geolocator` | ^13.0.1 | Location services |
| `image_picker` | ^1.1.2 | Camera/gallery upload |
| `file_picker` | ^8.1.4 | Document uploads |

### Rider App (additional)
| Package | Version | Purpose |
|---------|---------|---------|
| `pinput` | ^6.0.2 | OTP/PIN input UI |
| `lottie` | ^3.3.2 | Lottie animations |
| `shared_preferences` | ^2.3.2 | Local persistent storage |

---

## 🔮 Roadmap

- [x] Core ordering flow (User → Owner)
- [x] Razorpay payment integration
- [x] Real-time order tracking
- [x] PDF invoice generation
- [x] Rider App with KYC onboarding
- [x] Google Sign-In
- [x] QR token system
- [ ] Push Notifications for all roles
- [ ] Rating & Review system
- [ ] Krave Wallet (internal balance)
- [ ] Dark / Light mode toggle
- [ ] Rider GPS live tracking
- [ ] Canteen analytics dashboard

---

## ❓ Troubleshooting

| Issue | Solution |
|-------|---------|
| Build errors | Run `flutter clean && flutter pub get` |
| Firebase errors | Ensure `google-services.json` / `GoogleService-Info.plist` are in place |
| Kotlin version mismatch | Update `android/build.gradle` Kotlin version |
| Functions deployment fails | Verify Node.js version and `firebase login` status |
| Razorpay errors | Confirm `.env` keys and ensure test/live mode matches |

---

## 📄 License

Private & Proprietary — All Rights Reserved.

---

**Developed with ❤️ by the Krave Team**
