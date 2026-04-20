const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

async function register(req, res) {
  try {
    const { name, email, password, programme, year_group } = req.body;

    if (!name || !email || !password || !programme || !year_group) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const [existing] = await pool.query(
      'SELECT user_id FROM ss_users WHERE email = ?',
      [email]
    );
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user_id = uuidv4();

    await pool.query(
      `INSERT INTO ss_users (user_id, name, email, password_hash, programme, year_group)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [user_id, name, email, password_hash, programme, year_group]
    );

    const token = jwt.sign(
      { user_id, email, role: 'user' },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(201).json({
      token,
      user: { user_id, name, email, programme, year_group, role: 'user' },
    });
  } catch (err) {
    console.error('register error:', err);
    return res.status(500).json({ error: 'Server error during registration' });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const [rows] = await pool.query('SELECT * FROM ss_users WHERE email = ?', [
      email,
    ]);
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { user_id: user.user_id, email: user.email, role: user.role || 'user' },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const { password_hash, ...userObj } = user;
    return res.status(200).json({ token, user: userObj });
  } catch (err) {
    console.error('login error:', err);
    return res.status(500).json({ error: 'Server error during login' });
  }
}

async function updateFcmToken(req, res) {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) {
      return res.status(400).json({ error: 'fcm_token is required' });
    }
    await pool.query(
      'UPDATE ss_users SET fcm_token = ? WHERE user_id = ?',
      [fcm_token, req.user.user_id]
    );
    return res.status(200).json({ message: 'FCM token updated' });
  } catch (err) {
    console.error('updateFcmToken error:', err);
    return res.status(500).json({ error: 'Server error updating FCM token' });
  }
}

async function getStats(req, res) {
  try {
    const userId = req.user.user_id;
    const [groupsJoined] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_members WHERE user_id = ?',
      [userId]
    );
    const [notesShared] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_notes WHERE uploaded_by = ?',
      [userId]
    );
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [sessionsThisWeek] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_members WHERE user_id = ? AND joined_at >= ?',
      [userId, oneWeekAgo]
    );
    return res.status(200).json({
      groups_joined: groupsJoined[0].count,
      notes_shared: notesShared[0].count,
      sessions_this_week: sessionsThisWeek[0].count,
    });
  } catch (err) {
    console.error('getStats error:', err);
    return res.status(500).json({ error: 'Server error fetching stats' });
  }
}

async function updateProfile(req, res) {
  try {
    const { name } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'name is required' });
    }
    await pool.query(
      'UPDATE ss_users SET name = ? WHERE user_id = ?',
      [name.trim(), req.user.user_id]
    );
    return res.status(200).json({ message: 'Profile updated' });
  } catch (err) {
    console.error('updateProfile error:', err);
    return res.status(500).json({ error: 'Server error updating profile' });
  }
}

module.exports = { register, login, updateFcmToken, getStats, updateProfile };
