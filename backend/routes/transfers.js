const express = require('express');
const router = express.Router();
const { pgPool, mongoDb } = require('../db');
const { authMiddleware } = require('./auth');

router.post('/transfer', authMiddleware, async (req, res) => {
  const client = await pgPool.connect();
  try {
    const { toAccountNumber, amount, description } = req.body;
    if (!toAccountNumber || !amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid transfer details' });
    }

    await client.query('BEGIN');

    const sender = await client.query(
      'SELECT a.id, a.balance, a.account_number FROM accounts a WHERE a.user_id = $1 FOR UPDATE',
      [req.userId]
    );
    if (sender.rows.length === 0) throw new Error('Sender account not found');

    const receiver = await client.query(
      'SELECT a.id, a.balance, a.account_number FROM accounts a WHERE a.account_number = $1 FOR UPDATE',
      [toAccountNumber]
    );
    if (receiver.rows.length === 0) throw new Error('Receiver account not found');

    if (sender.rows[0].account_number === receiver.rows[0].account_number) {
      throw new Error('Cannot transfer to same account');
    }

    if (parseFloat(sender.rows[0].balance) < parseFloat(amount)) {
      throw new Error('Insufficient balance');
    }

    await client.query(
      'UPDATE accounts SET balance = balance - $1 WHERE id = $2',
      [amount, sender.rows[0].id]
    );
    await client.query(
      'UPDATE accounts SET balance = balance + $1 WHERE id = $2',
      [amount, receiver.rows[0].id]
    );

    const txn = await client.query(
      `INSERT INTO transactions
       (from_account_id, to_account_id, amount, description, status)
       VALUES ($1, $2, $3, $4, 'COMPLETED')
       RETURNING *`,
      [sender.rows[0].id, receiver.rows[0].id, amount, description || 'Transfer']
    );

    await client.query('COMMIT');

    if (mongoDb) {
      try {
        await mongoDb.collection('transaction_logs').insertOne({
          postgresTransactionId: txn.rows[0].id,
          fromAccount: sender.rows[0].account_number,
          toAccount: receiver.rows[0].account_number,
          amount: parseFloat(amount),
          description: description || 'Transfer',
          status: 'COMPLETED',
          createdAt: new Date()
        });
      } catch (e) {
        console.error('MongoDB log error:', e);
      }
    }

    res.json({
      success: true,
      transaction: txn.rows[0],
      message: 'Simulated transfer - demo only'
    });
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (e) {}
    res.status(400).json({ error: err.message });
  } finally {
    client.release();
  }
});

router.get('/history', authMiddleware, async (req, res) => {
  try {
    const result = await pgPool.query(
      `SELECT t.id, t.amount, t.description, t.status, t.created_at,
              sa.account_number AS from_account,
              ra.account_number AS to_account
       FROM transactions t
       JOIN accounts sa ON sa.id = t.from_account_id
       JOIN accounts ra ON ra.id = t.to_account_id
       WHERE sa.user_id = $1 OR ra.user_id = $1
       ORDER BY t.created_at DESC
       LIMIT 50`,
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
