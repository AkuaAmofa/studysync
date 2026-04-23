const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

async function sendNotification(fcmToken, title, body) {
  try {
    const admin = require('firebase-admin');
    if (!admin.apps.length) return;
    await admin.messaging().send({ token: fcmToken, notification: { title, body } });
  } catch (_) {
    // Notification delivery is best-effort; never block the main request.
  }
}

async function createGroup(req, res) {
  try {
    const { course_name, description, latitude, longitude, location_name, max_size, category } = req.body;
    const creator_id = req.user.user_id;

    if (!course_name || latitude == null || longitude == null || !location_name || !max_size) {
      return res.status(400).json({ error: 'course_name, latitude, longitude, location_name, and max_size are required' });
    }

    const group_id = uuidv4();
    const expires_at = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await pool.query(
      `INSERT INTO ss_study_groups
         (group_id, course_name, description, latitude, longitude, location_name, max_size, creator_id, expires_at, status, category)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)`,
      [group_id, course_name, description || null, latitude, longitude, location_name, max_size, creator_id, expires_at, category || null]
    );

    await pool.query(
      `INSERT INTO ss_group_members (member_id, group_id, user_id) VALUES (?, ?, ?)`,
      [uuidv4(), group_id, creator_id]
    );

    // Warn creator 1 hour before the group expires (at the 23-hour mark).
    setTimeout(async () => {
      try {
        const [userRows] = await pool.query(
          'SELECT fcm_token FROM ss_users WHERE user_id = ?',
          [creator_id]
        );
        const token = userRows[0]?.fcm_token;
        if (token) {
          await sendNotification(token, 'Group expiring soon',
            `Your ${course_name} study group expires in 1 hour!`);
        }
      } catch (_) {}
    }, 23 * 60 * 60 * 1000);

    const [rows] = await pool.query(
      'SELECT * FROM ss_study_groups WHERE group_id = ?',
      [group_id]
    );

    return res.status(201).json({ group: rows[0] });
  } catch (err) {
    console.error('createGroup error:', err);
    return res.status(500).json({ error: 'Server error creating group' });
  }
}

async function getNearbyGroups(req, res) {
  try {
    const { lat, lng } = req.query;

    if (lat == null || lng == null) {
      return res.status(400).json({ error: 'lat and lng query params are required' });
    }

    const user_id = req.user.user_id;

    const [groups] = await pool.query(
      `SELECT g.*,
              COUNT(DISTINCT m.member_id) AS member_count,
              (6371 * ACOS(
                COS(RADIANS(?)) * COS(RADIANS(g.latitude)) *
                COS(RADIANS(g.longitude) - RADIANS(?)) +
                SIN(RADIANS(?)) * SIN(RADIANS(g.latitude))
              )) AS distance_km,
              EXISTS(
                SELECT 1 FROM ss_group_members
                WHERE group_id = g.group_id AND user_id = ?
              ) AS is_member
       FROM ss_study_groups g
       LEFT JOIN ss_group_members m ON g.group_id = m.group_id
       WHERE g.status = 'active'
         AND (g.expires_at IS NULL OR g.expires_at > NOW())
       GROUP BY g.group_id
       ORDER BY g.created_at DESC`,
      [lat, lng, lat, user_id]
    );

    return res.status(200).json({ groups });
  } catch (err) {
    console.error('getNearbyGroups error:', err);
    return res.status(500).json({ error: 'Server error fetching nearby groups' });
  }
}

async function getGroupById(req, res) {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      `SELECT g.*, COUNT(DISTINCT m.member_id) AS member_count
       FROM ss_study_groups g
       LEFT JOIN ss_group_members m ON g.group_id = m.group_id
       WHERE g.group_id = ?
       GROUP BY g.group_id`,
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Group not found' });
    }

    return res.status(200).json({ group: rows[0] });
  } catch (err) {
    console.error('getGroupById error:', err);
    return res.status(500).json({ error: 'Server error fetching group' });
  }
}

async function endGroup(req, res) {
  try {
    const { id } = req.params;
    const user_id = req.user.user_id;

    const [rows] = await pool.query(
      'SELECT creator_id FROM ss_study_groups WHERE group_id = ?',
      [id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (rows[0].creator_id !== user_id) {
      return res.status(403).json({ error: 'Only the creator can end this group' });
    }

    await pool.query(
      "UPDATE ss_study_groups SET status = 'ended' WHERE group_id = ?",
      [id]
    );

    return res.status(200).json({ message: 'Group ended successfully' });
  } catch (err) {
    console.error('endGroup error:', err);
    return res.status(500).json({ error: 'Server error ending group' });
  }
}

async function getMyGroups(req, res) {
  try {
    const userId = req.user.user_id;
    const [rows] = await pool.query(
      `SELECT g.*, COUNT(DISTINCT m.member_id) AS member_count
       FROM ss_study_groups g
       JOIN ss_group_members m ON g.group_id = m.group_id
       WHERE m.user_id = ? AND g.status = 'active'
         AND (g.expires_at IS NULL OR g.expires_at > NOW())
       GROUP BY g.group_id
       ORDER BY g.created_at DESC`,
      [userId]
    );
    return res.status(200).json({ groups: rows });
  } catch (err) {
    console.error('getMyGroups error:', err);
    return res.status(500).json({ error: err.message });
  }
}

async function addNote(req, res) {
  try {
    const { id: group_id } = req.params;
    const uploaded_by = req.user.user_id;
    const { image_url, caption } = req.body;

    if (!image_url) {
      return res.status(400).json({ error: 'image_url is required' });
    }

    const note_id = uuidv4();
    await pool.query(
      `INSERT INTO ss_group_notes (note_id, group_id, uploaded_by, image_url, caption)
       VALUES (?, ?, ?, ?, ?)`,
      [note_id, group_id, uploaded_by, image_url, caption || null]
    );

    return res.status(201).json({ note_id });
  } catch (err) {
    console.error('addNote error:', err);
    return res.status(500).json({ error: 'Server error saving note' });
  }
}

async function getNotes(req, res) {
  try {
    const { id: group_id } = req.params;

    const [notes] = await pool.query(
      `SELECT n.note_id, n.image_url, n.caption, n.uploaded_at,
              u.name AS uploader_name
       FROM ss_group_notes n
       JOIN ss_users u ON n.uploaded_by = u.user_id
       WHERE n.group_id = ?
       ORDER BY n.uploaded_at DESC`,
      [group_id]
    );

    return res.status(200).json({ notes });
  } catch (err) {
    console.error('getNotes error:', err);
    return res.status(500).json({ error: 'Server error fetching notes' });
  }
}

module.exports = { createGroup, getNearbyGroups, getGroupById, endGroup, getMyGroups, addNote, getNotes };
