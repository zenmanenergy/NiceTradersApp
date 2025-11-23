# NICE Traders

**Neighborhood International Currency Exchange**

A community-powered mobile platform that connects travelers who need foreign currency with neighbors who have extra cash from their trips. Exchange safely, conveniently, and affordably—right in your own community.

---

## 🌍 What It Does

NICE Traders solves a simple problem:

- **You just returned from Europe** with leftover Euros
- **Your neighbor is leaving for Paris next week** and needs Euros
- Traditional currency exchanges charge 10-25% in fees
- Banks require appointments and may not have the currency in stock

NICE Traders connects you both. You meet at a safe public location, exchange cash, and each pay just $1 to use the platform.

---

## 💡 Why It Exists

Every year, millions of travelers:
- Return home with unused foreign cash that sits in drawers
- Pay excessive fees at airport kiosks (10-25%)
- Struggle to find local currency before trips
- Wait days for bank currency orders

**NICE Traders** turns neighborhoods into micro foreign-exchange networks, eliminating fees, delays, and waste.

---

## 🚀 How It Works

1. **List Currency** - Returning traveler lists leftover foreign cash (EUR, GBP, JPY, etc.)
2. **Search & Find** - Departing traveler searches for nearby currency on a map
3. **Connect** - Both users pay $1 to unlock messaging and negotiate details
4. **Meet Safely** - Exchange cash at a suggested safe public location
5. **Rate & Trust** - Both users rate the experience, building community trust

---

## ✨ Key Features

### Core Platform
- 🗺️ **Map-based listing system** - Find currency near you
- 💬 **Secure messaging** - Unlocked after commitment fee
- ⭐ **User ratings** - Build trust like Uber/Airbnb
- 📍 **Safe meet-up suggestions** - Public locations recommended
- 💱 **Live exchange rates** - Fair market pricing

### Native Mobile Features
- 📱 **GPS location services** - Automatic location detection
- 🔔 **Push notifications** - Get notified of nearby matches
- 📸 **QR code verification** - Confirm exchanges securely
- 🔒 **Secure authentication** - Protected user data
- 🌐 **Multi-currency support** - 100+ currencies available

---

## 🏗️ Architecture

### Three-Phase Development Strategy

#### **Phase 1: Browser Prototype** ✅ Complete
Built the entire app using web technologies to rapidly prototype UX and API integration.

**Stack:**
- Svelte + SvelteKit
- Python Flask backend
- MySQL database
- Mobile-first responsive design

#### **Phase 2: iOS Native App** 🚧 In Progress
Converting the web prototype to a full native iOS application.

**Stack:**
- SwiftUI (iOS 17+)
- URLSession networking
- CoreLocation for GPS
- Keychain for secure storage
- MapKit integration (planned)

#### **Phase 3: Android Native App** 📋 Planned
Port iOS app to native Android using Jetpack Compose.

**Stack:**
- Jetpack Compose
- Kotlin coroutines
- Retrofit/Ktor networking
- Google Maps SDK
- Firebase Push Notifications

---

## 🛠️ Technology Stack

### Backend
- **Language:** Python 3.x
- **Framework:** Flask
- **Database:** MySQL
- **API:** RESTful endpoints
- **Authentication:** Session-based with UserDefaults

### Frontend - Web (Phase 1)
- **Framework:** Svelte + SvelteKit
- **Styling:** Custom CSS with mobile-first design
- **Maps:** Google Maps JavaScript API
- **State:** Svelte stores
- **Build:** Vite

### Frontend - iOS (Phase 2)
- **Language:** Swift 5.x
- **Framework:** SwiftUI
- **Minimum iOS:** 17.0
- **Architecture:** MVVM pattern
- **Navigation:** NavigationStack
- **Async:** async/await with URLSession

---

## 📁 Project Structure

```
NiceTradersApp/
├── Client/
│   ├── Browser/          # Svelte web app (Phase 1)
│   └── IOS/              # Swift iOS app (Phase 2)
├── Server/               # Python Flask backend
├── Documentation/        # Project documentation
└── README.md            # This file
```

---

## 🎯 Target Users

- **International travelers** returning with leftover cash
- **Business travelers** needing quick currency access
- **Students abroad** exchanging between trips
- **Airport-area residents** with frequent access to currency
- **Expat communities** with regular currency needs

---

## 💰 Business Model

- **$1 per user per transaction** ($2 total per exchange)
- No percentage-based fees
- No hidden charges
- Fair market exchange rates
- Revenue from volume, not margins

---

## 🔒 Safety & Trust

- User rating system (like Uber/Airbnb)
- Suggested safe public meeting locations
- Optional identity verification
- Message history for accountability
- Community-driven trust network

---

## 🌐 Website

[http://nicetraders.net](http://nicetraders.net)

---

## 📄 License

Copyright © 2025 NICE Traders. All rights reserved.

---

## 👥 Contributing

This is currently a private project. For questions or collaboration inquiries, please contact the repository owner.

---

## 🗺️ Roadmap

### ✅ Completed
- [x] Web prototype with full user flow
- [x] Backend API with all endpoints
- [x] User authentication system
- [x] Listing creation and search
- [x] iOS app core functionality
- [x] Native flag images in iOS
- [x] Automatic location detection

### 🚧 In Progress
- [ ] MapKit integration for iOS
- [ ] Push notifications
- [ ] Payment processing integration
- [ ] QR code verification

### 📋 Planned
- [ ] iOS App Store submission
- [ ] Android native app development
- [ ] In-app messaging enhancements
- [ ] Advanced search filters
- [ ] User verification system

---

**NICE Traders** - Making currency exchange neighborly.
