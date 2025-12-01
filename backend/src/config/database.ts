import knex, { Knex } from 'knex';
import env from './env';
import logger from '../utils/logger';

const config: Knex.Config = {
  client: 'pg',
  connection: env.DATABASE_URL || {
    host: env.DB_HOST,
    port: env.DB_PORT,
    database: env.DB_NAME,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    ssl: env.DB_SSL ? { rejectUnauthorized: false } : false,
  },
  pool: {
    min: 2,
    max: 10,
    acquireTimeoutMillis: 30000,
    idleTimeoutMillis: 30000,
  },
  migrations: {
    directory: './src/migrations',
    extension: 'ts',
    tableName: 'knex_migrations',
  },
  debug: env.NODE_ENV === 'development',
};

const db = knex(config);

// Test connection
db.raw('SELECT 1')
  .then(() => {
    logger.info('✅ Database connection established');
  })
  .catch((err) => {
    logger.error('❌ Database connection failed:', err);
    process.exit(1);
  });

export default db;
