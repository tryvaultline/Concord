const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const fs = require('node:fs/promises');
const net = require('node:net');
const path = require('node:path');
const test = require('node:test');

const servicePath = path.resolve(__dirname, '..', 'server.js');

async function freePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      server.close((error) => error ? reject(error) : resolve(port));
    });
  });
}

async function startService(port, dataPath) {
  const child = spawn(process.execPath, [servicePath], {
    env: {
      ...process.env,
      CONCORD_AUTH_PORT: String(port),
      CONCORD_AUTH_BIND_HOST: '127.0.0.1',
      CONCORD_AUTH_DATA_PATH: dataPath,
      SEED_ACCOUNT_1_USERNAME: 'alpha_test',
      SEED_ACCOUNT_1_PASSWORD: 'test-password-123',
      SEED_ACCOUNT_1_DISPLAY_NAME: 'Alpha Test',
    },
    stdio: 'ignore',
  });
  const baseUrl = `http://127.0.0.1:${port}`;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      const response = await fetch(`${baseUrl}/v1/health`);
      if (response.ok) return { child, baseUrl };
    } catch {
      // Wait for the service to bind its port.
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  child.kill();
  throw new Error('Concord auth service did not start');
}

async function stopService(child) {
  child.kill();
  await new Promise((resolve) => child.once('exit', resolve));
}

test('persists seeded account identity and public device keys', async () => {
  const root = await fs.mkdtemp(path.join(require('node:os').tmpdir(), 'concord-auth-'));
  const dataPath = path.join(root, 'accounts.json');
  const port = await freePort();
  let first;
  let second;
  try {
    first = await startService(port, dataPath);
    const login = await fetch(`${first.baseUrl}/v1/accounts/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ username: 'alpha_test', password: 'test-password-123' }),
    });
    assert.equal(login.status, 200);
    const session = await login.json();
    const authorization = { authorization: `Bearer ${session.accessToken}`, 'content-type': 'application/json' };
    const device = await fetch(`${first.baseUrl}/v1/devices`, {
      method: 'POST',
      headers: authorization,
      body: JSON.stringify({
        deviceId: 1,
        registrationId: 1,
        identityKey: 'aGVsbG8',
        signedPreKey: 'c2lnbmVk',
        pqLastResortPreKey: 'cHE',
        oneTimePreKeys: ['b25l'],
      }),
    });
    assert.equal(device.status, 201);
    await stopService(first.child);
    first = undefined;

    second = await startService(port, dataPath);
    const secondLogin = await fetch(`${second.baseUrl}/v1/accounts/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ username: 'alpha_test', password: 'test-password-123' }),
    });
    assert.equal(secondLogin.status, 200);
    const secondSession = await secondLogin.json();
    assert.equal(secondSession.accountId, session.accountId);
    const directory = await fetch(`${second.baseUrl}/v1/directory/alpha_test`, {
      headers: { authorization: `Bearer ${secondSession.accessToken}` },
    });
    assert.equal(directory.status, 200);
    const result = await directory.json();
    assert.equal(result.devices.length, 1);
    assert.equal(result.devices[0].identityKey, 'aGVsbG8');
  } finally {
    if (first) await stopService(first.child);
    if (second) await stopService(second.child);
    await fs.rm(root, { recursive: true, force: true });
  }
});
