const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');
const { sendSms } = require('../utils/sms');

async function sendNotification(fcmToken, title, body) {
  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) return;
    await admin.messaging().send({ token: fcmToken, notification: { title, body } });
  } catch (_) {}
}

async function joinGroup(req, res) {
  try {
    const { id: group_id } = req.params;
    const user_id = req.user.user_id;

    const [groups] = await pool.query(
      "SELECT * FROM ss_study_groups WHERE group_id = ? AND status = 'active' AND expires_at > NOW()",
      [group_id]
    );
    if (groups.length === 0) {
      return res.status(404).json({ error: 'Group not found or no longer active' });
    }

    const group = groups[0];

    const [existing] = await pool.query(
      'SELECT 1 FROM ss_group_members WHERE group_id = ? AND user_id = ?',
      [group_id, user_id]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Already a member of this group' });
    }

    const [countRows] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_members WHERE group_id = ?',
      [group_id]
    );
    if (countRows[0].count >= group.max_size) {
      return res.status(400).json({ error: 'Group is full' });
    }

    await pool.query(
      'INSERT INTO ss_group_members (member_id, group_id, user_id) VALUES (?, ?, ?)',
      [uuidv4(), group_id, user_id]
    );

    // Notify group creator (fire-and-forget).
    (async () => {
      try {
        const [joinerRows] = await pool.query(
          'SELECT name FROM ss_users WHERE user_id = ?', [user_id]);
        const joinerName = joinerRows[0]?.name ?? 'Someone';
        const [creatorRows] = await pool.query(
          `SELECT u.fcm_token FROM ss_users u
           JOIN ss_study_groups g ON g.creator_id = u.user_id
           WHERE g.group_id = ?`, [group_id]);
        const token = creatorRows[0]?.fcm_token;
        if (token && group.creator_id !== user_id) {
          await sendNotification(token, 'New member joined!',
            `${joinerName} joined your ${group.course_name} group.`);
        }
      } catch (_) {}
    })();

    // Send SMS confirmation to the user who just joined (fire-and-forget).
    (async () => {
      try {
        const [userRows] = await pool.query(
          'SELECT phone_number FROM ss_users WHERE user_id = ?', [user_id]
        );
        const phone = userRows[0]?.phone_number;
        if (phone) {
          await sendSms(phone,
            `StudySync: You joined '${group.course_name}'. See you there!`);
        }
      } catch (_) {}
    })();

    return res.status(200).json({ message: 'Joined group successfully' });
  } catch (err) {
    console.error('joinGroup error:', err);
    return res.status(500).json({ error: 'Server error joining group' });
  }
}

async function leaveGroup(req, res) {
  try {
    const { id: group_id } = req.params;
    const user_id = req.user.user_id;

    await pool.query(
      'DELETE FROM ss_group_members WHERE group_id = ? AND user_id = ?',
      [group_id, user_id]
    );

    return res.status(200).json({ message: 'Left group successfully' });
  } catch (err) {
    console.error('leaveGroup error:', err);
    return res.status(500).json({ error: 'Server error leaving group' });
  }
}

async function getMembers(req, res) {
  try {
    const { id: group_id } = req.params;

    const [members] = await pool.query(
      `SELECT u.user_id, u.name, u.email, u.programme, u.year_group, u.phone_number, m.joined_at
       FROM ss_group_members m
       JOIN ss_users u ON m.user_id = u.user_id
       WHERE m.group_id = ?`,
      [group_id]
    );

    return res.status(200).json({ members });
  } catch (err) {
    console.error('getMembers error:', err);
    return res.status(500).json({ error: 'Server error fetching members' });
  }
}

module.exports = { joinGroup, leaveGroup, getMembers };
