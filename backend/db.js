require('dotenv').config();
const { Pool } = require('pg');
const { MongoClient } = require('mongodb');

let pgPool = null;
let mongoDb = null;

async function initTables() {
  if (!pgPool) return;
  try {
    await pgPool.query(`
      CREATE EXTENSION IF NOT EXISTS pgcrypto;
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        google_id VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS accounts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        account_number VARCHAR(20) UNIQUE NOT NULL,
        balance NUMERIC(15,2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS transactions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        from_account_id UUID REFERENCES accounts(id),
        to_account_id UUID REFERENCES accounts(id),
        amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
        description VARCHAR(255),
        status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS pin_credentials (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        pin_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Postgres tables verified/created');
  } catch (err) {
    console.error('Postgres initTables error:', err);
  }
}

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
      await initTables();
    }
  } catch (err) {
    console.error('Postgres connection error:', err);
  }

  try {
    if (process.env.MONGODB_URI) {
      const mongoClient = new MongoClient(process.env.MONGODB_URI, { maxPoolSize: 5 });
      await mongoClient.connect();
      mongoDb = mongoClient.db('paycore');
    }
  } catch (err) {
    console.error('MongoDB connection error:', err);
  }
}

connectDB();

module.exports = {
  get pgPool() { return pgPool; },
  get mongoDb() { return mongoDb; }
};
