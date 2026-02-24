# Firestore Schema Documentation

## Overview
This document outlines the Firestore collection structure for the CourtCare application.
The schema is designed to support offline-first capabilities using Drift for local storage and Firestore for synchronization.

## Security & Authentication
- **Role-Based Access Control (RBAC)**: Enforced via **Firebase Custom Claims**.
- **Roles**:
  - `admin`: Full access to all collections.
  - `agent`: Access to Maintenances (Read/Write).
  - `user` (default): Read own profile, Create Reservations (pending), Cancel own reservations.
  - `secretary`: (Reserved for future use, similar to agent + user management).

## Collections

### 1. `users`
Stores user profiles and authentication details.
- **Path**: `/users/{uid}`
- **Fields**:
  - `uid` (string) [PK]: Firebase Auth UID
  - `email` (string): User email (Unique constraint handled by Cloud Functions)
  - `name` (string): Display name
  - `role` (string): 'admin', 'agent', 'secretary', 'user'
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)
  - `syncedAt` (timestamp): Local Drift sync tracking
  - `remoteId` (string): Same as `uid` (Redundant but consistent for sync logic)
  - `profileImageUrl` (string)
  - `isActive` (boolean)
- **Indexes**:
  - `(role, isActive, createdAt DESC)`
  - `email` (Unique - via Cloud Function validation)

### 2. `terrains`
Stores tennis court information.
- **Path**: `/terrains/{id}`
- **Fields**:
  - `id` (string) [PK]: Auto-generated or custom string
  - `remoteId` (string): Firestore ID
  - `name` (string)
  - `surface` (string): 'clay', 'hard', 'grass'
  - `location` (string)
  - `capacity` (number)
  - `pricePerHour` (number)
  - `available` (boolean)
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)
  - `syncedAt` (timestamp)
  - `imageUrl` (string)
- **Indexes**:
  - `(available, surface, createdAt DESC)`

### 3. `reservations`
Real-time reservation data.
- **Path**: `/reservations/{id}`
- **Fields**:
  - `id` (string) [PK]
  - `remoteId` (string): Firestore ID
  - `userId` (string): Reference to `users`
  - `terrainId` (string): Reference to `terrains`
  - `date` (timestamp)
  - `startTime` (string): HH:mm
  - `endTime` (string): HH:mm
  - `status` (string): 'pending', 'confirmed', 'cancelled'
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)
  - `syncedAt` (timestamp)
  - `notes` (string)
  - `isSyncPending` (boolean): Local flag
- **Indexes**:
  - `(userId, date DESC)`
  - `(terrainId, date DESC)`
  - `(status, date DESC)`
  - Composite: `(terrainId, date, status)`

### Status Transitions (Reservations)
- `pending` -> `confirmed` (Admin/System)
- `pending` -> `cancelled` (User/Admin)
- `confirmed` -> `cancelled` (Admin)
- `cancelled` -> [immutable]

### 4. `stock`
Inventory items. **Sensitive Data - Admin Access Only.**
- **Path**: `/stock/{id}`
- **Fields**:
  - `id` (string) [PK]
  - `remoteId` (string): Firestore ID
  - `name` (string)
  - `category` (string)
  - `quantity` (number)
  - `minQuantity` (number)
  - `unitPrice` (number)
  - `lastModifiedBy` (string): Reference to `users`
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)
  - `syncedAt` (timestamp)
- **Indexes**:
  - `(category, quantity ASC)` [Low stock alerts]

### 5. `auditLogs`
System and security logs (Immutable).
- **TTL Policy**: Auto-delete after 365 days.
- **Path**: `/auditLogs/{id}`
- **Fields**:
  - `id` (string) [PK]
  - `remoteId` (string): Firestore ID
  - `action` (string)
  - `userId` (string): Reference to `users`
  - `userEmail` (string)
  - `timestamp` (timestamp)
  - `ipAddress` (string)
  - `deviceInfo` (string)
  - `details` (map)
  - `severity` (string): 'info', 'warning', 'critical'
- **Indexes**:
  - `(action, timestamp DESC)`
  - `(userId, timestamp DESC)`
  - `(severity, timestamp DESC)`

### 6. `maintenances`
Maintenance records. Accessible by **Admins** and **Agents**.
- **Path**: `/maintenances/{id}`
- **Fields**:
  - `id` (string) [PK]
  - `remoteId` (string): Firestore ID
  - `terrainId` (string): Reference to `terrains`
  - `type` (string)
  - `status` (string): 'scheduled', 'in_progress', 'completed'
  - `scheduledDate` (timestamp)
  - `completedDate` (timestamp)
  - `notes` (string)
  - `createdBy` (string): Reference to `users`
  - `createdAt` (timestamp)
  - `syncedAt` (timestamp)
- **Indexes**:
  - `(terrainId, scheduledDate DESC)`
  - `(status, scheduledDate DESC)`
