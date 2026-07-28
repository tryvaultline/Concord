# Concord Change Log

## Unreleased

- Pinned official Signal repositories at the commits listed in `VERSION_MATRIX.md`.
- Added a local, seed-only Argon2id username/password authentication service. Public account creation is disabled.
- Replaced the first iOS registration landing action with a Concord username/password screen. It does not invoke phone-number registration, SMS, voice verification, or device-transfer UI.
- Added a sideload-safe fallback when an App Group entitlement is absent.
- Corrected the local documentation and tests to distinguish implemented authentication from unimplemented Signal device provisioning and encrypted message transport.

## Not yet complete

- A local Signal-compatible account/device provisioning flow.
- Local encrypted direct/group messages, media, storage, calling, and APNs.
- Complete removal of upstream Signal network endpoints from the client.
- Verified multi-account isolation.
