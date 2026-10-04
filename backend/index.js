require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'PayCore API is running', version: '1.0.0' });
});
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

const { Pool } = require('pg');
const { MongoClient } = require('mongodb');

let pgPool = null;
let mongoClient = null;
let mongoDb = null;

async function connectDB() {
  try {
    if (process.env.DATABASE_URL) {
      pgPool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
        max: 2,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000
      });
      await pgPool.query('SELECT NOW()');
      console.log('Postgres connected');
    }
  } catch (err) {
    console.error('Postgres connection error:', err);
  }

  try {
    if (process.env.MONGODB_URI) {
      mongoClient = new MongoClient(process.env.MONGODB_URI, { maxPoolSize: 5 });
      await mongoClient.connect();
      mongoDb = mongoClient.db('paycore');
      console.log('MongoDB connected');
    }
  } catch (err) {
    console.error('MongoDB connection error:', err);
  }
}

connectDB();

module.exports = { app, pgPool, mongoDb };
