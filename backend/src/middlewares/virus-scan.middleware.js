/**
 * Middleware de scan antivirus pour sécuriser les uploads de fichiers
 * Utilise ClamAV via l'API Node 'clamscan' si disponible
 * Sinon, fonctionne en mode dégradé avec avertissements
 */
const fs = require('fs');
const path = require('path');
const ApiError = require('../utils/apiError');
const logger = require('../utils/logger');

// Vérification de la disponibilité du module clamscan
let NodeClam;
let clamAvAvailable = false;
try {
    NodeClam = require('clamscan');
    clamAvAvailable = true;
} catch (err) {
    logger.warn('Module clamscan non installé. Le scan antivirus sera désactivé.');
    logger.warn('Pour activer le scan antivirus, installez le package avec: npm install clamscan');
    logger.warn('Assurez-vous également que ClamAV est installé sur le serveur.');
}

let clamScanInstance = null;

/**
 * Initialise l'instance ClamAV une seule fois
 * @returns {Promise<NodeClam|null>} Instance ClamAV ou null si non disponible
 */
const initClamAV = async () => {
  // Si le module ClamAV n'est pas disponible, retourner null directement
  if (!clamAvAvailable) {
    return null;
  }
  
  // Si l'instance existe déjà, la retourner
  if (clamScanInstance) return clamScanInstance;
  
  try {
    const options = {
      removeInfected: true,
      quarantineInfected: false,
      scanLog: path.join(__dirname, '../../logs/virus-scan.log'),
      debugMode: process.env.NODE_ENV === 'development',
      clamdscan: {
        socket: process.env.CLAMAV_SOCKET || '/var/run/clamav/clamd.ctl',
        host: process.env.CLAMAV_HOST || '127.0.0.1',
        port: process.env.CLAMAV_PORT || 3310,
        localFallback: true,
        path: process.env.CLAMDSCAN_PATH || '/usr/bin/clamdscan',
        configFile: null,
      },
      preference: 'clamdscan'
    };

    clamScanInstance = await new NodeClam().init(options);
    logger.info('ClamAV antivirus middleware initialized successfully');
    return clamScanInstance;
  } catch (err) {
    logger.error('Failed to initialize ClamAV:', err);
    return null;
  }
};

/**
 * Middleware pour scanner un fichier unique
 */
exports.scanSingleFile = async (req, res, next) => {
  // Si pas de fichier, rien à scanner
  if (!req.file) {
    return next();
  }

  try {
    // Vérifier si ClamAV est disponible
    if (!clamAvAvailable) {
      logger.warn(`Mode dégradé: Module ClamAV non installé, fichier accepté sans scan antivirus: ${req.file.path}`);
      
      // Vérification de sécurité de base: taille du fichier et type MIME
      const { size, mimetype } = req.file;
      const maxSize = parseInt(process.env.MAX_FILE_SIZE || 5000000); // 5MB par défaut
      
      if (size > maxSize) {
        logger.warn(`Fichier trop volumineux rejeté: ${req.file.path} (${size} octets)`);
        fs.unlinkSync(req.file.path);
        return next(new ApiError(`Le fichier dépasse la taille maximale autorisée de ${maxSize/1000000}MB.`, 400));
      }
      
      return next();
    }

    // Si ClamAV est disponible, l'initialiser et scanner le fichier
    const clamscan = await initClamAV();
    if (!clamscan) {
      logger.warn(`ClamAV non disponible après initialisation, fichier accepté sans scan: ${req.file.path}`);
      return next();
    }

    const { file } = req;
    const filePath = file.path;
    
    logger.info(`Scanning file for viruses: ${filePath}`);
    const { isInfected, viruses } = await clamscan.scanFile(filePath);
    
    if (isInfected) {
      logger.error(`Virus détecté dans le fichier ${filePath}:`, viruses);
      fs.unlinkSync(filePath);
      return next(new ApiError('Le fichier contient un virus et a été rejeté.', 400));
    }
    
    logger.info(`Le fichier ${filePath} a passé le scan antivirus avec succès.`);
    next();
  } catch (error) {
    logger.error('Erreur lors du scan antivirus:', error);
    // Continuer par mesure de sécurité (rejeter le fichier en cas de problème de scan)
    if (req.file && req.file.path && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    next(new ApiError('Erreur lors du scan de sécurité du fichier.', 500));
  }
};

/**
 * Middleware pour scanner plusieurs fichiers
 */
exports.scanMultipleFiles = async (req, res, next) => {
  if (!req.files || req.files.length === 0) {
    return next();
  }

  try {
    // Vérifier si ClamAV est disponible
    if (!clamAvAvailable) {
      logger.warn(`Mode dégradé: Module ClamAV non installé, ${req.files.length} fichiers acceptés sans scan antivirus`);
      
      // Vérification de sécurité de base: taille du fichier
      const maxSize = parseInt(process.env.MAX_FILE_SIZE || 5000000); // 5MB par défaut
      const oversizedFiles = req.files.filter(file => file.size > maxSize);
      
      if (oversizedFiles.length > 0) {
        // Supprimer les fichiers trop volumineux
        oversizedFiles.forEach(file => {
          logger.warn(`Fichier trop volumineux rejeté: ${file.path} (${file.size} octets)`);
          if (fs.existsSync(file.path)) {
            fs.unlinkSync(file.path);
          }
        });
        
        // Si tous les fichiers sont trop volumineux, rejeter la requête
        if (oversizedFiles.length === req.files.length) {
          return next(new ApiError(`Tous les fichiers dépassent la taille maximale autorisée de ${maxSize/1000000}MB.`, 400));
        }
        
        // Filtrer les fichiers trop volumineux
        req.files = req.files.filter(file => file.size <= maxSize);
      }
      
      return next();
    }

    // Si ClamAV est disponible, l'initialiser
    const clamscan = await initClamAV();
    if (!clamscan) {
      logger.warn(`ClamAV non disponible après initialisation, ${req.files.length} fichiers acceptés sans scan`);
      return next();
    }

    // Scanner chaque fichier
    const infectedFiles = [];

    for (const file of req.files) {
      const filePath = file.path;
      logger.info(`Scanning file for viruses: ${filePath}`);
      const { isInfected, viruses } = await clamscan.scanFile(filePath);
      
      if (isInfected) {
        logger.error(`Virus détecté dans le fichier ${filePath}:`, viruses);
        infectedFiles.push({ file: file.originalname, viruses });
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
    }

    if (infectedFiles.length > 0) {
      // Supprimer les fichiers restants
      req.files.forEach(file => {
        if (fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
      return next(new ApiError('Des virus ont été détectés dans les fichiers téléchargés.', 400));
    }
    
    logger.info('Tous les fichiers ont passé le scan antivirus avec succès.');
    next();
  } catch (error) {
    logger.error('Erreur lors du scan antivirus des fichiers multiples:', error);
    // Supprimer tous les fichiers en cas d'erreur
    if (req.files) {
      req.files.forEach(file => {
        if (file.path && fs.existsSync(file.path)) {
          fs.unlinkSync(file.path);
        }
      });
    }
    next(new ApiError('Erreur lors du scan de sécurité des fichiers.', 500));
  }
};
