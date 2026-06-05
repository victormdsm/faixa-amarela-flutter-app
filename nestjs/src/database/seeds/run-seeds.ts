import 'reflect-metadata';
import AppDataSource from '../data-source';
import { seedRoles } from './roles.seed';
import { seedSuperadmin } from './superadmin.seed';

/**
 * Seed runner for local development.
 *
 * Usage:
 *   npm run seed:run
 */
async function runSeeds() {
  const dataSource = AppDataSource;

  try {
    if (!dataSource.isInitialized) {
      await dataSource.initialize();
    }

    console.log('[seed:run] Database connected');

    await seedRoles(dataSource);
    await seedSuperadmin(dataSource);

    console.log('[seed:run] Seeds completed successfully');
  } catch (error) {
    console.error('[seed:run] Seed failed:', error);
    process.exitCode = 1;
  } finally {
    if (dataSource.isInitialized) {
      await dataSource.destroy();
    }
  }
}

runSeeds();
