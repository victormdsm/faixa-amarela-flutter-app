import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddActivatedAtAndDailyMetrics1717600000000
  implements MigrationInterface
{
  name = 'AddActivatedAtAndDailyMetrics1717600000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE faixaamarela_prod.users
        ADD COLUMN IF NOT EXISTS activated_at timestamp without time zone NULL;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS faixaamarela_prod.daily_admin_metrics (
        id bigserial PRIMARY KEY,
        metric_date date NOT NULL UNIQUE,
        total_users bigint NOT NULL DEFAULT 0,
        total_parents bigint NOT NULL DEFAULT 0,
        total_drivers bigint NOT NULL DEFAULT 0,
        total_children bigint NOT NULL DEFAULT 0,
        total_active_enrollments bigint NOT NULL DEFAULT 0,
        total_pending_enrollments bigint NOT NULL DEFAULT 0,
        total_active_routes bigint NOT NULL DEFAULT 0,
        total_finished_routes bigint NOT NULL DEFAULT 0,
        total_boardings bigint NOT NULL DEFAULT 0,
        total_disembarkings bigint NOT NULL DEFAULT 0,
        total_inadimplent_children bigint NOT NULL DEFAULT 0,
        total_pending_requests bigint NOT NULL DEFAULT 0,
        total_publicity_clicks bigint NOT NULL DEFAULT 0,
        total_publicity_impressions bigint NOT NULL DEFAULT 0,
        created_at timestamp without time zone DEFAULT now(),
        updated_at timestamp without time zone DEFAULT now(),
        deleted_at timestamp without time zone NULL
      );
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP TABLE IF EXISTS faixaamarela_prod.daily_admin_metrics;
    `);
    await queryRunner.query(`
      ALTER TABLE faixaamarela_prod.users
        DROP COLUMN IF EXISTS activated_at;
    `);
  }
}
