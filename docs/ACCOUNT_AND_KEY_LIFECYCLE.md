# Concord Account & Key Lifecycle Architecture

This document describes the security model, account identity generation, password hashing, device provisioning, and cryptographic key material lifecycle for **Concord**.

## 1. Identity & Account Architecture

Concord detaches identity from telephone numbers (E.164 phone numbers) while preserving 100% of Signal's end-to-end encryption semantics (Signal Protocol double ratchet, prekeys, sealed sender).

### Concord Account ID (ACI)
- **Format**: Random RFC 4122 UUID v4 (e.g. `9f8e7d6c-5b4a-3f2e-1d0c-9b8a7f6e5d4c`).
- **Immutability**: Permanent internal primary key. Changing username or display name does NOT alter the Account ID.
- **Independence**: Completely decoupled from phone numbers and usernames.

### Username & Display Name System
- **Username Rules**:
  - Unique, case-insensitive comparison (`john_doe` == `John_Doe`).
  - Allowed characters: `a-z`, `A-Z`, `0-9`, `_`, `.`, `-`.
  - Length: 2 to 32 characters.
  - Reserved list enforcement: `admin`, `administrator`, `support`, `signal`, `concord`, `system`, `security`, `official`, `moderator`.
- **Display Name**: User-chosen visible display name in chats.

---

## 2. Authentication & Password Security

### Password Hashing Specification
Concord uses **Argon2id** (the memory-hard password hashing algorithm winner of the Password Hashing Competition) to store credentials safely:

```text
Algorithm: Argon2id
Memory Cost (m): 65536 KiB (64 MB)
Time Cost (t): 3 iterations
Parallelism (p): 4 threads
Salt Length: 16 bytes (cryptographically secure random bytes per user)
Hash Length: 32 bytes
```

### Rate Limiting & Protection
- Maximum 5 failed attempts per username within a 15-minute window.
- Exponential backoff / temporary 15-minute lockout upon exceeding limit.
- Timing-attack safe credential verification (constant-time response timing).

---

## 3. Cryptographic Key Material Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│                    Concord Client                       │
│                                                         │
│  1. Authenticate Username/Password ──────────┐          │
│  2. Generate Local Keys in iOS Keychain      │          │
│     - Identity Key Pair (Curve25519)         │          │
│     - Signed PreKey + Signature              │          │
│     - One-Time PreKeys (100x)                │          │
│     - Kyber Post-Quantum PreKeys             │          │
│                                              ▼          │
│  3. Upload PUBLIC Key Bundles ───>  Concord Auth Server │
│                                    (Stores Public Keys) │
│  4. Private Keys stay ALWAYS ON DEVICE Keychain.        │
└─────────────────────────────────────────────────────────┘
```

1. **Client Account Auth**: Client submits `Username` and `Password` to Concord Auth Service.
2. **Device Registration**: Server validates credentials and registers `Device ID` (Primary device = 1).
3. **Key Generation**: Client generates Signal cryptographic material locally on device:
   - **Identity Key Pair**: Long-term Curve25519 keypair. Private key stored in iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
   - **Signed PreKey**: Medium-term key signed by Identity Key.
   - **One-Time PreKeys**: Batch of single-use Curve25519 prekeys.
   - **Kyber PreKeys**: Post-quantum KEM prekeys for PQ-resistant session initialization.
4. **Public Key Upload**: Client uploads ONLY public key material to Concord Server. Private keys NEVER leave the device.
5. **Session Establishment**: When User A sends a message to User B (by username), User A fetches User B's public prekey bundle from Concord Server and performs X3DH / Double Ratchet session setup.
