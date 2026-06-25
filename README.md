<p align="center">
  <img src="documentation/logo.png" alt="Eazzio-Books Logo" width="320"/>
</p>

# Eazzio-Books — Mobile App

### A Flutter-based mobile companion for the Eazzio-Books accounting platform.

![Stack](https://img.shields.io/badge/Stack-Flutter%20%2B%20Dart-blue)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS-purple)
![License](https://img.shields.io/badge/License-Proprietary-red)

---

## 📖 About

The **Eazzio-Books Mobile App** (`mobile_books`) is a cross-platform mobile companion built with **Flutter** that mirrors and extends the core functionality of the main Eazzio-Books web application. It provides business owners and accounting staff with on-the-go access to financial data, invoices, reports, and customer management directly from their mobile devices.

---

## ✨ Key Features

- **Dashboard** — Real-time financial overview with fl_chart visualizations
- **Customer & Vendor Management** — Search, view, and manage contacts
- **Sales & Purchases** — Create and track quotes, invoices, bills, and payments
- **Inventory** — View stock levels and item details
- **Reports** — Profit & Loss, Balance Sheet, Trial Balance, and aging reports
- **Banking** — Account overview and transaction tracking
- **Document Attachments** — Upload and download files from mobile
- **Role-Based Access** — Admin, Accountant, Staff, Viewer roles
- **Dark Mode** — Full theme support

---

## 🛠️ Technology Stack

| Layer        | Technology                               |
| ------------ | ---------------------------------------- |
| Framework    | Flutter                                  |
| Language     | Dart                                     |
| State Mgmt   | Riverpod                                 |
| Navigation   | GoRouter                                 |
| HTTP Client  | Dio + CookieJar                          |
| Charts       | fl_chart                                 |
| PDF          | printing                                 |
| Storage      | flutter_secure_storage, shared_preferences |
| Fonts        | Google Fonts                             |
| Local Env    | flutter_dotenv                           |

---

## 🏗️ Project Structure

```
mobile-books/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── navigation/
│   │   ├── network/
│   │   ├── theme/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── customers/
│   │   ├── vendors/
│   │   ├── sales/
│   │   ├── purchases/
│   │   ├── inventory/
│   │   ├── banking/
│   │   ├── reports/
│   │   └── settings/
│   ├── shared/
│   │   ├── widgets/
│   │   └── models/
│   └── main.dart
├── assets/
│   └── images/
├── test/
├── android/
├── ios/
├── macos/
├── pubspec.yaml
└── .env
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.12.2`
- Dart `^3.12.2`
- Android Studio / Xcode (for platform builds)
- A running instance of the Eazzio-Books backend API

### Setup

```bash
git clone https://github.com/Eazzio-Technologies-Pvt-Ltd/Eazzio-Books.git
cd Eazzio-Books/mobile-books
```

Create a `.env` file in `mobile-books/`:

```env
API_BASE_URL=http://localhost:5000/api
```

Install dependencies and run:

```bash
flutter pub get
flutter run
```

---

## 📄 License

Proprietary software. Unauthorized copying, modification, distribution, or use without permission is strictly prohibited.

---

Made with ❤️ by the Eazzio-Books Development Team
