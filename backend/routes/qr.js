const express = require('express');
const router = express.Router();
const { mongoDb } = require('../index');
const { authMiddleware } = require('./auth');
const { v4: uuidv4 } = require('uuid');

router.post('/generate', authMiddleware, async (req, res) => {
  try {
    const { accountNumber, name } = req.body;
    const requestId = uuidv4().substring(0, 12);
    const data = {
      requestId,
      accountNumber,
      name: name || 'PayCore User',
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      used: false,
      createdBy: req.userId,
      createdAt: new Date()
    };
    if (mongoDb) {
      await mongoDb.collection('qr_payment_requests').insertOne(data);
    }
    res.json({
      requestId,
      qrData: JSON.stringify({ accountNumber, name: name || 'PayCore User' })
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:requestId', async (req, res) => {
  try {
    if (!mongoDb) return res.status(500).json({ error: 'MongoDB not connected' });
    const doc = await mongoDb.collection('qr_payment_requests').findOne({ requestId: req.params.requestId });
    if (!doc) return res.status(404).json({ error: 'QR request not found' });
    if (doc.used) return res.status(400).json({ error: 'QR already used' });
    if (doc.expiresAt < new Date()) return res.status(400).json({ error: 'QR expired' });
    res.json({ accountNumber: doc.accountNumber, name: doc.name });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:requestId/mark-used', async (req, res) => {
  try {
    if (mongoDb) {
      await mongoDb.collection('qr_payment_requests').updateOne(
        { requestId: req.params.requestId },
        { $set: { used: true, usedAt: new Date() } }
      );
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
