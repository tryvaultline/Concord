# Signal Service Dependencies

This is an implementation audit, not a completion claim. The imported iOS client still contains upstream Signal service configuration and the imported official services have not yet been composed into a Concord-compatible local stack.

| Dependency | Upstream role | Concord status |
|---|---|---|
| Signal REST/WebSocket service | account, key and message transport | **Not replaced** |
| Registration service | phone-number registration | **Not replaced in protocol layer; UI path bypassed** |
| Contact discovery | phone-number discovery | **Not replaced** |
| Storage service | encrypted storage | **Pinned upstream; not locally integrated** |
| Attachment CDN | encrypted media transport | **MinIO scaffold only; not integrated** |
| Calling/TURN | calls | **Pinned upstream; not locally integrated** |
| APNs proxy | push delivery | **Awaiting Concord Apple credentials** |
| SVR/key transparency | account recovery and verification | **Not configured** |

The current iOS landing screen no longer invokes phone registration, SMS, voice verification, or Signal device-transfer screens. The client must still be routed away from every Signal endpoint before a final Concord IPA may claim `NO_UNINTENDED_SIGNAL_NETWORK_DEPENDENCIES`.
