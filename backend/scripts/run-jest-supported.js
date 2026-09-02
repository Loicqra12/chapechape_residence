/**
 * Suite supportée P2-03 : ignore toujours la quarantine, même si le shell
 * a encore P2_03_INCLUDE_QUARANTINE=1 après un test:legacy.
 */
delete process.env.P2_03_INCLUDE_QUARANTINE;
const { spawnSync } = require('child_process');
const r = spawnSync(
  'npx',
  ['jest', '--coverage=false', '--testTimeout=180000'],
  { stdio: 'inherit', shell: true, env: process.env }
);
process.exit(r.status ?? 1);
