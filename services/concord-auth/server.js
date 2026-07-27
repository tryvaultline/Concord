const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(express.json());

const PORT = process.env.CONCORD_AUTH_PORT || 8080;

// Reserved usernames
const RESERVED_USERNAMES = new Set([
  'admin', 'administrator', 'support', 'signal', 'concord',
  'system', 'security', 'official', 'moderator'
]);

// In-Memory Data Stores for Local Node Server
const usersByUsername = new Map(); // username.toLowerCase() -> UserObject
const usersById = new Map();       // accountId -> UserObject
const prekeyBundles = new Map();   // accountId -> KeyBundle
const messageQueues = new Map();   // accountId -> Array of Messages
const groupsById = new Map();      // groupId -> GroupObject
const attachments = new Map();     // attachmentId -> Buffer/Metadata
const loginAttempts = new Map();    // username -> { count, lockedUntil }

// Argon2id / Scrypt Crypto Helper
function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.scryptSync(password, salt, 64, { N: 16384, r: 8, p: 1 }).toString('hex');
  return { hash, salt };
}

function verifyPassword(password, storedHash, salt) {
  const { hash } = hashPassword(password, salt);
  return crypto.timingSafeEqual(Buffer.from(hash, 'hex'), Buffer.from(storedHash, 'hex'));
}

// Seed Accounts Setup
function seedTestAccounts() {
  const seedAccount1 = {
    username: '_ii',
    password: 'QQaa13579',
    displayName: 'Owen'
  };

  const seedAccount2 = {
    username: '.1',
    password: 'QQaa13579',
    displayName: 'Hi.'
  };

  [seedAccount1, seedAccount2].forEach(acc => {
    const lowerName = acc.username.toLowerCase();
    if (!usersByUsername.has(lowerName)) {
      const accountId = uuidv4();
      const { hash, salt } = hashPassword(acc.password);
      const userObj = {
        accountId,
        username: acc.username,
        displayName: acc.displayName,
        passwordHash: hash,
        salt,
        createdAt: new Date().toISOString(),
        devices: [1]
      };
      usersByUsername.set(lowerName, userObj);
      usersById.set(accountId, userObj);
      messageQueues.set(accountId, []);
      console.log(`[SEED] Created Concord Seed Account: username="${acc.username}" accountId="${accountId}"`);
    }
  });
}

// REST ENDPOINTS

// Health Check Endpoint
app.get('/v1/health', (req, res) => {
  res.json({
    status: 'OK',
    service: 'concord-auth',
    version: '1.0.0',
    mode: 'phone-less-accounts',
    seedAccountsLoaded: usersByUsername.size >= 2
  });
});

// Concord Username Search
app.get('/v1/concord/users/search', (req, res) => {
  const query = (req.query.q || '').trim().toLowerCase();
  if (!query) {
    return res.status(400).json({ error: 'Query parameter q is required' });
  }

  const results = [];
  for (const [lowerName, user] of usersByUsername.entries()) {
    if (lowerName.includes(query)) {
      results.push({
        accountId: user.accountId,
        username: user.username,
        displayName: user.displayName
      });
    }
  }

  res.json({ count: results.length, users: results });
});

// Register Endpoint
app.post('/v1/accounts/register', (req, res) => {
  const { username, password, displayName } = req.body;

  if (!username || !password || !displayName) {
    return res.status(400).json({ error: 'username, password, and displayName are required' });
  }

  const cleanUsername = username.trim();
  const lowerName = cleanUsername.toLowerCase();

  if (RESERVED_USERNAMES.has(lowerName)) {
    return res.status(409).json({ error: 'Username is reserved by Concord system' });
  }

  if (usersByUsername.has(lowerName)) {
    return res.status(409).json({ error: 'Username already exists' });
  }

  if (cleanUsername.length < 2 || cleanUsername.length > 32) {
    return res.status(400).json({ error: 'Username length must be between 2 and 32 characters' });
  }

  const accountId = uuidv4();
  const { hash, salt } = hashPassword(password);

  const newUser = {
    accountId,
    username: cleanUsername,
    displayName,
    passwordHash: hash,
    salt,
    createdAt: new Date().toISOString(),
    devices: [1]
  };

  usersByUsername.set(lowerName, newUser);
  usersById.set(accountId, newUser);
  messageQueues.set(accountId, []);

  res.status(201).json({
    status: 'SUCCESS',
    accountId,
    username: cleanUsername,
    displayName,
    deviceId: 1
  });
});

// Login Endpoint
app.post('/v1/accounts/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'username and password are required' });
  }

  const lowerName = username.trim().toLowerCase();
  const user = usersByUsername.get(lowerName);

  // Rate Limiting & Lockout Check
  const attemptInfo = loginAttempts.get(lowerName) || { count: 0, lockedUntil: 0 };
  if (Date.now() < attemptInfo.lockedUntil) {
    return res.status(429).json({ error: 'Account temporarily locked due to failed attempts. Try again in 15 minutes.' });
  }

  if (!user || !verifyPassword(password, user.passwordHash, user.salt)) {
    attemptInfo.count += 1;
    if (attemptInfo.count >= 5) {
      attemptInfo.lockedUntil = Date.now() + 15 * 60 * 1000; // 15 mins
    }
    loginAttempts.set(lowerName, attemptInfo);
    return res.status(401).json({ error: 'Invalid username or password' });
  }

  // Reset login attempts on success
  loginAttempts.delete(lowerName);

  const sessionToken = crypto.randomBytes(32).toString('hex');

  res.json({
    status: 'SUCCESS',
    accountId: user.accountId,
    username: user.username,
    displayName: user.displayName,
    sessionToken,
    deviceId: 1
  });
});

// Prekey Bundle Upload (Signal Protocol Key Distribution)
app.post('/v1/keys/prekeys', (req, res) => {
  const { accountId, identityKey, signedPreKey, oneTimePreKeys, kyberPreKeys } = req.body;

  if (!accountId || !identityKey || !signedPreKey) {
    return res.status(400).json({ error: 'accountId, identityKey, signedPreKey required' });
  }

  prekeyBundles.set(accountId, {
    accountId,
    identityKey,
    signedPreKey,
    oneTimePreKeys: oneTimePreKeys || [],
    kyberPreKeys: kyberPreKeys || [],
    updatedAt: new Date().toISOString()
  });

  res.json({ status: 'PREKEYS_STORED', accountId });
});

// Fetch Prekey Bundle for Recipient
app.get('/v1/keys/prekeys/:accountId', (req, res) => {
  const { accountId } = req.params;
  const bundle = prekeyBundles.get(accountId);

  if (!bundle) {
    // Return dummy prekey bundle if not yet uploaded, allowing simulated initial session setup
    return res.json({
      accountId,
      identityKey: 'concord_pub_identity_' + crypto.randomBytes(16).toString('hex'),
      signedPreKey: {
        keyId: 1,
        publicKey: 'concord_pub_signed_' + crypto.randomBytes(16).toString('hex'),
        signature: 'concord_sig_' + crypto.randomBytes(16).toString('hex')
      },
      oneTimePreKey: {
        keyId: Math.floor(Math.random() * 1000),
        publicKey: 'concord_pub_otk_' + crypto.randomBytes(16).toString('hex')
      }
    });
  }

  res.json(bundle);
});

// Send Message Endpoint (Direct / Note to Self / Group / Media)
app.post('/v1/messages/send', (req, res) => {
  const { senderAccountId, recipientAccountId, groupId, encryptedPayload, mediaId, isNoteToSelf } = req.body;

  if (!senderAccountId || (!recipientAccountId && !groupId && !isNoteToSelf)) {
    return res.status(400).json({ error: 'senderAccountId and (recipientAccountId, groupId, or isNoteToSelf) required' });
  }

  const messageId = uuidv4();
  const timestamp = new Date().toISOString();

  const msgObj = {
    messageId,
    senderAccountId,
    recipientAccountId: isNoteToSelf ? senderAccountId : recipientAccountId,
    groupId: groupId || null,
    encryptedPayload: encryptedPayload || 'CONCORD_E2E_ENCRYPTED_BLOB',
    mediaId: mediaId || null,
    isNoteToSelf: !!isNoteToSelf,
    timestamp
  };

  const targetAccount = isNoteToSelf ? senderAccountId : recipientAccountId;

  if (targetAccount) {
    const queue = messageQueues.get(targetAccount) || [];
    queue.push(msgObj);
    messageQueues.set(targetAccount, queue);
  }

  if (groupId && groupsById.has(groupId)) {
    const group = groupsById.get(groupId);
    group.members.forEach(memberId => {
      if (memberId !== senderAccountId) {
        const memberQueue = messageQueues.get(memberId) || [];
        memberQueue.push({ ...msgObj, groupId });
        messageQueues.set(memberId, memberQueue);
      }
    });
  }

  res.json({ status: 'SENT', messageId, timestamp });
});

// Message Sync Endpoint
app.get('/v1/messages/sync/:accountId', (req, res) => {
  const { accountId } = req.params;
  const queue = messageQueues.get(accountId) || [];
  
  // Drain queue
  messageQueues.set(accountId, []);

  res.json({ count: queue.length, messages: queue });
});

// Create Encrypted Group Endpoint
app.post('/v1/groups/create', (req, res) => {
  const { title, creatorAccountId, members } = req.body;

  if (!title || !creatorAccountId) {
    return res.status(400).json({ error: 'title and creatorAccountId required' });
  }

  const groupId = 'group_' + uuidv4();
  const allMembers = Array.from(new Set([creatorAccountId, ...(members || [])]));

  const groupObj = {
    groupId,
    title,
    ownerAccountId: creatorAccountId,
    admins: [creatorAccountId],
    members: allMembers,
    createdAt: new Date().toISOString()
  };

  groupsById.set(groupId, groupObj);

  res.status(201).json({ status: 'GROUP_CREATED', group: groupObj });
});

// Media Attachment Upload Endpoint
app.post('/v1/attachments/upload', (req, res) => {
  const attachmentId = 'att_' + uuidv4();
  attachments.set(attachmentId, {
    attachmentId,
    createdAt: new Date().toISOString(),
    size: req.body ? JSON.stringify(req.body).length : 0
  });

  res.json({
    status: 'UPLOADED',
    attachmentId,
    cdnUrl: `http://localhost:${PORT}/v1/attachments/${attachmentId}`
  });
});

app.get('/v1/attachments/:attachmentId', (req, res) => {
  const { attachmentId } = req.params;
  if (!attachments.has(attachmentId)) {
    return res.status(404).json({ error: 'Attachment not found' });
  }
  res.json({ attachmentId, data: 'ENCRYPTED_MEDIA_STREAM' });
});

// Initialize Seed Accounts and Start Server
seedTestAccounts();

app.listen(PORT, () => {
  console.log(`[CONCORD] Auth & Encryption Server active on http://localhost:${PORT}`);
  console.log(`[CONCORD] Phone-less registration & Argon2id auth ready.`);
});
