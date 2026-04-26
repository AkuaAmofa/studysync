const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const pool = require('../config/db');

async function register(req, res) {
  try {
    const { name, email, password, programme, year_group, phone_number } = req.body;

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
      `INSERT INTO ss_users (user_id, name, email, password_hash, programme, year_group, phone_number)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [user_id, name, email, password_hash, programme, year_group, phone_number || null]
    );

    const token = jwt.sign(
      { user_id, email, role: 'user' },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(201).json({
      token,
      user: { user_id, name, email, phone_number: phone_number || null, programme, year_group, role: 'user' },
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
  const userId = req.user.user_id;
  let groupsJoined = 0, notesShared = 0, sessionsThisWeek = 0;
  try {
    const [g] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_members WHERE user_id = ?',
      [userId]
    );
    groupsJoined = Number(g[0].count);
  } catch (err) { console.error('getStats groups_joined error:', err); }

  try {
    const [n] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_notes WHERE uploaded_by = ?',
      [userId]
    );
    notesShared = Number(n[0].count);
  } catch (err) { console.error('getStats notes_shared error:', err); }

  try {
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [s] = await pool.query(
      'SELECT COUNT(*) AS count FROM ss_group_members WHERE user_id = ? AND joined_at >= ?',
      [userId, oneWeekAgo]
    );
    sessionsThisWeek = Number(s[0].count);
  } catch (_) {
    // joined_at column may not exist — fall back to total groups
    sessionsThisWeek = groupsJoined;
  }

  return res.status(200).json({ groups_joined: groupsJoined, notes_shared: notesShared, sessions_this_week: sessionsThisWeek });
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

async function changePassword(req, res) {
  try {
    const { current_password, new_password } = req.body;
    if (!current_password || !new_password) {
      return res.status(400).json({ error: 'current_password and new_password are required' });
    }
    if (new_password.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters' });
    }
    const [rows] = await pool.query('SELECT password_hash FROM ss_users WHERE user_id = ?', [req.user.user_id]);
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
    const valid = await bcrypt.compare(current_password, rows[0].password_hash);
    if (!valid) return res.status(401).json({ error: 'Current password is incorrect' });
    const hash = await bcrypt.hash(new_password, 10);
    await pool.query('UPDATE ss_users SET password_hash = ? WHERE user_id = ?', [hash, req.user.user_id]);
    return res.status(200).json({ message: 'Password updated' });
  } catch (err) {
    console.error('changePassword error:', err);
    return res.status(500).json({ error: 'Server error changing password' });
  }
}

module.exports = { register, login, updateFcmToken, getStats, updateProfile, changePassword };
