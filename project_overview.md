# Project Overview: Krave

This document provides a technical summary of the **Krave** project, designed to help you showcase the application during interviews. It covers the technology stack, architecture, state management, API structure, and key features.

## 1. Technology Stack

### Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **UI Design**: Material 3 Design with a custom "Professional Dark" theme (Amber/Orange primary, Deep Dark Blue background).
- **Fonts**: Google Fonts (Outfit).

### Backend (Serverless)
- **Platform**: [Firebase](https://firebase.google.com/)
- **Logic**: Firebase Cloud Functions (Node.js 22)
- **Database**: Cloud Firestore (NoSQL)
- **Storage**: Firebase Storage (Images/Media)
- **Authentication**: Firebase Authentication
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Third-Party Integrations
- **Payments**: Razorpay (via `razorpay_flutter` and Cloud Functions)
- **PDF Generation**: `pdf` and `printing` packages

## 2. Architecture & State Management

### State Management: `Provider`
The application uses the **Provider** package for dependency injection and state management.
- **`MultiProvider` (at Root)**: Initializes and provides global services (`AuthService`, `FirestoreService`) and state (`CartProvider`) to the entire widget tree.
- **`ChangeNotifier`**: Used for mutable state, specifically in `CartProvider` to handle shopping cart updates (add/remove items, update totals) and notify listeners to rebuild UI.
- **`Streams`**: Used heavily for real-time data sync (e.g., `auth.authStateChanges()` for login sessions, Firestore streams for order updates).

### Navigation
- **Type**: Standard Flutter Navigator (Named Routes).
- **Setup**: defined in `MaterialApp` routes.
  - `/login` -> `LoginScreen`
  - `/user_home` -> `UserHome`
  - `/admin_home` -> `AdminHome`
- **Dynamic Routing**: The `Root` widget acts as an auth-gate. It listens to the auth stream and user role to dynamically redirect users to the correct home screen (User, Admin, or Owner).

## 3. API & Data Flow

### Communication Methods
1.  **Direct Firestore Access (Frontend)**:
    - The app reads/writes directly to Firestore for standard CRUD operations (e.g., fetching menu items, updating user profile) using `FirestoreService`.
    - **Security**: Secured via Firestore Security Rules (implied).

2.  **Cloud Functions (Backend logic)**:
    - **Triggers**: Automatic background functions that react to database changes.
        - `onOrderCreated`: Notifies the canteen owner via FCM when a new order is placed.
        - `onOrderStatusUpdate`: Notifies the user via FCM when their order status changes.
        - `onOwnerCreated`: Notifies admins when a new canteen owner signs up.
        - `onOwnerDelete`: Cleans up Auth users when an Owner document is deleted.
    - **Callable Functions (HTTPS)**: Secure endpoints called directly from the Flutter app.
        - `createRazorpayOrder`: Securely initiates a payment order on the server.
        - `confirmRazorpayPayment`: Verifies payment signature and finalizes the transaction.

### REST API
While the project primarily uses Firebase SDKs, it engages with REST concepts via:
- **Cloud Functions**: The Callable functions effectively act as secure API endpoints.
- **Razorpay Integration**: The backend communicates with Razorpay's REST API to create orders and verify payments.

## 4. Key Features to Highlight

- **Role-Based Access Control (RBAC)**: Distinct flows for Users, Canteen Owners, and Admins, managed via a single codebase and dynamic routing.
- **Real-Time Updates**: UI updates instantly when orders change status, leveraging Firestore implementation.
- **Serverless Architecture**: Scalable backend without managing servers.
- **Secure Payments**: Payment processing is handled securely on the backend (Cloud Functions) to prevent client-side tampering.
- **Automated Notifications**: User engagement is driven by event-triggered push notifications.

## 5. Directory Structure (`lib/`)

- **`src/config.dart`**: App-wide configuration.
- **`src/services/`**: Core logic layers.
  - `auth_service.dart`: Wraps Firebase Auth.
  - `firestore_service.dart`: Wraps Cloud Firestore interactions.
  - `cart_provider.dart`: Business logic for the shopping cart.
- **`src/screens/`**: UI screens, organized by role (`user`, `owner`, `admin`) and feature (`auth`).
- **`src/widgets/`**: Reusable UI components.
- **`src/models/`**: Data models (implied POJOs for User, Order, FoodItem).
