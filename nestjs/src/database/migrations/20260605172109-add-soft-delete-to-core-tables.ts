import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Add deleted_at (soft delete) to core tables used by the NestJS application.
 *
 * Tables covered:
 *   - childrens
 *   - transport_enrollments
 *   - vehicles
 *   - user_addresses
 *   - route_manifests
 *   - notifications
 *
 * This migration is additive and does not drop legacy tables or data.
 */
export class AddSoftDeleteToCoreTables20260605172109 implements MigrationInterface {
  name = 'AddSoftDeleteToCoreTables20260605172109';

  private async addDeletedAt(queryRunner: QueryRunner, table: string): Promise<void> {
    const exists = await queryRunner.query(`
      SELECT 1
      FROM information_schema.columns
      WHERE table_schema = 'faixaamarela_prod'
        AND table_name = '${table}'
        AND column_name = 'deleted_at';
    `);

    if (!exists || exists.length === 0) {
      await queryRunner.query(`
        ALTER TABLE faixaamarela_prod.${table}
        ADD COLUMN deleted_at timestamp without time zone NULL;
      `);
    }
  }

  private async dropDeletedAt(queryRunner: QueryRunner, table: string): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE faixaamarela_prod.${table}
      DROP COLUMN IF EXISTS deleted_at;
    `);
  }

  public async up(queryRunner: QueryRunner): Promise<void> {
    const tables = [
      'childrens',
      'transport_enrollments',
      'vehicles',
      'user_addresses',
      'route_manifests',
      'notifications',
    ];

    for (const table of tables) {
      await this.addDeletedAt(queryRunner, table);
    }
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const tables = [
      'notifications',
      'route_manifests',
      'user_addresses',
      'vehicles',
      'transport_enrollments',
      'childrens',
    ];

    for (const table of tables) {
      await this.dropDeletedAt(queryRunner, table);
    }
  }
}
