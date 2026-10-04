# PayCore — Banking & Payments App

A complete, working MVP of a banking & payments app built with **Flutter** (mobile) and **Node.js + Express** (backend), using **PostgreSQL** (relational) and **MongoDB Atlas** (NoSQL). This project demonstrates real CRUD, atomic money transfers with DB transactions, dual-database logging, authentication, PIN + biometric security, and QR-based payments.

> **SIMULATED FUNDS — NOT REAL MONEY**  
> This is a demo app for educational purposes only.

## Architecture

- **Frontend**: Flutter (Android APK)
- **Backend**: Node.js + Express API (deployed on Vercel)
- **Relational DB (SQL)**: PostgreSQL (Vercel Postgres / Supabase Postgres) — tables: users, ccounts, 	ransactions, pin_credentials
- **NoSQL DB**: MongoDB Atlas — collections: 	ransaction_logs, qr_payment_requests, device_sessions
- **Auth**: Email/password (bcrypt + JWT) + Google OAuth
- **Security**: PIN (hashed, bcrypt), Fingerprint/biometric via local_auth on app launch and before transaction confirmation

## Database Design

### PostgreSQL Schema (Relational)
- users(id, name, email, password_hash, google_id, created_at) — User accounts
- ccounts(id, user_id, account_number, balance, created_at) — Bank accounts (FK to users)
- 	ransactions(id, from_account_id, to_account_id, amount, description, status, created_at) — Transaction records (FKs to accounts)
- pin_credentials(id, user_id, pin_hash, created_at) — Hashed PIN (1:1 with user)

**Constraints**: alance >= 0, mount > 0, UNIQUE on email/account_number, proper foreign keys.

### MongoDB Collections (NoSQL)
- 	ransaction_logs — Audit trail of completed transfers (stores Postgres transaction id, accounts, amount, timestamp) for flexible querying/analytics
- qr_payment_requests — Short-lived QR scan sessions (requestId, accountNumber, expiresAt, used)
- device_sessions — Session tracking metadata (optional audit)

## How the SQL Transaction + NoSQL Logging Works

**Atomic Money Transfer (SQL Transaction)**: When a user initiates a transfer, the API executes a real PostgreSQL transaction (BEGIN ? debit sender ? credit receiver ? insert transaction row ? COMMIT or ROLLBACK). Row-level locks (FOR UPDATE) are used to prevent race conditions. If any step fails, all changes are rolled back — ensuring data consistency.

**Dual-Database Logging (NoSQL Audit Trail)**: After a successful commit in PostgreSQL, the transfer details are also written to MongoDB's 	ransaction_logs collection. This provides an immutable, queryable audit trail with flexible schema (useful for reporting/analytics) while the core financial state remains in the normalized relational DB. Both systems together satisfy "SQL + NoSQL database system with real CRUD and authentication" requirements.

## Features

1. User registration & login (email+password, hashed with bcrypt)
2. Google OAuth sign-in
3. Auto account creation with unique account number & demo balance (?10,000)
4. Atomic money transfer between accounts with DB transaction
5. Transaction history from PostgreSQL + audit logs in MongoDB
6. QR code generation for receiving money
7. QR code scanning to prefill send money screen
8. PIN setup/verification (hashed)
9. Biometric/fingerprint lock on app launch and before confirming transactions

## Live Demo URL

> Backend deployed on Vercel. Update pp/lib/config.dart with your live backend URL.

Example: https://your-paycore-backend.vercel.app

## Running Backend Locally

`ash
cd backend
cp .env.example .env  # Fill in DATABASE_URL, MONGODB_URI, JWT_SECRET
npm install
npm start
`

- PostgreSQL: Create DB and run schema.sql
- MongoDB Atlas: Create cluster and get connection string
- Test endpoints at http://localhost:3000/api/health

## Installing the APK

1. Download the released APK from the repo (pp/build/app/outputs/flutter-apk/app-release.apk) or build your own
2. Enable "Install from unknown sources" on Android device
3. Install and launch PayCore
4. Register/login and start using with simulated funds

## Building APK from Source

`ash
cd app
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
`

**SIMULATED FUNDS — NOT REAL MONEY. This is for demonstration purposes only.**
