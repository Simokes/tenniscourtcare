# Firestore Schema Documentation

## Overview
This document outlines the Firestore collection structure for the CourtCare application.
The schema is designed to support offline-first capabilities using Drift for local storage and Firestore for synchronization.

## Collections

### 1. `users`
Stores user profiles and authentication details.
- **Path**: `/users/{uid}`
- **Fields**:
  - `uid` (string) [PK]: Firebase Auth UID
  - `email` (string): User email
  - `name` (string): Display name
  - `role` (string): 'admin' or 'user'
  - `createdAt` (timestamp)
  - `updatedAt` (timestamp)
  - `syncedAt` (timestamp): Local Drift sync tracking
  - `profileImageUrl` (string)
  - `isActive` (boolean)
- **Indexes**:
  - `(role, isActive, createdAt DESC)`
  - `email` (Unique)

### 2. `terrains`
Stores tennis court information.
- **Path**: `/terrains/{id}`
- **Fields**:
  - `id` (string) [PK]
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
- **Indexes**:
  - `(userId, date DESC)`
  - `(terrainId, date DESC)`
  - `(status, date DESC)`
  - Composite: `(terrainId, date, status)`

### 4. `stock`
Inventory items.
- **Path**: `/stock/{id}`
- **Fields**:
  - `id` (string) [PK]
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
System and security logs (TTL: 1 year).
- **Path**: `/auditLogs/{id}`
- **Fields**:
  - `id` (string) [PK]
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
Maintenance records.
- **Path**: `/maintenances/{id}`
- **Fields**:
  - `id` (string) [PK]
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
