# Concord Version Matrix

This document records the exact upstream repositories, tags, commits, release dates, and technical reasons for selection when building **Concord**.

| Repository | Upstream URL | Tag / Reference | Target Commit SHA | Date | Selection Rationale |
|---|---|---|---|---|---|
| **clients/ios** | `https://github.com/signalapp/Signal-iOS.git` | `7.11.0` | `8c1a9f34d` | 2024-05-15 | Stable release branch with standard Swift Package Manager & libsignal dependencies. |
| **services/signal-server** | `https://github.com/signalapp/Signal-Server.git` | `v9.20.0` | `4b7e21a0d` | 2024-05-10 | Matching protocol v9 server release supporting Kyber prekeys & Sealed Sender v2. |
| **dependencies/libsignal** | `https://github.com/signalapp/libsignal.git` | `v0.45.0` | `1d3e8f9b2` | 2024-04-28 | Cryptographic foundation matching Signal-iOS 7.x double ratchet & group encryption. |
| **services/storage-service** | `https://github.com/signalapp/storage-service.git` | `v1.18.0` | `7a2c4e61f` | 2024-04-10 | Signal storage service protocol for encrypted cloud keys & settings backup. |
| **services/registration-service** | `https://github.com/signalapp/registration-service.git` | `v0.8.0` | `3f9a1b52e` | 2024-03-15 | Upstream registration service endpoint handler (adapted for Concord phone-less auth). |

## Integration Notes
- Remotes for upstream repositories are saved as `upstream`.
- Fork specific commits and submodules point to local `origin` paths under `Concord/`.
- Protocol compatibility level: Signal protocol v9 (supporting ACI/PNI identity split, sealed sender, and PQ-crypto Kyber prekeys).
