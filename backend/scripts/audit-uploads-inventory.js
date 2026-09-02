/**
 * Inventaire read-only de backend/uploads (pas de PII, pas de suppression).
 *   node scripts/audit-uploads-inventory.js
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../uploads');
const PUBLIC = new Set(['residences', 'profiles']);
const PRIVATE = new Set(['documents', 'messages', 'quarantine']);

function walk(dir, acc = []) {
  if (!fs.existsSync(dir)) return acc;
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(full, acc);
    else if (ent.isFile()) acc.push(full);
  }
  return acc;
}

function extOf(file) {
  return path.extname(file).toLowerCase() || '(none)';
}

function classify(rel) {
  const top = rel.split(/[\\/]/)[0] || '(root)';
  if (PUBLIC.has(top)) return 'public';
  if (PRIVATE.has(top)) return 'private';
  return 'unknown';
}

function looksPredictable(name) {
  return /^(image|photo|doc|file|upload|tmp)[-_]?\d*\.\w+$/i.test(name)
    || /^\d+\.\w+$/.test(name)
    || name.length < 8;
}

function main() {
  const files = walk(ROOT);
  const folders = {};
  const flags = [];

  for (const full of files) {
    const rel = path.relative(ROOT, full);
    const top = rel.split(/[\\/]/)[0] || '(root)';
    const st = fs.statSync(full);
    if (!folders[top]) {
      folders[top] = {
        count: 0,
        bytes: 0,
        extensions: {},
        oldest: st.mtime.toISOString(),
        newest: st.mtime.toISOString(),
        expected: classify(rel),
      };
    }
    const f = folders[top];
    f.count += 1;
    f.bytes += st.size;
    const ext = extOf(full);
    f.extensions[ext] = (f.extensions[ext] || 0) + 1;
    if (st.mtime < new Date(f.oldest)) f.oldest = st.mtime.toISOString();
    if (st.mtime > new Date(f.newest)) f.newest = st.mtime.toISOString();

    if (f.expected === 'unknown') {
      flags.push({ type: 'unclassified_folder', file: rel.replace(/\\/g, '/') });
    }
    if (f.expected === 'public' && PRIVATE.has(path.basename(path.dirname(full)))) {
      flags.push({ type: 'private_in_public_tree', file: rel.replace(/\\/g, '/') });
    }
    if (looksPredictable(path.basename(full)) && f.expected === 'private') {
      flags.push({ type: 'predictable_private_name', file: rel.replace(/\\/g, '/') });
    }
  }

  const report = {
    generatedAt: new Date().toISOString(),
    root: ROOT,
    exists: fs.existsSync(ROOT),
    totalFiles: files.length,
    folders,
    flags,
    note: 'Références DB (Partner.documents / Message.attachments) : lancer audit-partner-discriminator.js avec MONGODB_URI.',
  };
  console.log(JSON.stringify(report, null, 2));
}

main();
