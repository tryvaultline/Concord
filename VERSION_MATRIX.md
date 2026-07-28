# Concord Version Matrix

This document records the exact upstream repositories, tags, commits, release dates, and technical reasons for selection when building **Concord**.

| Repository | Upstream URL | Tag / Reference | Target Commit SHA | Date | Selection Rationale |
|---|---|---|---|---|---|
| **clients/ios** | `https://github.com/signalapp/Signal-iOS.git` | `main` | `30da85beab750c23d691e8a91e2e6a96b0842080` | 2026-07-22 | Official Signal-iOS commit pinned before Concord changes; its Pods submodule is pinned by Signal-iOS at `790e6b432451d2c22ff765fb974288d8fe5dfbd5`. |
| **services/signal-server** | `https://github.com/signalapp/Signal-Server.git` | `main` | `3447345d02e326bd9740ac4784d1eab09d78f37a` | 2026-07-23 | Official server commit one day after the selected iOS source. The previous `v9.99.1` tag was rejected because it dates to 2023. |
| **dependencies/libsignal** | `https://github.com/signalapp/libsignal.git` | `v0.99.1` | `97801d22dcf9f5bf714f7b8fa3212cdc973ae1c8` | 2026-07-23 | Official cryptographic library release contemporaneous with the selected iOS and server commits. |
| **services/storage-service** | `https://github.com/signalapp/storage-service.git` | `v20260611.0.0` | `1594bbf181594b22131551482cfffc7bb08c95a6` | 2026-06-11 | Official tagged storage-service release near the selected client/server window. |
| **services/registration-service** | `https://github.com/signalapp/registration-service.git` | `main` | `9dce790401a43a1c4d6f53940599630d8c196edb` | 2026-07-17 | Official current registration-service commit; retained only for migration analysis, not for Concord production phone registration. |
| **services/calling-service** | `https://github.com/signalapp/Signal-Calling-Service.git` | `v137` | `ecc14cca0e5473fe801301761041893ad2b0b7c1` | 2026-07-08 | Official calling-service tag within the same release window; required for future independent calls. |

## Integration Notes
- `clients/ios` is a Git submodule pinned to the Concord-iOS fork. Its upstream remote remains `https://github.com/signalapp/Signal-iOS.git`; its required Signal submodules are initialized recursively in CI.
- Concord-specific work must be made as small, reviewable commits in that client; do not replace the client with a standalone prototype UI.
- Account login and account switching must be implemented against a reviewed Concord service contract while retaining Signal's identity, database and session lifecycle. A UI-only login screen is not an implementation of authentication.
- Protocol compatibility level: Signal protocol v9 (supporting ACI/PNI identity split, sealed sender, and PQ-crypto Kyber prekeys).
