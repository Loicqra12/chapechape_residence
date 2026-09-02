const fs = require('fs').promises;
const os = require('os');
const path = require('path');
const { cleanupTempFiles } = require('../../../src/utils/cleanup');

describe('cleanupTempFiles (util, pas HTTP)', () => {
  let dir;

  beforeEach(async () => {
    dir = await fs.mkdtemp(path.join(os.tmpdir(), 'chape-cleanup-'));
  });

  afterEach(async () => {
    await fs.rm(dir, { recursive: true, force: true });
  });

  it('supprime les fichiers plus vieux que maxAgeHours', async () => {
    const oldFile = path.join(dir, 'old.tmp');
    await fs.writeFile(oldFile, 'old');
    const oldTime = new Date(Date.now() - 25 * 60 * 60 * 1000);
    await fs.utimes(oldFile, oldTime, oldTime);

    await cleanupTempFiles(dir, 24);
    await expect(fs.access(oldFile)).rejects.toMatchObject({ code: 'ENOENT' });
  });

  it('conserve un fichier récent', async () => {
    const recent = path.join(dir, 'recent.tmp');
    await fs.writeFile(recent, 'new');
    await cleanupTempFiles(dir, 24);
    await expect(fs.access(recent)).resolves.toBeUndefined();
  });

  it('répertoire inexistant : pas d’exception', async () => {
    await expect(cleanupTempFiles(path.join(dir, 'missing'), 24)).resolves.toBeUndefined();
  });
});
