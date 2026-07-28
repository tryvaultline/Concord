# Concord Account and Key Lifecycle

## Implemented local authentication boundary

`services/concord-auth` accepts only the two administrator-seeded development accounts. It creates a random UUID v4 Concord Account ID, compares usernames case-insensitively, stores an Argon2id password hash (19 MiB memory, time cost 2, parallelism 1), limits failed attempts, and returns a random bearer token whose SHA-256 digest is retained in memory only. The local-development minimum is two username characters and eight password characters; production policy must use stricter limits. Public registration returns HTTP 403.

The seed values are loaded only from `.env.local`; that file is ignored by Git. No password is written to logs, test output, or source control.

## Not implemented yet

The login service currently does **not** provision a Signal device, generate or upload public prekeys, persist an account session in the iOS Keychain, or establish a message session. The iOS sign-in UI deliberately stops after authentication rather than entering the upstream phone-registration flow or claiming a ready encrypted account.

## Required implementation for the next phase

1. Authenticate the username/password over HTTPS and issue a revocable device session.
2. Generate the identity key pair, signed prekeys, one-time prekeys, and Kyber prekeys locally on the device.
3. Store private material in the Keychain; upload only the required public material to the Concord Signal-compatible service.
4. Bind the device to the immutable Concord Account ID without treating the username or password as cryptographic key material.
5. Restore or revoke device sessions without exposing private keys to the server.

Until these steps have running tests with two accounts, `PHASE_2_CONCORD_ACCOUNTS_PASSED` must not be reported.
