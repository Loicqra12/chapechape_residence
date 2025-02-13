const fs = require('fs').promises;
const path = require('path');

/**
 * Clean up files older than the specified age
 * @param {string} directory - Directory to clean up
 * @param {number} maxAgeHours - Maximum age in hours before file is deleted
 */
async function cleanupTempFiles(directory = path.join(__dirname, '../../temp'), maxAgeHours = 24) {
    try {
        // Ensure directory exists
        await fs.access(directory);

        // Get all files in directory
        const files = await fs.readdir(directory);
        const now = Date.now();
        const maxAge = maxAgeHours * 60 * 60 * 1000; // Convert hours to milliseconds

        for (const file of files) {
            const filePath = path.join(directory, file);
            try {
                const stats = await fs.stat(filePath);
                const fileAge = now - stats.mtime.getTime();

                if (fileAge > maxAge) {
                    await fs.unlink(filePath);
                }
            } catch (error) {
                console.error(`Error processing file ${file}:`, error);
            }
        }
    } catch (error) {
        if (error.code === 'ENOENT') {
            console.log('Directory does not exist:', directory);
            return;
        }
        throw error;
    }
}

module.exports = {
    cleanupTempFiles
};
