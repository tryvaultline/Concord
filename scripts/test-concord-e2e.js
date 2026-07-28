// This test intentionally proves only the local authentication boundary.
// Signal-protocol messaging must be proved against the official client/server
// stack; this script must never report an E2E messaging success by itself.
const crypto = require('crypto');
const { spawn } = require('child_process');
const path = require('path');

const port = 18080;
const password = `local-${crypto.randomBytes(24).toString('hex')}`;
const authDirectory = path.join(__dirname, '..', 'services', 'concord-auth');
const child = spawn(process.execPath, ['server.js'], {
  cwd: authDirectory,
  env: {
    ...process.env,
    CONCORD_AUTH_PORT: String(port),
    SEED_ACCOUNT_1_USERNAME: 'localalpha',
    SEED_ACCOUNT_1_PASSWORD: password,
    SEED_ACCOUNT_1_DISPLAY_NAME: 'Local Alpha',
  },
  stdio: ['ignore', 'pipe', 'pipe'],
});

async function request(pathname, options) {
  return fetch(`http://127.0.0.1:${port}${pathname}`, options);
}

async function main() {
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('concord-auth did not start')), 10_000);
    child.stdout.on('data', (data) => {
      if (data.toString().includes('listening')) {
        clearTimeout(timer);
        resolve();
      }
    });
    child.on('exit', (code) => reject(new Error(`concord-auth exited: ${code}`)));
  });

  const health = await request('/v1/health').then((response) => response.json());
  if (health.seededAccountCount !== 1 || health.signalProtocolIntegration !== 'NOT_CONFIGURED') {
    throw new Error('unexpected health response');
  }
  const login = await request('/v1/accounts/login', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: 'LOCALALPHA', password }),
  });
  const loginBody = await login.json();
  if (!login.ok || typeof loginBody.accessToken !== 'string') throw new Error('login failed');
  const registration = await request('/v1/accounts/register', { method: 'POST' });
  if (registration.status !== 403) throw new Error('public registration is enabled');
  console.log('CONCORD_AUTH_LOCAL_LOGIN_TEST_PASSED');
  console.log('SIGNAL_PROTOCOL_E2E_NOT_YET_CONFIGURED');
}

main()
  .catch((error) => { console.error(error.message); process.exitCode = 1; })
  .finally(() => child.kill());
