const fs = require('fs');
const path = require('path');

function fix(root, pkgImport) {
  let n = 0;
  function walk(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) {
        walk(p);
        continue;
      }
      if (!e.name.endsWith('.dart')) continue;
      let s = fs.readFileSync(p, 'utf8');
      if (!s.includes('const FlutterSecureStorage()')) continue;
      s = s.replace(/const FlutterSecureStorage\(\)/g, 'AppSecureStorage.instance');
      if (!s.includes('secure_storage.dart')) {
        const lines = s.split('\n');
        let last = -1;
        for (let i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) last = i;
        }
        const imp = `import '${pkgImport}';`;
        if (last >= 0) lines.splice(last + 1, 0, imp);
        else lines.unshift(imp);
        s = lines.join('\n');
      }
      fs.writeFileSync(p, s);
      n += 1;
      console.log('updated', p);
    }
  }
  walk(path.join(root, 'lib'));
  console.log('fixed', n, 'in', root);
}

fix(
  path.join(__dirname, '../chapechape_partner'),
  'package:chapechape_partner/core/utils/secure_storage.dart'
);
fix(
  path.join(__dirname, '../chapechape_client'),
  'package:chapechape_client/core/utils/secure_storage.dart'
);
