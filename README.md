# 🍔 Krave - The Ultimate Canteen Pre-ordering App

**Krave** is a modern, full-featured Flutter application designed to revolutionize the campus dining experience. It bridges the gap between hungry students/staff and canteen owners by enabling seamless pre-ordering, real-time tracking, and efficient order management.

---

## 🌟 Key Features

### 👤 For Users (Students/Staff)
*   **Secure Authentication**: Easy sign-up and login using Email & Password.
*   **Smart Search**: Instantly find canteens or specific food items using the powerful search bar.
*   **Visual Menu**: Browse mouth-watering menus with high-quality images and clear **Veg/Non-Veg** indicators.
*   **Cart Management**: Add multiple items, adjust quantities, and view a detailed bill summary before checkout.
*   **Seamless Payments**: Integrated **Razorpay** payment gateway for secure transactions (currently in Test Mode).
*   **Live Order Tracking**: Watch your order status change in real-time:
    *   ⏳ **Pending**: Order sent to canteen.
    *   👨‍🍳 **Preparing**: Food is being cooked.
    *   ✅ **Ready**: Pick up your food!
    *   🏁 **Completed**: Order finished.
*   **Order History**: Access past orders and download PDF invoices for expense tracking.

### 🏪 For Canteen Owners
*   **Business Dashboard**: Get a bird's-eye view of your business with daily stats:
    *   Total Pending Orders
    *   Orders In-Progress
    *   Today's Revenue
    *   Completed Orders Count
*   **Menu Control**: Full control to **Add**, **Edit**, or **Delete** menu items. Set prices, categories, and upload images.
*   **Order Management**: Accept incoming orders with a single tap. Update status to "Preparing" and "Ready" to notify users.
*   **Store Timings**: Easily manage opening and closing hours directly from the app.

### 🛡️ For Admins
*   **Quality Control**: Review new canteen registration requests.
*   **Approval System**: Approve valid canteens to go live or reject invalid ones.
*   **Revocation**: Maintain platform quality by removing canteens that violate policies.

---

## 📱 App Flow & Screenshots

1.  **Onboarding**: Users sign up and choose their role (User or Canteen Owner).
2.  **Home Screen**: Users see a list of approved canteens. Owners see their dashboard.
3.  **Ordering**: Users select a canteen -> Add items -> Pay via Razorpay.
4.  **Fulfillment**: Owner receives order -> Starts preparing -> Marks as Ready.
5.  **Pickup**: User shows the **Token Number** to the canteen owner to collect food.

---

## 🛠️ Technical Architecture

Krave is built with a robust tech stack ensuring scalability and performance:

*   **Frontend Framework**: [Flutter](https://flutter.dev/) (Dart) - For cross-platform native performance.
*   **Backend & Database**: [Firebase](https://firebase.google.com/)
    *   **Firestore**: Real-time NoSQL database for syncing orders and menus.
    *   **Firebase Auth**: Secure user authentication.
    *   **Cloud Functions**: Serverless backend logic (optional/future).
*   **State Management**: [Provider](https://pub.dev/packages/provider) - For efficient state handling.
*   **Payment Gateway**: [Razorpay](https://razorpay.com/) - For handling payments.
*   **UI Design**: Custom **Glassmorphism** aesthetic, **Shimmer** loading effects, and **Google Fonts** (Outfit).

---

## 🚀 Installation & Setup Guide

Follow these steps to run Krave on your local machine.

### Prerequisites
1.  **Flutter SDK**: Ensure you have Flutter installed (`flutter doctor`).
2.  **Dart SDK**: Included with Flutter.
3.  **Firebase Account**: You need a Firebase project.

### Step 1: Clone the Repository
```bash
git clone https://github.com/yourusername/krave.git
cd krave
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Configuration
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Create a new project.
3.  **Enable Authentication**: Go to Build -> Authentication -> Sign-in method -> Enable **Email/Password**.
4.  **Create Database**: Go to Build -> Firestore Database -> Create Database.
    *   Start in **Test Mode** for development.
5.  **Add App**: Register an Android/iOS app in Firebase settings.
6.  **Download Config**:
    *   For Android: Download `google-services.json` and place it in `android/app/`.
    *   For iOS: Download `GoogleService-Info.plist` and place it in `ios/Runner/`.

### Step 4: Run the App
Connect your device or start an emulator, then run:
```bash
flutter run
```

---

## � Project Structure Explained

Here is a quick guide to the codebase to help you navigate:

*   **`lib/main.dart`**: The entry point of the application. Sets up themes and providers.
*   **`lib/src/models/`**: Data classes (POJOs) defining the structure of `User`, `Canteen`, `Order`, and `MenuItem`.
*   **`lib/src/screens/`**:
    *   **`auth/`**: Login and Signup screens.
    *   **`user/`**: Screens for the customer app (Home, Menu, Cart, Order History).
    *   **`owner/`**: Screens for the canteen manager (Dashboard, Manage Menu, Live Orders).
    *   **`admin/`**: Screens for the super admin (Approve/Revoke Canteens).
*   **`lib/src/services/`**:
    *   **`auth_service.dart`**: Handles Login, Signup, and Logout.
    *   **`firestore_service.dart`**: The core data layer. Handles all database CRUD operations.
    *   **`cart_provider.dart`**: Manages the shopping cart state locally.
*   **`lib/src/widgets/`**: Reusable UI components like `RestaurantCard`, `GlassContainer`, and `GradientBackground`.

---

## ❓ Troubleshooting

*   **Build Errors?**
    *   Run `flutter clean` and then `flutter pub get`.
    *   Ensure your Kotlin version in `android/build.gradle` matches the Flutter requirements.
*   **Firebase Errors?**
    *   Double-check that `google-services.json` is in the correct folder.
    *   Ensure your Firestore Security Rules allow read/write for development.

---

## 🔮 Future Roadmap

*   [ ] Push Notifications for order updates.
*   [ ] Rating and Review system for canteens.
*   [ ] Wallet system for quicker payments.
*   [ ] Dark/Light mode toggle.

---

**Developed with ❤️ by the Krave Team**
