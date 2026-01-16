# 🚀 IssueFlow — Jira-Inspired Issue Tracking Platform

IssueFlow is a modern, Jira-inspired issue tracking and project collaboration platform built with **Flutter (Web)** and a **scalable FastAPI backend**.  
It enables teams to manage projects, track issues, collaborate in real time, and onboard members seamlessly.

> Built with scalability, real-time communication, and clean architecture in mind.

---

## 🌐 Live Demo

- **Frontend (Flutter Web)**  
  👉 https://issueflow-app.web.app

- **Backend (FastAPI)**  
  👉 https://issueflow-project-backend.onrender.com/health

---

## ✨ Features

### 🔐 Authentication & Onboarding
- Email & Google authentication using Firebase
- Secure JWT-based backend authentication
- Guided onboarding flow for first-time users

### 📁 Project Management
- Create and manage multiple projects
- Unique project keys (Jira-style)
- Invite team members via email
- Accept or decline project invitations

### 🐞 Issue Tracking
- Create issues with:
  - Type (Task / Bug / Feature)
  - Priority (Low / Medium / High)
  - Status (To Do / In Progress / Done)
- Filter issues by status, priority, and assignee
- Assign issues to team members

### 💬 Real-Time Comments
- Per-issue comment threads
- Real-time updates using **Redis Pub/Sub + WebSockets**
- Edit and delete comments
- Multi-user collaboration

### 🎨 UI / UX
- Dark & Light theme support
- Responsive, desktop-first web UI
- Clean and modern Jira-inspired design

---

## 🧱 Architecture

### Frontend (Flutter Web)
- Flutter
- Dart
- BLoC / Cubit for state management
- Clean Architecture
  - Presentation
  - Domain
  - Data
- Dependency Injection
- Firebase integration

### Backend (FastAPI)
- FastAPI
- PostgreSQL
- Redis (Pub/Sub)
- WebSockets for real-time communication
- SQLModel
- JWT Authentication
- Firebase Admin SDK for token verification
- Dockerized setup

---

## 🖼️ Screenshots
Authentication
<img width="1912" height="910" alt="Screenshot 2026-01-15 230614" src="https://github.com/user-attachments/assets/25684b5c-f6f5-4b7d-916d-60859919c894" />
OnBoarding Flow
<img width="1908" height="914" alt="Screenshot 2026-01-15 230718" src="https://github.com/user-attachments/assets/883fe489-a2e7-41fc-8c0c-c43e31faadbb" />
<img width="1909" height="907" alt="Screenshot 2026-01-15 230806" src="https://github.com/user-attachments/assets/214a410b-dc82-4aa7-880b-cbaccd869805" />
<img width="1918" height="897" alt="Screenshot 2026-01-15 230744" src="https://github.com/user-attachments/assets/2c00bb2f-23ed-4613-a8ae-eedb3da8ccb2" />
DashBoard
<img width="1912" height="898" alt="image" src="https://github.com/user-attachments/assets/dff35d44-759f-4378-b66e-eed10ace28a8" />
Create Project
<img width="1912" height="908" alt="Screenshot 2026-01-15 230952" src="https://github.com/user-attachments/assets/2a8b8bf9-3244-4c76-b805-e5a745e41270" />
Invite Members
<img width="1919" height="897" alt="Screenshot 2026-01-16 172458" src="https://github.com/user-attachments/assets/18f8eef3-03e3-490f-9b92-a20d5b46b5ec" />
Issues & Real-Time Comments
<img width="1907" height="903" alt="Screenshot 2026-01-16 172323" src="https://github.com/user-attachments/assets/e0019724-1603-4864-9b23-55cb0e3e35d7" />
Accept Invite
<img width="1915" height="897" alt="Screenshot 2026-01-16 172546" src="https://github.com/user-attachments/assets/65191e2c-ca02-4c1b-88c0-cc2b32e0577a" />
Settings Page
<img width="1916" height="901" alt="Screenshot 2026-01-15 230922" src="https://github.com/user-attachments/assets/cc3f0b11-8f71-4267-80b4-880759b2df9c" />
Filter & Sorting
<img width="1917" height="895" alt="Screenshot 2026-01-16 172645" src="https://github.com/user-attachments/assets/4bfd48b1-3a9c-44c5-8559-2397468f4daf" />

---

## ⚙️ Tech Stack

### Frontend
- Flutter (Web)
- Dart
- BLoC / Cubit
- Firebase Authentication
- Clean Architecture

### Backend
- FastAPI
- PostgreSQL (Render)
- Redis (Upstash)
- WebSockets
- Docker
- Firebase Admin SDK

---

## 🧪 Key Highlights (Resume / Interview Ready)

- Built a **Jira-like issue tracking system** with real-world project workflows
- Implemented **real-time collaboration using Redis Pub/Sub and WebSockets**
- Designed a **scalable FastAPI backend** supporting multi-instance deployments
- Applied **Clean Architecture and BLoC** for maintainable Flutter codebase

---

## 🚀 Deployment

- **Frontend**: Firebase Hosting (Free tier)
- **Backend**: Render (Free tier)
- **Database**: Render PostgreSQL
- **Redis**: Upstash Redis

> ⚠️ Note: Backend may take a few seconds to wake up on first request due to Render free-tier cold start.

---

## 👨‍💻 Author

**Rajat Gore**  
Full-Stack Developer

- GitHub: https://github.com/Rajatg180

---

## ⭐️ Support

If you like this project:
- ⭐ Star the repository
- 🍴 Fork it
- 💬 Share feedback
