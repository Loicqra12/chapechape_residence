const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const mediaController = require('../controllers/media.controller');

router.use(protect);

router.get('/cloudinary-signature', mediaController.getCloudinarySignature);

module.exports = router;
