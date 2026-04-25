const express = require('express');
const router = express.Router();
const { register, login, updateFcmToken, getStats, updateProfile, changePassword } = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/register', register);
router.post('/login', login);
router.patch('/fcm-token', authMiddleware, updateFcmToken);
router.get('/stats', authMiddleware, getStats);
router.patch('/profile', authMiddleware, updateProfile);
router.patch('/password', authMiddleware, changePassword);

module.exports = router;
