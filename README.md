# ✝ ChurchConnect

> **Connecting the Body of Christ** — A Digital Church Management System

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=flat&logo=firebase)
![Paystack](https://img.shields.io/badge/Payments-Paystack-00C3F7?style=flat)
![Brevo](https://img.shields.io/badge/Email-Brevo-0B996E?style=flat)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

---

## 📱 Live Demo

🌐 **Web App:** [https://church-management-system-d7d3a.web.app](https://church-management-system-d7d3a.web.app)

---

## 📖 About

**ChurchConnect** is a full-stack mobile and web application built with Flutter that helps churches in Ghana digitally manage their members, collect dues and contributions online, and communicate with members automatically.

This project was developed as an **IT Capstone Project** at the **University of Cape Coast, Ghana** by **Lawrence Koomson** (Level 400, BSc Information Technology).

---

## 🎯 Problem Statement

Most churches in Ghana still manage their member records, dues collection and communications manually. This leads to:

- Lost or inaccurate member records
- Difficulty tracking dues payments
- Poor communication between church and members
- No digital payment options for members
- Manual and time-consuming administrative work

---

## ✅ Solution

ChurchConnect provides a complete digital platform where:

- Members can **register and manage their profiles** online
- Members can **pay dues and contributions** using Mobile Money or bank cards
- Members receive **automatic email notifications** for payments and events
- The church admin can **create and announce events** to all members instantly
- Member records are **automatically synced** to Google Sheets for easy review
- **Overdue reminders** are sent automatically to members who have not paid
- **Birthday wishes** are sent automatically to members on their birthdays

---

## 🚀 Features

### Member Features
- ✅ Register and create a personal church profile
- ✅ Login with email and password
- ✅ Forgot password via email reset
- ✅ Personalized dashboard with dues status
- ✅ Make real payments via Paystack (MTN MoMo, Vodafone Cash, AirtelTigo, Bank Cards)
- ✅ View payment history and giving summary
- ✅ Download digital membership ID card (PDF)
- ✅ View upcoming church events
- ✅ Receive payment confirmation emails
- ✅ Receive event announcement emails
- ✅ Receive birthday wishes on their birthday
- ✅ Receive overdue dues reminders

### Admin Features
- ✅ Create and manage church events
- ✅ Send event announcements to all members automatically
- ✅ Automatic overdue member detection and reminders
- ✅ View all member records in Google Sheets

---

## 🛠 Tech Stack

| Technology | Purpose |
|---|---|
| **Flutter** | Mobile & Web App (iOS, Android, Web) |
| **Firebase Auth** | User Authentication |
| **Cloud Firestore** | Real-time Database |
| **Paystack** | Payment Processing (Ghana MoMo & Cards) |
| **Brevo (Sendinblue)** | Email Notifications |
| **Google Sheets API** | Financial Record Keeping |
| **Google Apps Script** | Birthday Automation & Sheets Web API |
| **Zapier** | Welcome Email Automation |
| **Firebase Hosting** | Web App Deployment |
| **Claude AI** | AI-Assisted Development |

---

## 📧 Automated Workflows

| Workflow | Trigger | Tool |
|---|---|---|
| Welcome Email | New member registers | Brevo |
| Payment Confirmation | Payment verified | Brevo |
| Event Announcement | Admin creates event | Brevo |
| Dues Reminder | Admin logs in (monthly) | Brevo |
| Birthday Wishes | Member's birthday (8am daily) | Google Apps Script |
| Google Sheets Sync | Any action | Apps Script API / gsheets |

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry point & routing
├── firebase_options.dart        # Firebase configuration (not in repo)
├── models/
│   ├── member_model.dart        # Member data model
│   ├── payment_model.dart       # Payment data model
│   └── event_model.dart         # Event data model
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Login screen
│   │   └── register_screen.dart # Registration screen
│   ├── member/
│   │   ├── member_dashboard_screen.dart
│   │   ├── payment_screen.dart
│   │   ├── payment_history_screen.dart
│   │   ├── giving_summary_screen.dart
│   │   ├── id_card_screen.dart
│   │   └── profile_screen.dart
│   └── events/
│       ├── events_screen.dart
│       └── add_event_screen.dart
├── services/
│   ├── email_service.dart       # Brevo email service (not in repo)
│   ├── paystack_service.dart    # Paystack payment service (not in repo)
│   ├── sheets_service.dart      # Google Sheets service (not in repo)
│   ├── overdue_service.dart     # Automatic overdue detection
│   ├── notification_service.dart
│   ├── pdf_service.dart         # PDF receipt & ID card generation
│   └── event_service.dart
├── utils/
│   ├── app_colors.dart          # App color constants
│   └── app_constants.dart       # App-wide constants
└── widgets/
    ├── app_logo.dart            # ChurchConnect logo widget
    └── theme_switcher.dart
```

---

## ⚙️ Setup Instructions

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio or VS Code
- Firebase account
- Paystack account (Ghana)
- Brevo account
- Google Cloud account

### 1. Clone the repository
```bash
git clone https://github.com/lawrykoomson/church-connect.git
cd church-connect
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
```bash
flutterfire configure
```
Select your Firebase project and follow the prompts.

### 4. Create sensitive service files

Create the following files which are not included in the repository:

**lib/firebase_options.dart** — Generated by FlutterFire CLI

**lib/services/email_service.dart** — Add your Brevo API key:
```dart
static const String _apiKey = 'YOUR_BREVO_API_KEY';
```

**lib/services/paystack_service.dart** — Add your Paystack secret key:
```dart
static const String _secretKey = 'YOUR_PAYSTACK_SECRET_KEY';
```

**lib/services/sheets_service.dart** — Add your Google Service Account credentials and Sheets ID.

**android/app/google-services.json** — Download from Firebase console.

### 5. Run the app

**Chrome (Web):**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d YOUR_DEVICE_ID
```

### 6. Deploy to Firebase Hosting
```bash
flutter build web --release
firebase deploy --only hosting
```

---

## 🔒 Security

- All API keys and credentials are stored locally and **never committed to version control**
- Firebase Authentication handles all password management securely
- Paystack processes all payments — card/MoMo details never touch our servers
- Firestore security rules require authentication for all data access

---

## 📊 Grading Criteria (Capstone)

| Criterion | Weight | Focus |
|---|---|---|
| Problem & Solution Design | 20% | Clear problem identification, appropriate solution |
| Technical Implementation | 30% | Quality of prompts, Zapier, course concepts |
| Functionality | 25% | Solution works as intended |
| Documentation | 15% | User guide, setup instructions, ethical considerations |
| Presentation | 10% | Effective demonstration, clear communication |

---

## 🤝 Ethical Considerations

- **Data Privacy** — Minimum necessary data collected and stored securely
- **Financial Transparency** — All payments verified by Paystack before recording
- **Responsible AI** — Claude AI used for development assistance; all code reviewed by developer
- **Inclusion** — App works on both phone and web browser
- **Sustainability** — Paperless system eliminates printed records and receipts

---

## 👨‍💻 Developer

**Lawrence Koomson**
- 📧 Email: koomsonlawrence64@gmail.com
- 📱 Phone: +233 54 634 5865
- 🐙 GitHub: [github.com/lawrykoomson](https://github.com/lawrykoomson)
- 🏫 Institution: University of Cape Coast, Ghana
- 📚 Programme: BSc Information Technology, Level 400
- 📅 Year: 2026

---

## 📄 License

This project is licensed under the MIT License.

---

> *"Connecting the Body of Christ through technology"*
> — ChurchConnect, 2026
