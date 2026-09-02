const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');

router.use(protect);

function notImplemented(req, res) {
  return res.status(501).json({
    success: false,
    code: 'NOT_IMPLEMENTED',
    message: 'Support tickets non implémenté. Ownership (requester / assignedStaff / admin) obligatoire avant activation.',
  });
}

router.get('/tickets', notImplemented);
router.post('/tickets', notImplemented);
router.post('/tickets/:id/reply', notImplemented);
router.put('/tickets/:id/close', notImplemented);

module.exports = router;
