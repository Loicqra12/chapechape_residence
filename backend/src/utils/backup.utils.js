const fs = require('fs').promises;
const path = require('path');
const mongoose = require('mongoose');

const BACKUP_DIR = path.join(__dirname, '../../backups');

/**
 * Ensure backup directory exists
 */
async function ensureBackupDir() {
  try {
    await fs.access(BACKUP_DIR);
  } catch (error) {
    await fs.mkdir(BACKUP_DIR, { recursive: true });
  }
}

/**
 * Create a MongoDB backup using Mongoose export
 * Since mongodump is not available, we'll export collections as JSON
 */
async function createBackup(name) {
  await ensureBackupDir();

  const timestamp = new Date().toISOString().replace(/:/g, '-').split('.')[0];
  const backupName = name || `backup_${timestamp}`;
  const backupPath = path.join(BACKUP_DIR, `${backupName}.json`);

  try {
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();

    const backup = {
      timestamp: new Date(),
      database: db.databaseName,
      collections: {}
    };

    // Export each collection
    for (const collectionInfo of collections) {
      const collectionName = collectionInfo.name;
      const collection = db.collection(collectionName);
      const documents = await collection.find({}).toArray();
      backup.collections[collectionName] = documents;
    }

    // Write to file
    await fs.writeFile(backupPath, JSON.stringify(backup, null, 2));

    // Get file stats
    const stats = await fs.stat(backupPath);

    return {
      name: `${backupName}.json`,
      path: backupPath,
      size: Math.round(stats.size / (1024 ** 2)), // MB
      date: new Date(),
      collections: collections.length,
      status: 'success'
    };
  } catch (error) {
    console.error('Backup error:', error);
    throw new Error(`Failed to create backup: ${error.message}`);
  }
}

/**
 * List all backups
 */
async function listBackups() {
  await ensureBackupDir();

  try {
    const files = await fs.readdir(BACKUP_DIR);
    const backups = [];

    for (const file of files) {
      if (file.endsWith('.json')) {
        const filePath = path.join(BACKUP_DIR, file);
        const stats = await fs.stat(filePath);

        backups.push({
          id: file.replace('.json', ''),
          name: file,
          size: `${Math.round(stats.size / (1024 ** 2))}MB`,
          date: stats.mtime,
          type: 'manual',
          status: 'success'
        });
      }
    }

    return backups.sort((a, b) => b.date - a.date);
  } catch (error) {
    console.error('Error listing backups:', error);
    return [];
  }
}

/**
 * Delete a backup file
 */
async function deleteBackup(backupId) {
  const backupPath = path.join(BACKUP_DIR, `${backupId}.json`);

  try {
    await fs.unlink(backupPath);
    return true;
  } catch (error) {
    console.error('Error deleting backup:', error);
    throw new Error(`Failed to delete backup: ${error.message}`);
  }
}

/**
 * Restore from backup
 * WARNING: This will overwrite existing data!
 */
async function restoreBackup(backupId) {
  const backupPath = path.join(BACKUP_DIR, `${backupId}.json`);

  try {
    const backupData = await fs.readFile(backupPath, 'utf8');
    const backup = JSON.parse(backupData);

    const db = mongoose.connection.db;

    // Restore each collection
    for (const [collectionName, documents] of Object.entries(backup.collections)) {
      const collection = db.collection(collectionName);

      // Clear existing data
      await collection.deleteMany({});

      // Insert backup data
      if (documents.length > 0) {
        await collection.insertMany(documents);
      }
    }

    return {
      success: true,
      collectionsRestored: Object.keys(backup.collections).length,
      timestamp: backup.timestamp
    };
  } catch (error) {
    console.error('Restore error:', error);
    throw new Error(`Failed to restore backup: ${error.message}`);
  }
}

module.exports = {
  createBackup,
  listBackups,
  deleteBackup,
  restoreBackup
};
