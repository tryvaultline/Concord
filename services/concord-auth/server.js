const argon2 = require('argon2');
const crypto = require('crypto');
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs/promises');
const path = require('path');

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));

const port = Number(process.env.CONCORD_AUTH_PORT || 8080);
const bindHost = process.env.CONCORD_AUTH_BIND_HOST || '127.0.0.1';
const dataPath = process.env.CONCORD_AUTH_DATA_PATH
  || path.join(__dirname, 'data', 'concord-accounts.json');
const reservedUsernames = new Set([
  'admin', 'administrator', 'support', 'signal', 'concord', 'system',
  'security', 'official', 'moderator',
]);
const usersByNormalizedUsername = new Map();
const attemptsByNormalizedUsername = new Map();
const sessionsByDigest = new Map();
const maxFailures = 5;
const lockoutMs = 15 * 60 * 1000;
let persistQueue = Promise.resolve();

function normalizeUsername(value) {
  return value.trim().toLocaleLowerCase('en-US');
}

function validateUsername(value) {
  if (typeof value !== 'string') return false;
  const username = value.trim();
  return username.length >= 2
    && username.length <= 32
    && /^[A-Za-z0-9._-]+$/.test(username)
    && !reservedUsernames.has(normalizeUsername(username));
}

function seedDefinition(index) {
  return {
    username: process.env[`SEED_ACCOUNT_${index}_USERNAME`],
    password: process.env[`SEED_ACCOUNT_${index}_PASSWORD`],
    displayName: process.env[`SEED_ACCOUNT_${index}_DISPLAY_NAME`],
  };
}

function serializeAccount(account) {
  return {
    accountId: account.accountId,
    username: account.username,
    displayName: account.displayName,
    passwordHash: account.passwordHash,
    createdAt: account.createdAt,
    devices: [...account.devices.values()],
  };
}

async function persistAccounts() {
  const payload = JSON.stringify({
    version: 1,
    accounts: [...usersByNormalizedUsername.values()].map(serializeAccount),
  }, null, 2);
  persistQueue = persistQueue.then(async () => {
    await fs.mkdir(path.dirname(dataPath), { recursive: true });
    const temporaryPath = `${dataPath}.${process.pid}.${crypto.randomUUID()}.tmp`;
    await fs.writeFile(temporaryPath, payload, { encoding: 'utf8', mode: 0o600 });
    await fs.rename(temporaryPath, dataPath);
  });
  return persistQueue;
}

async function loadAccounts() {
  try {
    const raw = await fs.readFile(dataPath, 'utf8');
    const parsed = JSON.parse(raw);
    if (parsed?.version !== 1 || !Array.isArray(parsed.accounts)) {
      throw new Error('unsupported account data format');
    }
    for (const account of parsed.accounts) {
      if (!account || !validateUsername(account.username)
        || typeof account.accountId !== 'string'
        || typeof account.displayName !== 'string'
        || typeof account.passwordHash !== 'string') {
        throw new Error('invalid account data');
      }
      const normalized = normalizeUsername(account.username);
      if (usersByNormalizedUsername.has(normalized)) {
        throw new Error('duplicate account data');
      }
      const devices = new Map();
      for (const device of account.devices ?? []) {
        if (device && Number.isInteger(device.deviceId) && device.deviceId > 0
          && typeof device.identityKey === 'string') {
          devices.set(device.deviceId, device);
        }
      }
      usersByNormalizedUsername.set(normalized, {
        accountId: account.accountId,
        username: account.username,
        displayName: account.displayName,
        passwordHash: account.passwordHash,
        createdAt: account.createdAt,
        devices,
      });
    }
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
}

async function seedLocalAccounts() {
  for (const index of [1, 2]) {
    const seed = seedDefinition(index);
    const supplied = Object.values(seed).filter(Boolean).length;
    if (supplied === 0) continue;
    if (supplied !== 3 || !validateUsername(seed.username) || seed.password.length < 8) {
      throw new Error(`SEED_ACCOUNT_${index} is incomplete or violates local development policy`);
    }
    const normalized = normalizeUsername(seed.username);
    if (usersByNormalizedUsername.has(normalized)) {
      continue;
    }
    usersByNormalizedUsername.set(normalized, {
      accountId: uuidv4(),
      username: seed.username.trim(),
      displayName: seed.displayName.trim(),
      passwordHash: await argon2.hash(seed.password, {
        type: argon2.argon2id,
        memoryCost: 19 * 1024,
        timeCost: 2,
        parallelism: 1,
      }),
      createdAt: new Date().toISOString(),
      devices: new Map(),
    });
  }
  await persistAccounts();
}

function tokenAccount(req) {
  const authorization = req.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return undefined;
  const token = authorization.slice('Bearer '.length);
  const digest = crypto.createHash('sha256').update(token).digest('hex');
  const session = sessionsByDigest.get(digest);
  if (!session || session.expiresAt <= Date.now()) {
    sessionsByDigest.delete(digest);
    return undefined;
  }
  return [...usersByNormalizedUsername.values()].find((account) => account.accountId === session.accountId);
}

function requireAccount(req, res, next) {
  const account = tokenAccount(req);
  if (!account) return res.status(401).json({ error: 'Authentication required.' });
  req.concordAccount = account;
  return next();
}

function isBase64UrlPublicMaterial(value, maximumBytes = 16384) {
  if (typeof value !== 'string' || value.length === 0 || value.length > maximumBytes * 2) return false;
  if (!/^[A-Za-z0-9_-]+$/.test(value)) return false;
  try {
    return Buffer.from(value, 'base64url').length <= maximumBytes;
  } catch {
    return false;
  }
}

function genericAuthenticationFailure(res) {
  return res.status(401).json({ error: 'Invalid credentials.' });
}

app.get('/v1/health', (_req, res) => {
  res.json({
    status: 'OK',
    service: 'concord-auth',
    authentication: 'username-password',
    seededAccountCount: usersByNormalizedUsername.size,
    signalProtocolIntegration: 'PUBLIC_KEY_DIRECTORY_ONLY',
  });
});

app.post('/v1/accounts/login', async (req, res, next) => {
  try {
    const { username, password } = req.body ?? {};
    if (typeof username !== 'string' || typeof password !== 'string') {
      return genericAuthenticationFailure(res);
    }
    const normalized = normalizeUsername(username);
    const attempt = attemptsByNormalizedUsername.get(normalized) ?? { failures: 0, lockedUntil: 0 };
    if (Date.now() < attempt.lockedUntil) {
      return res.status(429).json({ error: 'Too many attempts. Try again later.' });
    }
    const account = usersByNormalizedUsername.get(normalized);
    const authenticated = account && await argon2.verify(account.passwordHash, password);
    if (!authenticated) {
      attempt.failures += 1;
      if (attempt.failures >= maxFailures) attempt.lockedUntil = Date.now() + lockoutMs;
      attemptsByNormalizedUsername.set(normalized, attempt);
      return genericAuthenticationFailure(res);
    }
    attemptsByNormalizedUsername.delete(normalized);
    const token = crypto.randomBytes(32).toString('base64url');
    sessionsByDigest.set(crypto.createHash('sha256').update(token).digest('hex'), {
      accountId: account.accountId,
      expiresAt: Date.now() + 12 * 60 * 60 * 1000,
    });
    return res.json({
      accountId: account.accountId,
      username: account.username,
      displayName: account.displayName,
      accessToken: token,
      expiresIn: 12 * 60 * 60,
    });
  } catch (error) {
    next(error);
  }
});

app.all('/v1/accounts/register', (_req, res) => {
  res.status(403).json({ error: 'Public registration is disabled.' });
});

app.get('/v1/accounts/me', requireAccount, (req, res) => {
  const account = req.concordAccount;
  res.json({
    accountId: account.accountId,
    username: account.username,
    displayName: account.displayName,
    deviceCount: account.devices.size,
  });
});

app.post('/v1/devices', requireAccount, async (req, res, next) => {
  try {
    const { deviceId, registrationId, identityKey, signedPreKey, pqLastResortPreKey, oneTimePreKeys } = req.body ?? {};
    if (!Number.isInteger(deviceId) || deviceId < 1 || deviceId > 127
      || !Number.isInteger(registrationId) || registrationId < 1 || registrationId > 0x3fff
      || !isBase64UrlPublicMaterial(identityKey, 1024)
      || !isBase64UrlPublicMaterial(signedPreKey, 4096)
      || !isBase64UrlPublicMaterial(pqLastResortPreKey, 8192)
      || !Array.isArray(oneTimePreKeys) || oneTimePreKeys.length > 1000
      || !oneTimePreKeys.every((key) => isBase64UrlPublicMaterial(key, 8192))) {
      return res.status(400).json({ error: 'Invalid public device key material.' });
    }
    const account = req.concordAccount;
    account.devices.set(deviceId, {
      deviceId,
      registrationId,
      identityKey,
      signedPreKey,
      pqLastResortPreKey,
      oneTimePreKeys,
      updatedAt: new Date().toISOString(),
    });
    await persistAccounts();
    return res.status(201).json({ deviceId, status: 'PUBLIC_KEYS_STORED' });
  } catch (error) {
    next(error);
  }
});

app.get('/v1/directory/:username', requireAccount, (req, res) => {
  const requested = normalizeUsername(req.params.username);
  const account = usersByNormalizedUsername.get(requested);
  if (!account) return res.status(404).json({ error: 'Account not found.' });
  return res.json({
    accountId: account.accountId,
    username: account.username,
    displayName: account.displayName,
    devices: [...account.devices.values()].map(({ updatedAt, ...device }) => ({ ...device, updatedAt })),
  });
});

app.use((_req, res) => res.status(404).json({ error: 'Not found.' }));
app.use((error, _req, res, _next) => {
  console.error('[concord-auth] request failed:', error.message);
  res.status(500).json({ error: 'Internal server error.' });
});

loadAccounts()
  .then(seedLocalAccounts)
  .then(() => app.listen(port, bindHost, () => {
    console.log(`[concord-auth] listening on ${bindHost}:${port}; seeded accounts: ${usersByNormalizedUsername.size}`);
  }))
  .catch((error) => {
    console.error(`[concord-auth] startup failed: ${error.message}`);
    process.exitCode = 1;
  });
