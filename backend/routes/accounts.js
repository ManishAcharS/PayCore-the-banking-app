const express = require('express');
const router = express.Router();
const { pgPool } = require('../db');
const { authMiddleware } = require('./auth');

router.get('/balance', authMiddleware, async (req, res) => {
  try {
    const result = await pgPool.query(
      'SELECT a.account_number, a.balance, a.id FROM accounts a WHERE a.user_id = ',
      [req.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Account not found' });
    res.json({ account: result.rows[0], note: 'Simulated balance, demo app' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const result = await pgPool.query(
      'SELECT a.id, a.account_number, a.balance, a.created_at FROM accounts a WHERE a.user_id = ',
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
