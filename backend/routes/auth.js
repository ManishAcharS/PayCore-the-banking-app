const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { pgPool } = require('../db');

const JWT_SECRET = process.env.JWT_SECRET || 'demo_secret_key_change_in_prod';
const generateAccountNumber = () => {
  return 'PC' + Math.floor(100000000 + Math.random() * 900000000).toString();
};

const authMiddleware = (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) return res.status(400).json({ error: 'All fields required' });

    const hashed = await bcrypt.hash(password, 10);
    const result = await pgPool.query(
      'INSERT INTO users (name, email, password_hash) VALUES (, , ) RETURNING id, name, email',
      [name, email, hashed]
    );
    const user = result.rows[0];
    const accountNumber = generateAccountNumber();
    await pgPool.query(
      'INSERT INTO accounts (user_id, account_number, balance) VALUES (, , )',
      [user.id, accountNumber, 10000.00]
    );
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ user, token, accountNumber, message: 'Simulated balance, demo app' });
  } catch (err) {
    if (err.code === '23505') return res.status(400).json({ error: 'Email already exists' });
    res.status(500).json({ error: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const result = await pgPool.query('SELECT * FROM users WHERE email = ', [email]);
    if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });
    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ user: { id: user.id, name: user.name, email: user.email }, token });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/google', async (req, res) => {
  try {
    const { name, email, googleId } = req.body;
    if (!email || !googleId) return res.status(400).json({ error: 'Missing data' });
    let result = await pgPool.query('SELECT * FROM users WHERE google_id =  OR email = ', [googleId, email]);
    let user;
    if (result.rows.length === 0) {
      const hashed = await bcrypt.hash(uuidv4(), 10);
      result = await pgPool.query(
        'INSERT INTO users (name, email, password_hash, google_id) VALUES (, , , ) RETURNING id, name, email',
        [name || email, email, hashed, googleId]
      );
      user = result.rows[0];
      const accountNumber = generateAccountNumber();
      await pgPool.query(
        'INSERT INTO accounts (user_id, account_number, balance) VALUES (, , )',
        [user.id, accountNumber, 10000.00]
      );
    } else {
      user = result.rows[0];
    }
    const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ user: { id: user.id, name: user.name, email: user.email }, token });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const result = await pgPool.query('SELECT id, name, email FROM users WHERE id = ', [req.userId]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = { router, authMiddleware };
