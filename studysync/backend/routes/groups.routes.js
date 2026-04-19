const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { createGroup, getNearbyGroups, getGroupById, endGroup } = require('../controllers/groups.controller');
const { joinGroup, leaveGroup, getMembers } = require('../controllers/members.controller');

router.use(authMiddleware);

router.post('/', createGroup);
router.get('/nearby', getNearbyGroups);
router.get('/:id', getGroupById);
router.patch('/:id/end', endGroup);
router.post('/:id/join', joinGroup);
router.delete('/:id/leave', leaveGroup);
router.get('/:id/members', getMembers);

module.exports = router;
