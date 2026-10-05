const express = require('express');
const cors = require('cors');

const { router } = require('./routes/auth');
const accountsRouter = require('./routes/accounts');
const transfersRouter = require('./routes/transfers');
const pinRouter = require('./routes/pin');
const qrRouter = require('./routes/qr');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'PayCore API is running', version: '1.0.0' });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/auth', router);
app.use('/api/accounts', accountsRouter);
app.use('/api/transfers', transfersRouter);
app.use('/api/pin', pinRouter);
app.use('/api/qr', qrRouter);

module.exports = app;
