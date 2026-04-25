const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { createGroup, getNearbyGroups, getGroupById, endGroup, getMyGroups, extendGroup, addNote, getNotes } = require('../controllers/groups.controller');
const { joinGroup, leaveGroup, getMembers } = require('../controllers/members.controller');

router.use(authMiddleware);

router.post('/', createGroup);
router.get('/nearby', getNearbyGroups);
router.get('/my-groups', getMyGroups);
router.get('/:id', getGroupById);
router.patch('/:id/end', endGroup);
router.patch('/:id/extend', extendGroup);
router.post('/:id/join', joinGroup);
router.delete('/:id/leave', leaveGroup);
router.get('/:id/members', getMembers);
router.post('/:id/notes', addNote);
router.get('/:id/notes', getNotes);

module.exports = router;
