const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const mediaController = require('../controllers/media.controller');
const { streamPrivateUpload } = require('../security/private-uploads');

router.use(protect);

router.get('/cloudinary-signature', mediaController.getCloudinarySignature);
router.get('/private/:folder/:filename', streamPrivateUpload);

module.exports = router;
