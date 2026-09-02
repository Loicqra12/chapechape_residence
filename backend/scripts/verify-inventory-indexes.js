/**
 * Vérification READ-ONLY des invariants Mongo cibles (P0).
 * Ne crée, ne supprime, ni ne synchronise aucun index.
 *
 * Usage :
 *   node scripts/verify-inventory-indexes.js
 *
 * exit 0 = SAFE
 * exit 1 = UNSAFE (invariant critique manquant)
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');

function hasUniqueKeyIndex(indexes) {
  return indexes.some((idx) => idx.unique === true && idx.key && idx.key.key === 1);
}

function hasAvailabilityUnique(indexes) {
  return indexes.some(
    (idx) => idx.unique === true && idx.key && idx.key.residenceId === 1 && idx.key.date === 1
  );
}

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('RESULT: UNSAFE');
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }

  console.log('Connexion read-only (host/db seulement, pas de secret)');
  const uriFp = fingerprintFromUri(process.env.MONGODB_URI);
  if (uriFp) {
    console.log('uri.host:', uriFp.host);
    console.log('uri.database:', uriFp.database);
    console.log('fingerprint(host|database):', uriFp.fingerprint);
  }

  await mongoose.connect(uri, { autoIndex: false });

  console.log('connected.host (shard résolu, diagnostic):', mongoose.connection.host);
  console.log('connected.database:', mongoose.connection.name);

  const checks = [];
  const fail = (name, detail) => {
    checks.push({ name, ok: false, detail });
  };
  const pass = (name, detail) => {
    checks.push({ name, ok: true, detail });
  };

  const admin = mongoose.connection.db.admin();
  let hello = {};
  let buildInfo = {};
  try {
    hello = await admin.command({ hello: 1 });
  } catch (err) {
    try {
      hello = await admin.command({ isMaster: 1 });
    } catch (err2) {
      fail('Mongo hello', err2.message);
    }
  }
  try {
    buildInfo = await admin.command({ buildInfo: 1 });
  } catch (err) {
    buildInfo = { version: 'unknown' };
  }

  const setName = hello.setName || null;
  const isMongos = hello.msg === 'isdbgrid';
  const isReplica = Boolean(setName) || isMongos;
  const transactions = isReplica;
  console.log('MongoDB version:', buildInfo.version || 'unknown');
  console.log('writeConcern connection:', JSON.stringify(mongoose.connection.writeConcern || hello.me && 'default'));
  console.log('readConcern:', JSON.stringify(hello.readConcern || mongoose.connection.readConcern || 'default'));

  if (isReplica) {
    pass('Mongo replica set', setName || 'mongos');
  } else {
    fail('Mongo replica set', 'standalone — transactions indisponibles');
  }

  if (transactions) {
    pass('Transactions', 'replica set / mongos');
  } else {
    fail('Transactions', 'non supportées sur standalone');
  }

  const db = mongoose.connection.db;
  let lockIndexes = [];
  let availIndexes = [];
  try {
    lockIndexes = await db.collection('inventorylocks').indexes();
  } catch (err) {
    fail('InventoryLock.key UNIQUE', `collection absente ou inaccessible: ${err.message}`);
  }
  try {
    availIndexes = await db.collection('availabilities').indexes();
  } catch (err) {
    fail('Availability unique index', `collection absente ou inaccessible: ${err.message}`);
  }

  if (lockIndexes.length) {
    if (hasUniqueKeyIndex(lockIndexes)) {
      pass('InventoryLock.key UNIQUE', JSON.stringify(lockIndexes.map((i) => i.name)));
    } else {
      fail('InventoryLock.key UNIQUE', JSON.stringify(lockIndexes));
    }
  }

  if (availIndexes.length) {
    if (hasAvailabilityUnique(availIndexes)) {
      pass('Availability unique index', JSON.stringify(availIndexes.map((i) => i.name)));
    } else {
      fail('Availability unique index', JSON.stringify(availIndexes));
    }
  }

  console.log('');
  for (const row of checks) {
    console.log(`${row.name.padEnd(34)} ${row.ok ? '✅' : '❌'}  ${row.detail || ''}`);
  }

  const unsafe = checks.some((c) => !c.ok);
  console.log('');
  console.log(unsafe ? 'RESULT: UNSAFE' : 'RESULT: SAFE');

  await mongoose.disconnect();
  process.exit(unsafe ? 1 : 0);
}

main().catch((err) => {
  console.error('RESULT: UNSAFE');
  console.error(err);
  process.exit(1);
});
