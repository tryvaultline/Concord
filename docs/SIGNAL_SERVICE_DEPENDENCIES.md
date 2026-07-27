# Signal Service Dependencies & Concord Replacements

This document audits all external Signal services, domain references, API endpoints, and dependencies found within Signal upstream repositories, documenting their Concord local replacements.

| Service / Domain | Original Functionality | Concord Local Replacement | Replacement Status | Notes |
|---|---|---|---|---|
| `api.directory.signal.org` | Phone number contact discovery | `http://localhost:8080/v1/concord/users/search` | **Replaced** | Phone lookup replaced with Concord Username search. |
| `textsecure-service.whispersystems.org` | Signal WebSocket & REST Messaging API | `http://localhost:8080/v1/messages` | **Replaced** | Direct local socket and HTTP routes. |
| `cdn.signal.org` / `cdn2.signal.org` | Media & Attachment CDN | Local MinIO S3 (`http://localhost:9000/attachments`) | **Replaced** | Self-hosted S3 compatible storage. |
| `storage.signal.org` | Signal Storage Service (encrypted settings/contacts) | Concord Local Storage Service (`http://localhost:8080/v1/storage`) | **Replaced** | Local key-value store for encrypted data. |
| `svr2.signal.org` | Secure Value Recovery (SGX / Enclave) | Disabled locally | **Disabled** | SVR relies on Intel SGX enclaves; disabled for local independence. |
| `turn.signal.org` / STUN | WebRTC Relay for Calls | Local STUN/TURN (`stun:localhost:3478`) | **Replaced** | Self-hosted TURN server configuration. |
| `chat.signal.org` | Web client & WebSockets | `ws://localhost:8080/v1/websocket/` | **Replaced** | WebSocket endpoint mapped to local stack. |
| `updates.signal.org` | In-app update checks | Disabled | **Disabled** | Manual app updates only. |
| `support.signal.org` | Help center web links | Local documentation / disabled | **Replaced** | Replaced with local help route. |
| `donations.signal.org` | Signal Foundation donations | Disabled | **Disabled** | Stripped from settings menu. |
| `keytransparency.signal.org` | Key Transparency Audit Log | Disabled / Local log | **Disabled** | Transparency log disabled for self-contained deployment. |
| `apn.signal.org` | Apple Push Notification proxy | Direct APNs with Concord Team ID | **Replaced** | Concord APNs environment credentials (`apns.env.example`). |

---

## Network Isolation Rule

The Concord client and server must NEVER send traffic to `*.signal.org` or `*.whispersystems.org`.
This is verified automatically via `scripts/test-network-isolation.ps1`.
