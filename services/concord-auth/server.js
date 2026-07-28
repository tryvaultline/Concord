const argon2 = require('argon2');
const crypto = require('crypto');
const express = require('express');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '16kb' }));

const port = Number(process.env.CONCORD_AUTH_PORT || 8080);
const bindHost = process.env.CONCORD_AUTH_BIND_HOST || '127.0.0.1';
const reservedUsernames = new Set([
  'admin', 'administrator', 'support', 'signal', 'concord', 'system',
  'security', 'official', 'moderator',
]);
const usersByNormalizedUsername = new Map();
const attemptsByNormalizedUsername = new Map();
const sessionsByDigest = new Map();
const maxFailures = 5;
const lockoutMs = 15 * 60 * 1000;

function normalizeUsername(value) {
  return value.trim().toLocaleLowerCase('en-US');
}

function validateUsername(value) {
  if (typeof value !== 'string') return false;
  const username = value.trim();
  return username.length >= 3
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

async function seedLocalAccounts() {
  for (const index of [1, 2]) {
    const seed = seedDefinition(index);
    const supplied = Object.values(seed).filter(Boolean).length;
    if (supplied === 0) continue;
    if (supplied !== 3 || !validateUsername(seed.username) || seed.password.length < 12) {
      throw new Error(`SEED_ACCOUNT_${index} is incomplete or violates local development policy`);
    }
    const normalized = normalizeUsername(seed.username);
    if (usersByNormalizedUsername.has(normalized)) {
      throw new Error(`Duplicate seeded username for SEED_ACCOUNT_${index}`);
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
    });
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
    signalProtocolIntegration: 'NOT_CONFIGURED',
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

app.use((_req, res) => res.status(404).json({ error: 'Not found.' }));
app.use((error, _req, res, _next) => {
  console.error('[concord-auth] request failed:', error.message);
  res.status(500).json({ error: 'Internal server error.' });
});

seedLocalAccounts()
  .then(() => app.listen(port, bindHost, () => {
    console.log(`[concord-auth] listening on ${bindHost}:${port}; seeded accounts: ${usersByNormalizedUsername.size}`);
  }))
  .catch((error) => {
    console.error(`[concord-auth] startup failed: ${error.message}`);
    process.exitCode = 1;
  });
