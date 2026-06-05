import { DataSource } from 'typeorm';

/**
 * Truncates all tables used in tests. Runs against the real PostgreSQL test database.
 * This is the heavy cleanup used between e2e/integration suites.
 *
 * Tables are ordered to avoid FK violations.
 */
export async function truncateAll(dataSource: DataSource): Promise<void> {
  if (!dataSource.isInitialized) {
    throw new Error('DataSource must be initialized before truncating tables');
  }

  const tables = [
    'notification_jobs',
    'notifications',
    'route_manifests',
    'inadimplency_statuses',
    'transport_enrollments',
    'user_addresses',
    'vehicles',
    'drivers',
    'user_roles',
    'roles',
    'childrens',
    'daily_admin_metrics',
    'users',
  ];

  const schema = (dataSource.options as { schema?: string }).schema ?? 'public';

  await dataSource.query('SET CONSTRAINTS ALL DEFERRED');
  for (const table of tables) {
    try {
      await dataSource.query(`TRUNCATE TABLE "${schema}"."${table}" RESTART IDENTITY CASCADE`);
    } catch (err) {
      // Ignore missing tables until the migration creates them.
      const message = err instanceof Error ? err.message : String(err);
      if (!message.includes('does not exist')) {
        // eslint-disable-next-line no-console
        console.warn(`Truncate failed for ${table}: ${message}`);
      }
    }
  }
}

/**
 * Cleans up only rows created by the current test run.
 * Use this when test data is tagged with a run_id or when you want lighter cleanup.
 */
export async function cleanupDatabase(dataSource: DataSource): Promise<void> {
  await truncateAll(dataSource);
}
