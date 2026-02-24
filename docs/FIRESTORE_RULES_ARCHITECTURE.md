# Firestore Rules Architecture

## Overview

This document describes the Firestore Rules implementation for the entire application.

## Collections & Access Control

### Users Collection
- **Read**: Owner (self) or Admin
- **Write**: Cloud Functions only (not direct)
- **Sensitive Fields**: role, isActive (protected)

### Terrains Collection
- **Read**: Public (anyone)
- **Write**: Admin only
- **Purpose**: Booking system - customers need to see available courts

### Stock Collection
- **Read**: Admin only
- **Write**: Admin only
- **Sensitive**: Inventory is confidential business data

### Maintenances Collection
- **Read**: Authenticated (all team members)
- **Write**: Admin only
- **Purpose**: Team coordination

### Reservations Collection
- **Read**: Owner or Admin
- **Create**: Validated by rules + Cloud Functions
- **Update**: Owner can cancel, Admin can reschedule
- **Delete**: Admin only
- **Validation**:
  - startTime < endTime
  - startTime > now (no past dates)
  - terrainId required
  - Initial status must be 'pending'
  - Conflict detection: Cloud Functions (async)

### AuditLogs Collection
- **Read**: Admin only
- **Write**: Cloud Functions only (via Admin SDK)
- **Purpose**: Compliance + audit trail

## Security Rules Hierarchy

1. **Authentication**: All operations require auth (except public reads)
2. **Authorization**: Role-based access (admin, agent, secretary)
3. **Field-Level**: Sensitive fields protected (role, isActive, stock quantity)
4. **Business Logic**: Rules validate basic constraints (dates, required fields)
5. **Async Operations**: Cloud Functions handle complex logic (conflicts, notifications)

## Testing

- Node.js: 65+ tests (rules validation)
- Flutter: 10+ tests (integration)
- Total: 75+ tests covering all collections + roles

## Deployment Checklist

Before deploying to production:

- [ ] All tests passing (npm test)
- [ ] Cloud Functions deployed (auth, reservations)
- [ ] Firestore indexes created (if needed)
- [ ] Rules validated in Firebase Console
- [ ] Test data cleared from production
