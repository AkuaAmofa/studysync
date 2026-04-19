const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

async function createGroup(req, res) {
  try {
    const { course_name, description, latitude, longitude, location_name, max_size } = req.body;
    const creator_id = req.user.user_id;

    if (!course_name || latitude == null || longitude == null || !location_name || !max_size) {
      return res.status(400).json({ error: 'course_name, latitude, longitude, location_name, and max_size are required' });
    }

    const group_id = uuidv4();
    const expires_at = new Date(Date.now() + 4 * 60 * 60 * 1000);

    await pool.query(
      `INSERT INTO ss_study_groups
         (group_id, course_name, description, latitude, longitude, location_name, max_size, creator_id, expires_at, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
      [group_id, course_name, description || null, latitude, longitude, location_name, max_size, creator_id, expires_at]
    );

    await pool.query(
      `INSERT INTO ss_group_members (member_id, group_id, user_id) VALUES (?, ?, ?)`,
      [uuidv4(), group_id, creator_id]
    );

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

    const [groups] = await pool.query(
      `SELECT g.*,
              COUNT(m.user_id) AS member_count,
              (6371 * ACOS(
                COS(RADIANS(?)) * COS(RADIANS(g.latitude)) *
                COS(RADIANS(g.longitude) - RADIANS(?)) +
                SIN(RADIANS(?)) * SIN(RADIANS(g.latitude))
              )) AS distance_km
       FROM ss_study_groups g
       LEFT JOIN ss_group_members m ON g.group_id = m.group_id
       WHERE g.status = 'active'
         AND g.expires_at > NOW()
       GROUP BY g.group_id
       HAVING distance_km <= 5
       ORDER BY distance_km ASC`,
      [lat, lng, lat]
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
      `SELECT g.*, COUNT(m.user_id) AS member_count
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

module.exports = { createGroup, getNearbyGroups, getGroupById, endGroup };
