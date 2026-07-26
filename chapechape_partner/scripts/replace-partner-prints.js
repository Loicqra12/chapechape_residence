/**
 * Remplace print( par AppLogger.d( dans chapechape_partner/lib
 * Usage: node scripts/replace-partner-prints.js
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '../lib');
let files = 0;

function walk(dir) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      walk(p);
      continue;
    }
    if (!ent.name.endsWith('.dart') || ent.name.includes('app_logger')) continue;

    let s = fs.readFileSync(p, 'utf8');
    if (!/\bprint\(/.test(s)) continue;

    s = s.replace(/\bprint\(/g, 'AppLogger.d(');

    if (!s.includes('app_logger.dart')) {
      const lines = s.split('\n');
      let lastImport = -1;
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ')) lastImport = i;
      }
      const imp = "import 'package:chapechape_partner/core/utils/app_logger.dart';";
      if (lastImport >= 0) lines.splice(lastImport + 1, 0, imp);
      else lines.unshift(imp);
      s = lines.join('\n');
    }

    fs.writeFileSync(p, s);
    files += 1;
    console.log('updated', path.relative(root, p));
  }
}

walk(root);
console.log('Done. files:', files);
