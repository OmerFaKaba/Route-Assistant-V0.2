# 🗺️ Route Assistant

Route Assistant is a mobile application designed for discovering, sharing, and managing outdoor routes such as hiking and walking trails.  
The application combines map-based navigation, community interaction, and a scalable backend architecture.

Developed using **Flutter** with a **Supabase** backend.

---

## 🚀 Features

### 📍 Route Discovery
- Nearby routes based on user location  
- Interactive map view using Google Maps  
- Easy exploration of outdoor trails  

### 🗺️ Route Details
- Detailed route view with map visualization  
- Route descriptions and location information  

### ❤️ Community Features
- Like and comment on routes  
- View other users’ profiles  
- Community-driven interaction  

### 💬 Messaging
- Real-time user-to-user messaging  
- Inbox-style conversation list  

### 🔐 Authentication
- Secure login and registration  
- Supabase Authentication  
- Row Level Security (RLS) for data protection  

### ⚡ Performance & Testing
- Load and stress testing using **k6**  
- Concurrent user simulations  
- Backend performance analysis  

---

## 🧱 Tech Stack

### Frontend
- Flutter  
- Material 3 UI  
- Google Maps SDK  

### Backend
- Supabase  
  - PostgreSQL  
  - Authentication  
  - Realtime  
  - Row Level Security (RLS)  

### Testing
- k6 (Performance & Stress Testing)

---

## 🏗️ Application Architecture

Flutter Mobile App  
→ REST / Realtime  
→ Supabase Backend  
→ Authentication, Database, Realtime, RLS  

---

## 📱 Screens

- Home / Explore  
- Nearby Routes  
- Route Detail  
- Profile  
- Messages  
- Login & Register  

---

## 🔒 Security

- Row Level Security ensures users only access their own data  
- Public routes are readable by authenticated users  
- Sensitive operations are access-controlled  

---

## 🧪 Testing & Performance

- Stress tests with high numbers of concurrent users  
- Real user scenario testing  
- Performance metrics collected and evaluated  

---

## 📦 Build APK (Testing)

flutter build apk --split-per-abi

APK files can be shared directly with test users.

---

## 👥 Contributors

- Ömer Faruk Kaba
- Esra Yıldız  

---

## 📌 Future Improvements

- Offline map support  
- Advanced route recommendations  
- Notification system  
- Similar route suggestions based on distance and location  

