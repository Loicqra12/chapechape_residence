process.env.P2_03_INCLUDE_QUARANTINE = '1';
const { spawnSync } = require('child_process');
const r = spawnSync(
  'npx',
  ['jest', '--coverage=false'],
  { stdio: 'inherit', shell: true, env: process.env }
);
process.exit(r.status ?? 1);
