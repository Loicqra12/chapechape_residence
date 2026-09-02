const fs = require('fs');
const path = require('path');
const quarantine = require('../../p2-03-quarantine');

function countSkips(dir) {
  let n = 0;
  for (const name of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, name.name);
    if (name.isDirectory()) {
      if (name.name === 'manual' || name.name === 'node_modules') continue;
      n += countSkips(p);
      continue;
    }
    if (!name.name.endsWith('.test.js')) continue;
    const src = fs.readFileSync(p, 'utf8');
    n += (src.match(/\bit\.skip\s*\(/g) || []).length;
    n += (src.match(/\btest\.skip\s*\(/g) || []).length;
    n += (src.match(/\bdescribe\.skip\s*\(/g) || []).length;
    n += (src.match(/\bxit\s*\(/g) || []).length;
  }
  return n;
}

describe('P2-03 quarantine guard', () => {
  it('currentQuarantine === WAVE_BASELINE (dette figée) et <= plafond historique', () => {
    expect(quarantine.length).toBe(quarantine.WAVE_BASELINE);
    expect(quarantine.length).toBeLessThanOrEqual(quarantine.CEILING);
  });

  it('skipped Jest plafonné', () => {
    const testsRoot = path.join(__dirname, '../..');
    expect(countSkips(testsRoot)).toBeLessThanOrEqual(quarantine.SKIP_CEILING);
  });

  it('chaque entrée est unique', () => {
    expect(new Set(quarantine).size).toBe(quarantine.length);
  });
});
