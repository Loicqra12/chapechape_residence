const fs = require('fs').promises;
const path = require('path');

class PhoneLogger {
    constructor() {
        this.logDir = path.join(__dirname, '../logs/phone');
        this.ensureLogDirectory();
        
        // Cache en mémoire pour les statistiques temps réel
        this.statsCache = {
            totalLogs: 0,
            byCountry: {},
            byAction: {},
            errors: [],
            lastUpdated: new Date()
        };
    }

    async ensureLogDirectory() {
        try {
            await fs.mkdir(this.logDir, { recursive: true });
        } catch (error) {
            console.error('Erreur création dossier logs:', error);
        }
    }

    /**
     * Logger un événement lié aux numéros de téléphone
     * @param {Object} logData - Données à logger
     */
    async log(logData) {
        const timestamp = new Date();
        const logEntry = {
            timestamp: timestamp.toISOString(),
            ...logData,
            // Ajouter des métadonnées automatiques
            metadata: {
                userAgent: logData.userAgent || 'backend',
                ip: logData.ip || 'internal',
                sessionId: logData.sessionId || 'system'
            }
        };

        try {
            // Analyser et enrichir les données
            const enrichedEntry = this.enrichLogEntry(logEntry);
            
            // Écrire dans le fichier quotidien
            await this.writeToFile(enrichedEntry);
            
            // Mettre à jour les statistiques
            this.updateStats(enrichedEntry);
            
            // Logger en console pour debug
            console.log(`📱 Phone Log: ${enrichedEntry.action} - ${enrichedEntry.normalizedOutput || enrichedEntry.originalInput}`);
            
        } catch (error) {
            console.error('Erreur logging phone:', error);
        }
    }

    /**
     * Enrichir l'entrée de log avec des analyses automatiques
     */
    enrichLogEntry(entry) {
        const enriched = { ...entry };
        
        // Analyser le numéro original
        if (entry.originalInput) {
            enriched.analysis = this.analyzePhoneNumber(entry.originalInput);
        }
        
        // Analyser le numéro normalisé
        if (entry.normalizedOutput) {
            enriched.normalizedAnalysis = this.analyzePhoneNumber(entry.normalizedOutput);
        }
        
        // Détecter les erreurs de format
        if (entry.originalInput && entry.normalizedOutput) {
            enriched.formatChanges = this.detectFormatChanges(
                entry.originalInput, 
                entry.normalizedOutput
            );
        }
        
        return enriched;
    }

    /**
     * Analyser un numéro de téléphone
     */
    analyzePhoneNumber(phoneNumber) {
        const analysis = {
            length: phoneNumber.length,
            hasCountryCode: phoneNumber.startsWith('+'),
            detectedCountry: null,
            detectedCarrier: null,
            format: 'unknown'
        };
        
        // Détecter le pays
        if (phoneNumber.startsWith('+225')) {
            analysis.detectedCountry = 'CI';
            analysis.detectedCarrier = this.detectIvoryCoastCarrier(phoneNumber);
        } else if (phoneNumber.startsWith('+221')) {
            analysis.detectedCountry = 'SN';
            analysis.detectedCarrier = this.detectSenegalCarrier(phoneNumber);
        } else if (phoneNumber.startsWith('+223')) {
            analysis.detectedCountry = 'ML';
        } else if (phoneNumber.startsWith('+226')) {
            analysis.detectedCountry = 'BF';
        } else if (phoneNumber.startsWith('+224')) {
            analysis.detectedCountry = 'GN';
        }
        
        // Détecter le format
        if (phoneNumber.startsWith('+')) {
            analysis.format = 'e164';
        } else if (phoneNumber.startsWith('0')) {
            analysis.format = 'national_with_zero';
        } else if (/^\d+$/.test(phoneNumber)) {
            analysis.format = 'digits_only';
        }
        
        return analysis;
    }

    /**
     * Détecter l'opérateur en Côte d'Ivoire
     */
    detectIvoryCoastCarrier(phoneNumber) {
        const number = phoneNumber.replace('+225', '');
        
        if (number.startsWith('07') || number.startsWith('47') || number.startsWith('67')) {
            return 'Orange';
        } else if (number.startsWith('05') || number.startsWith('45') || number.startsWith('65')) {
            return 'MTN';
        } else if (number.startsWith('01') || number.startsWith('41') || number.startsWith('61')) {
            return 'Moov';
        }
        
        return 'Unknown';
    }

    /**
     * Détecter l'opérateur au Sénégal
     */
    detectSenegalCarrier(phoneNumber) {
        const number = phoneNumber.replace('+221', '');
        
        if (number.startsWith('77') || number.startsWith('78')) {
            return 'Orange';
        } else if (number.startsWith('70') || number.startsWith('76')) {
            return 'Tigo';
        } else if (number.startsWith('75')) {
            return 'Expresso';
        }
        
        return 'Unknown';
    }

    /**
     * Détecter les changements de format
     */
    detectFormatChanges(original, normalized) {
        const changes = [];
        
        if (!original.startsWith('+') && normalized.startsWith('+')) {
            changes.push('added_country_code');
        }
        
        if (original.startsWith('0') && !normalized.includes('0')) {
            changes.push('removed_leading_zero');
        }
        
        if (original.length !== normalized.length) {
            changes.push('length_changed');
        }
        
        const originalDigits = original.replace(/\D/g, '');
        const normalizedDigits = normalized.replace(/\D/g, '');
        
        if (originalDigits !== normalizedDigits.substring(normalizedDigits.length - originalDigits.length)) {
            changes.push('digits_modified');
        }
        
        return changes;
    }

    /**
     * Écrire dans le fichier de log quotidien
     */
    async writeToFile(logEntry) {
        const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
        const filename = `phone-${date}.json`;
        const filepath = path.join(this.logDir, filename);
        
        try {
            // Lire le fichier existant ou créer un nouveau
            let logs = [];
            try {
                const existingData = await fs.readFile(filepath, 'utf8');
                logs = JSON.parse(existingData);
            } catch (error) {
                // Fichier n'existe pas, créer un nouveau
                logs = [];
            }
            
            // Ajouter la nouvelle entrée
            logs.push(logEntry);
            
            // Réécrire le fichier
            await fs.writeFile(filepath, JSON.stringify(logs, null, 2));
            
        } catch (error) {
            console.error('Erreur écriture fichier log:', error);
        }
    }

    /**
     * Mettre à jour les statistiques en cache
     */
    updateStats(logEntry) {
        this.statsCache.totalLogs++;
        this.statsCache.lastUpdated = new Date();
        
        // Statistiques par pays
        const country = logEntry.normalizedAnalysis?.detectedCountry || 'Unknown';
        this.statsCache.byCountry[country] = (this.statsCache.byCountry[country] || 0) + 1;
        
        // Statistiques par action
        const action = logEntry.action || 'unknown';
        this.statsCache.byAction[action] = (this.statsCache.byAction[action] || 0) + 1;
        
        // Collecter les erreurs
        if (logEntry.error) {
            this.statsCache.errors.push({
                timestamp: logEntry.timestamp,
                error: logEntry.error,
                action: logEntry.action,
                phone: logEntry.originalInput
            });
            
            // Garder seulement les 100 dernières erreurs
            if (this.statsCache.errors.length > 100) {
                this.statsCache.errors = this.statsCache.errors.slice(-100);
            }
        }
    }

    /**
     * Obtenir les statistiques actuelles
     */
    getStats() {
        return {
            ...this.statsCache,
            // Ajouter des métriques calculées
            topCountries: Object.entries(this.statsCache.byCountry)
                .sort(([,a], [,b]) => b - a)
                .slice(0, 5),
            topActions: Object.entries(this.statsCache.byAction)
                .sort(([,a], [,b]) => b - a)
                .slice(0, 10),
            recentErrors: this.statsCache.errors.slice(-10)
        };
    }

    /**
     * Obtenir les logs d'une période
     */
    async getLogsByDate(date) {
        const filename = `phone-${date}.json`;
        const filepath = path.join(this.logDir, filename);
        
        try {
            const data = await fs.readFile(filepath, 'utf8');
            return JSON.parse(data);
        } catch (error) {
            return [];
        }
    }

    /**
     * Analyser les erreurs fréquentes
     */
    async analyzeCommonErrors(days = 7) {
        const errors = {};
        const now = new Date();
        
        for (let i = 0; i < days; i++) {
            const date = new Date(now - i * 24 * 60 * 60 * 1000);
            const dateStr = date.toISOString().split('T')[0];
            const logs = await this.getLogsByDate(dateStr);
            
            logs.forEach(log => {
                if (log.error) {
                    const errorKey = log.error.substring(0, 50); // Tronquer
                    errors[errorKey] = (errors[errorKey] || 0) + 1;
                }
            });
        }
        
        return Object.entries(errors)
            .sort(([,a], [,b]) => b - a)
            .slice(0, 10)
            .map(([error, count]) => ({ error, count }));
    }
}

// Instance singleton
const phoneLogger = new PhoneLogger();

module.exports = phoneLogger;
