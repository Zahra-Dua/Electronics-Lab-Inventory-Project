# 🔧 Lab Inventory Management System

A cross-platform Flutter app that helps lab staff and admins **find any electronic component in under 10 seconds** — with a real physical storage hierarchy, live stock tracking, and AI-powered visual search.

Built as an internship project for the Engineering & Instrumentation Department.

---

## 📌 The Problem

Labs accumulate hundreds of electronic components — sensors, ICs, resistors, capacitors, dev boards — with no consistent way to:
- know **where** a component is physically stored
- know **how many** are currently available
- get notified before something runs out

This app solves that with a digital, role-based inventory system that mirrors the lab's real storage layout.

---

## ✨ Features

### 👑 Admin
- Manage staff accounts (add / edit / deactivate)
- Add & edit components with multiple photos, ABC(D) classification, and minimum stock levels
- Manage storage locations (Rack → Shelf → Box hierarchy)
- Add stock, issue, return, transfer, and mark items damaged
- Full transaction history and audit logs (who changed what, and when)
- Dashboard with live stock stats, low-stock alerts, most-used components, and recent activity
- One-click data-cleanup utility to guard against orphaned records

### 👨‍🔧 Lab Staff
- Search components by name, code, or part number
- **Search by photo** — snap a picture of an unlabeled component and get the closest inventory matches (AI-powered)
- View exact storage location and live stock for any component
- Issue and return components; view personal transaction history

### 🔐 Shared
- Role-based authentication (Admin / Lab Staff), login by email or Employee ID
- Real-time on-device notifications for low-stock / out-of-stock events
- In-app notification center

---

## 🗺️ How Storage Works

Components are never assigned directly to a rack or shelf — only to a **box**, following the real physical hierarchy:

```
Rack (A / B / C / D — matches component's ABC(D) class)
 └── Shelf
      └── Box
           └── Components live here
```

A component's ABC(D) classification automatically determines which rack it belongs to, keeping the digital layout consistent with the physical one.

---

## 🧠 AI-Powered Visual Search

Instead of typing a component's name, a user can photograph it and the app finds the closest matches:

```
Photo → CLIP image embedding → cosine similarity
       → against a Firestore-driven embedding database → ranked matches
```

- Built with **PyTorch + CLIP (Hugging Face)**, served via a **FastAPI** backend
- A Firestore real-time listener keeps the embedding database in sync automatically — new components are embedded as soon as their photos are added, no manual re-indexing required

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Auth & Database | Firebase Authentication, Cloud Firestore |
| Image Storage | Supabase Storage |
| Local Notifications | `flutter_local_notifications` |
| AI Visual Search | Python, FastAPI, PyTorch, CLIP (`openai/clip-vit-base-patch32`) |

---

## 📂 Project Structure

```
lib/
├── models/          # Data models (User, Component, Location, Inventory, Transaction, ...)
├── services/        # Firestore / Supabase / Storage service classes
├── providers/        # App-wide state (AuthProvider)
├── screens/
│   ├── admin/       # Admin dashboard, component/location/staff management
│   ├── lab_staff/   # Lab staff dashboard, search, history
│   └── ...          # Shared screens (login, signup, image search, notifications)
├── widgets/          # Reusable widgets (e.g. cascading location picker, stock watcher)
└── constants/        # Dropdown options, enums, config

component_ai_search/  # Python AI backend (CLIP embeddings + FastAPI search API)
├── api_server.py
├── build_embeddings.py
└── requirements.txt
```

---

## 🚀 Getting Started

### Flutter app
```bash
flutter pub get
flutter run
```
Configure Firebase (`flutterfire configure`) and add your Supabase project URL + anon key in `main.dart` before running.

### AI backend
```bash
cd component_ai_search
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt
python -m uvicorn api_server:app --host 0.0.0.0 --port 8000
```
Add your Firebase `serviceAccountKey.json` to this folder (never commit it — see `.gitignore`).

---

## 🔮 Planned Enhancements

- **QR Code Scanning** — scan a component or box QR code instead of searching manually
- **Project-wise Inventory Tracking** — link issued components to specific projects, so admins can see exactly what each project used
- Exportable stock/usage reports
- Push notifications (Firebase Cloud Messaging) once on a paid Firebase tier
- Supplier management module

---

## 🔒 Security Notes

- Firestore access is fully role-gated via Security Rules (Admin vs Lab Staff vs unauthenticated)
- `serviceAccountKey.json` and `.venv/` are git-ignored — never commit credentials
- Transaction and audit logs are append-only (no update/delete allowed) for accountability

---
