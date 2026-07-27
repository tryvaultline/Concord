# Concord Secure Messaging Ecosystem

**Concord** is an independent, phone-less secure messaging ecosystem built on official **Signal** open-source foundations (`Signal-iOS`, `Signal-Server`, `libsignal`).

It replaces telephone number authentication with **Username, Password, and Display Name** accounts while retaining 100% end-to-end encryption semantics (Signal Protocol double ratchet, Curve25519 prekeys, post-quantum Kyber prekeys, sealed sender, encrypted group v2).

---

## Legal Notice & Attribution

> **IMPORTANT NOTICE**
> 
> Concord is an independent modified project based on open-source Signal software.
> Concord is not affiliated with or endorsed by Signal.
>
> All upstream components from `signalapp` are licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.
> See `THIRD_PARTY_NOTICES.md` and `LICENSES/AGPL-3.0.txt`.

---

## Directory Structure

```text
Concord/
├─ clients/
│  ├─ ios/                      # Official Signal-iOS client fork (Xcode workspace + submodules)
│  └─ ios-prototype-legacy/     # Archived pre-fork UIKit prototype; not shipped or built
├─ archive/ios-prototype/        # Archived placeholder IPA and Payload; never ship these artifacts
├─ services/
│  ├─ concord-auth/             # Phone-less Auth & Key Distribution API (Argon2id)
│  ├─ signal-server/            # Signal Protocol backend server adapter
│  ├─ storage-service/          # Key-value encrypted storage backup
│  ├─ registration-service/     # Identity registration service endpoint
│  └─ calling-service/          # WebRTC voice/video relay service
├─ dependencies/
│  └─ libsignal/                # Official libsignal crypto library (Rust/C)
├─ infrastructure/
│  ├─ docker/                   # Docker Compose container definitions
│  ├─ local/                    # Local storage & databases
│  └─ scripts/                  # Service control & maintenance scripts
├─ configuration/
│  ├─ development/              # Environment configurations (concord.env)
│  └─ examples/                 # APNs template example (apns.env.example)
├─ docs/                        # Architecture, key lifecycle & macOS build guides
├─ LICENSES/                    # AGPL-3.0 legal text
├─ THIRD_PARTY_NOTICES.md       # Upstream credits & attribution
├─ README.md                    # Project documentation
└─ VERSION_MATRIX.md            # Upstream repository version pin matrix
```

---

## Quick Start (Local Service Stack)

### 1. Bootstrap Local Environment
```powershell
.\scripts\bootstrap-local.ps1
# Or on macOS/Linux: bash scripts/bootstrap-local.sh
```

### 2. Start Services
```powershell
.\scripts\start-local.ps1
# Or on macOS/Linux: bash scripts/start-local.sh
```

### 3. Run Health Check
```powershell
.\scripts\health-check.ps1
```

### Build the iOS client

The iOS client is the official Signal-iOS workspace at `clients/ios/Signal.xcworkspace`.
Its current product name, bundle identifier, and app icon remain unchanged. Build it on macOS/Xcode; do not use the archived prototype or a generated placeholder binary.

To export a signed IPA from that workspace:
```bash
python3 scripts/package_ipa.py --team-id YOUR_APPLE_TEAM_ID
```

For an unsigned IPA that a sideloading tool will sign, use `python3 scripts/package_ipa.py --unsigned`.

### 4. Run End-to-End Test Suite
```powershell
.\scripts\test-concord-e2e.ps1
```

---

## Pre-seeded Development Accounts

| Username | Password | Display Name | Internal Concord Account ID (ACI) |
|---|---|---|---|
| `_ii` | `QQaa13579` | `Owen` | Dynamic Random UUID v4 |
| `.1` | `QQaa13579` | `Hi.` | Dynamic Random UUID v4 |

---

## Network Independence Audit

Verify zero connections are made to `signal.org` domains:
```powershell
.\scripts\test-network-isolation.ps1
```
Result: `NO_UNINTENDED_SIGNAL_NETWORK_DEPENDENCIES`
