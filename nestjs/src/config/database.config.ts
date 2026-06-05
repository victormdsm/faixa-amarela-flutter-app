import { registerAs } from '@nestjs/config';
import { DataSource, DataSourceOptions } from 'typeorm';

export const DATABASE_CONFIG_TOKEN = 'database';

/**
 * Build TypeORM DataSourceOptions from environment variables.
 *
 * Critical rules:
 * - synchronize is always false (migrations only)
 * - schema defaults to faixaamarela_prod
 * - logging enabled in non-production environments
 * - SSL enabled in production when DB_SSL=true
 */
function parseSsl(value?: string): boolean | object {
  if (!value) return false;
  const lowered = value.toLowerCase();
  if (lowered === 'true' || lowered === '1') return { rejectUnauthorized: false };
  if (lowered === 'false' || lowered === '0') return false;
  try {
    return JSON.parse(value);
  } catch {
    return { rejectUnauthorized: false };
  }
}

export const buildDataSourceOptions = (): DataSourceOptions => {
  const env = process.env.APP_ENV || process.env.NODE_ENV || 'local';
  const isProduction = env === 'production' || env === 'prod';

  return {
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    username: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_DATABASE || 'faixaamarela_prod',
    schema: process.env.DB_SCHEMA?.split(',')[0] || 'faixaamarela_prod',
    ssl: parseSsl(process.env.DB_SSL),
    synchronize: false,
    logging: isProduction
      ? ['error', 'warn', 'migration']
      : ['error', 'warn', 'schema', 'migration'],
    entities: [__dirname + '/../database/entities/*.entity.{ts,js}'],
    migrations: [__dirname + '/../database/migrations/*.{ts,js}'],
    migrationsRun: false,
    migrationsTableName: 'typeorm_migrations',
  };
};

/**
 * NestJS config factory registered under the 'database' namespace.
 */
export const databaseConfig = registerAs(DATABASE_CONFIG_TOKEN, buildDataSourceOptions);

/**
 * Default export is a pre-built DataSource for TypeORM CLI usage
 * (migration:run, migration:generate, etc.).
 */
export default new DataSource(buildDataSourceOptions());
