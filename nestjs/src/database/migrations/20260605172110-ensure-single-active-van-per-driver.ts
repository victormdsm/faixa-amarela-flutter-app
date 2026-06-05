import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Enforce the business rule: one active van per driver.
 *
 * Decision:
 *   - "active" means deleted_at IS NULL.
 *   - When an admin registers a new van for a driver, the service layer must
 *     soft-delete (set deleted_at = now()) the driver's previous active van(s).
 *   - Historical manifests keep the van_id they used, so history is preserved.
 *
 * This migration adds a partial unique index to enforce one active van per
 * driver at the database level. It also creates an index to quickly locate a
 * driver's active van.
 */
export class EnsureSingleActiveVanPerDriver20260605172110 implements MigrationInterface {
  name = 'EnsureSingleActiveVanPerDriver20260605172110';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS vehicles_driver_active_unique
      ON faixaamarela_prod.vehicles (driver_id)
      WHERE deleted_at IS NULL;
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS vehicles_driver_deleted_at_index
      ON faixaamarela_prod.vehicles (driver_id, deleted_at);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS faixaamarela_prod.vehicles_driver_deleted_at_index;
    `);

    await queryRunner.query(`
      DROP INDEX IF EXISTS faixaamarela_prod.vehicles_driver_active_unique;
    `);
  }
}
