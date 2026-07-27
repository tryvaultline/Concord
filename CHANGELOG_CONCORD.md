# Concord Change Log & Upstream Modifications

This document lists all modifications made to upstream Signal software to create the independent **Concord** ecosystem.

## [1.0.0-concord] - 2026-07-27

### Added
- **Phone-less Authentication System**: Introduced Concord Account ID (UUID v4 / ACI), Argon2id password hashing with salt, username validation, and reserved name protection (`admin`, `support`, `signal`, `concord`, `system`, etc.).
- **Pre-seeded Accounts**: Added local development seed accounts (`_ii` / `Owen` and `.1` / `Hi.`).
- **Concord Rebranding**: Rebranded product display name to `Concord`, default iOS bundle identifier to `app.concord.ios`, centralizing configuration in `configuration/BundleIdentifiers.xcconfig`.
- **Unified Management Automation**: Added `scripts/bootstrap-local`, `scripts/start-local`, `scripts/stop-local`, `scripts/reset-local`, `scripts/health-check`, `scripts/test-network-isolation`, and `scripts/test-concord-e2e`.
- **Documentation Suite**: Added `VERSION_MATRIX.md`, `THIRD_PARTY_NOTICES.md`, `SIGNAL_SERVICE_DEPENDENCIES.md`, `ACCOUNT_AND_KEY_LIFECYCLE.md`, `GROUP_PERMISSIONS_GAP_ANALYSIS.md`, and `MACOS_BUILD_GUIDE.md`.

### Removed / Disabled
- **Phone Number Registration**: Stripped E.164 phone number requirement, SMS verification API endpoints, and country code pickers.
- **External Signal Endpoints**: Isolated network connections from `signal.org` and `whispersystems.org`.
- **Intel SGX SVR Enclave & Transparency Log**: Disabled non-essential external service dependencies for offline self-contained operation.

### Modified
- **Key Distribution Adapter**: Adapted Signal Protocol key bundle publishing to link Curve25519 prekeys and post-quantum Kyber prekeys to Concord Account IDs.
