# Authentication Flow Diagram

This document illustrates the authentication process in TennisCourt Care.

## Sign In Flow

```mermaid
graph TD
    A[User Enters Credentials] --> B{Validate Format?}
    B -- Invalid --> C[Throw InvalidCredentialsException]
    B -- Valid --> D{Rate Limit Check?}
    D -- Locked (Memory) --> E[Throw AccountLockedException]
    D -- Locked (DB) --> E
    D -- Allowed --> F[Fetch User from DB]
    F -- Not Found --> G[Record Attempt (Failure)]
    G --> H[Throw InvalidCredentialsException]
    F -- Found --> I{Verify Password?}
    I -- Invalid Hash --> G
    I -- Valid Hash --> J[Record Attempt (Success)]
    J --> K[Log Audit Event (LOGIN_SUCCESS)]
    K --> L[Generate JWT Token]
    L --> M[Store Token in Secure Storage]
    M --> N[Return User Entity]
```

## Session Validation Flow (App Launch)

```mermaid
graph TD
    A[App Launch] --> B{Token in Secure Storage?}
    B -- No --> C[Redirect to Login]
    B -- Yes --> D{Verify Token Signature & Expiry?}
    D -- Invalid/Expired --> E[Clear Token]
    E --> C
    D -- Valid --> F[Extract Email from Payload]
    F --> G[Fetch User from DB]
    G -- Not Found --> E
    G -- Found --> H[Update Auth State (Logged In)]
    H --> I[Redirect to Home]
```

## Admin Registration Flow

```mermaid
graph TD
    A[First Launch] --> B{Users Exist in DB?}
    B -- Yes --> C[Redirect to Login]
    B -- No --> D[Show Admin Registration Form]
    D --> E[User Submits Form]
    E --> F{Validate Inputs?}
    F -- Invalid --> G[Show Error]
    F -- Valid --> H[Hash Password (PBKDF2)]
    H --> I[Insert User (Role: Admin)]
    I --> J[Log Audit Event (ADMIN_REGISTERED)]
    J --> K[Auto-Login (Sign In Flow)]
```
