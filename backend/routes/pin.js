const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const { pgPool } = require('../index');
const { authMiddleware } = require('./auth');

router.post('/set', authMiddleware, async (req, res) => {
  try {
    const { pin } = req.body;
    if (!pin || pin.length < 4) return res.status(400).json({ error: 'PIN must be 4-6 digits' });
    const pinHash = await bcrypt.hash(pin, 10);
    await pgPool.query(
      INSERT INTO pin_credentials (user_id, pin_hash) VALUES (, )
       ON CONFLICT (user_id) DO UPDATE SET pin_hash = ,
      [req.userId, pinHash]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/verify', authMiddleware, async (req, res) => {
  try {
    const { pin } = req.body;
    const result = await pgPool.query('SELECT pin_hash FROM pin_credentials WHERE user_id = ', [req.userId]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'PIN not set' });
    const valid = await bcrypt.compare(pin, result.rows[0].pin_hash);
    if (!valid) return res.status(401).json({ error: 'Invalid PIN' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/status', authMiddleware, async (req, res) => {
  try {
    const result = await pgPool.query('SELECT 1 FROM pin_credentials WHERE user_id = ', [req.userId]);
    res.json({ hasPin: result.rows.length > 0 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
