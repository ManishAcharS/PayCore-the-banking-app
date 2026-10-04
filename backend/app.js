const { router, authMiddleware } = require('./routes/auth');
const accountsRouter = require('./routes/accounts');
const transfersRouter = require('./routes/transfers');
const pinRouter = require('./routes/pin');
const qrRouter = require('./routes/qr');

const { app } = require('./index');

app.use('/api/auth', router);
app.use('/api/accounts', accountsRouter);
app.use('/api/transfers', transfersRouter);
app.use('/api/pin', pinRouter);
app.use('/api/qr', qrRouter);
