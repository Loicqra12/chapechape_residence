const path = require('path');
const fs = require('fs');
const { protect } = require('../middlewares/auth.middleware');
const { Conversation, Message } = require('../models/message.model');
const Partner = require('../models/partner.model');
const { canAccessConversation } = require('../security/resource-access');
const { isStaff } = require('../security/roles');

const UPLOAD_ROOT = path.resolve(__dirname, '../../uploads');
const PRIVATE_FOLDERS = new Set(['documents', 'messages', 'quarantine']);

function basenameOfUrl(url) {
  return path.basename(String(url || '').split('?')[0].replace(/\\/g, '/'));
}

function safeJoinUpload(folder, filename) {
  const cleanedFolder = String(folder || '').replace(/\\/g, '/').split('/').pop();
  const cleanedName = path.basename(String(filename || ''));
  if (!PRIVATE_FOLDERS.has(cleanedFolder) || !cleanedName || cleanedName.includes('..')) {
    return null;
  }
  const resolved = path.resolve(UPLOAD_ROOT, cleanedFolder, cleanedName);
  if (!resolved.startsWith(path.resolve(UPLOAD_ROOT, cleanedFolder))) {
    return null;
  }
  return resolved;
}

async function canReadPrivateFile(req, folder, filename) {
  if (isStaff(req.user.role)) return true;
  if (folder === 'documents') {
    const partner = await Partner.findById(req.user.id).select('documents');
    if (partner?.documents?.some((d) => basenameOfUrl(d.url) === filename)) {
      return true;
    }
    return false;
  }
  if (folder === 'messages') {
    const needle = `/uploads/messages/${filename}`;
    const message = await Message.findOne({
      'attachments.url': { $in: [needle, filename, `uploads/messages/${filename}`] },
    }).select('conversation');
    if (!message) return false;
    const conversation = await Conversation.findById(message.conversation).select('participants');
    return canAccessConversation(conversation, req.user);
  }
  return false;
}

function denyPublicPrivateUploads(req, res, next) {
  const rel = decodeURIComponent(req.path || '').replace(/^\/+/, '').replace(/\\/g, '/');
  if (rel.includes('..')) {
    return res.status(400).json({ success: false, message: 'Chemin invalide' });
  }
  if (rel.startsWith('documents/') || rel.startsWith('messages/') || rel.startsWith('quarantine/')) {
    return res.status(401).json({
      success: false,
      message: 'Authentification requise',
    });
  }
  return next();
}

async function streamPrivateUpload(req, res) {
  const { folder, filename } = req.params;
  const target = safeJoinUpload(folder, filename);
  if (!target) {
    return res.status(404).json({ success: false, message: 'Fichier introuvable' });
  }
  const allowed = await canReadPrivateFile(req, folder, path.basename(target));
  if (!allowed) {
    return res.status(403).json({ success: false, message: 'Non autorisé' });
  }
  if (!fs.existsSync(target)) {
    return res.status(404).json({ success: false, message: 'Fichier introuvable' });
  }
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Content-Disposition', `inline; filename="${path.basename(target)}"`);
  return res.sendFile(target);
}

module.exports = {
  denyPublicPrivateUploads,
  streamPrivateUpload,
  protectPrivateUpload: protect,
};
