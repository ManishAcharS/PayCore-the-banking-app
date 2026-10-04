const { router, authMiddleware } = require('./auth');
const accountsRouter = require('./accounts');
const transfersRouter = require('./transfers');
const pinRouter = require('./pin');
const qrRouter = require('./qr');
const { app } = require('./index');

app.use('/api/auth', router);
app.use('/api/accounts', accountsRouter);
app.use('/api/transfers', transfersRouter);
app.use('/api/pin', pinRouter);
app.use('/api/qr', qrRouter);
