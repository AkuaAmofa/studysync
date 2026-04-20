const express = require('express');
const router = express.Router();
const { register, login, updateFcmToken } = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

router.post('/register', register);
router.post('/login', login);
router.patch('/fcm-token', authMiddleware, updateFcmToken);

module.exports = router;
