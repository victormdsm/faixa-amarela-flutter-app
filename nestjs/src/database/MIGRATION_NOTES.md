# Migration Notes - NestJS Database Layer

## Overview

This document describes the database changes applied by the TypeORM migrations in
`src/database/migrations/` for the Faixa Amarela NestJS migration.

All migrations are **additive**. No legacy tables were dropped and no legacy
data was deleted.

---

## Migrations Created

### 1. `20260605172107-add-users-activated-at`

Adds the `activated_at` column to `users`:

- `activated_at timestamp without time zone NULL`
- Partial index on `activated_at`

This replaces the legacy `is_activated` / `activation_token` flow as the source
of truth for account confirmation. A user is considered fully active when:

```text
is_active = true
activated_at IS NOT NULL
```

### 2. `20260605172108-create-daily-admin-metrics`

Creates the `daily_admin_metrics` aggregated table for the admin reports module.

Columns:

- `id bigserial PRIMARY KEY`
- `metric_date date NOT NULL UNIQUE`
- `total_users`, `total_parents`, `total_drivers`, `total_children`
- `total_active_enrollments`, `total_pending_enrollments`
- `total_active_routes`, `total_finished_routes`
- `total_boardings`, `total_disembarkings`
- `total_inadimplent_children`, `total_pending_requests`
- `total_publicity_clicks`, `total_publicity_impressions`
- `created_at`, `updated_at`, `deleted_at`

This table must be populated by a worker; the `reports/overview` endpoint should
read from it instead of scanning operational tables.

### 3. `20260605172109-add-soft-delete-to-core-tables`

Adds `deleted_at` to the core operational tables used by NestJS:

- `childrens`
- `transport_enrollments`
- `vehicles`
- `user_addresses`
- `route_manifests`
- `notifications`

Hard delete is disabled at the application layer. Repositories should use
TypeORM's soft-remove / restore methods where applicable.

### 4. `20260605172110-ensure-single-active-van-per-driver`

Enforces the business rule: **one active van per driver**.

Decision:

- An "active" van is defined as `deleted_at IS NULL`.
- When an admin registers a new van for a driver, the application must
  soft-delete any existing active van for that driver before inserting the new
  one. This keeps historical manifests intact because they store the `van_id`
  used at the time.
- A partial unique index guarantees this at the database level:

```sql
CREATE UNIQUE INDEX vehicles_driver_active_unique
ON vehicles (driver_id) WHERE deleted_at IS NULL;
```

Application services that create vans for drivers must call a helper such as:

```ts
await vehicleRepository.softDelete({ driverId, deletedAt: IsNull() });
```

before saving the new active van.

---

## Entities

All TypeORM entities are located in `src/database/entities/` and map the
`faixaamarela_prod` schema.

Principal entities:

- `User` (`users`)
- `Role` (`roles`)
- `UserRole` (`user_roles`)
- `Child` (`childrens`)
- `TransportEnrollment` (`transport_enrollments`)
- `InadimplencyStatus` (`inadimplency_statuses`)
- `UserAddress` (`user_addresses`)
- `Vehicle` (`vehicles`)
- `RouteManifest` (`route_manifests`)
- `Notification` (`notifications`)
- `NotificationJob` (`notification_jobs`)
- `DailyAdminMetric` (`daily_admin_metrics`)

Catalog / auxiliary entities:

- `School`, `Shift`, `Plan`
- `Province`, `City`, `District`
- `Publicity`, `PublicityCity`
- `Driver`, `DriverProfileChangeRequest`
- `VehicleImage`, `RoutePreset`
- `Boarding`, `BoardingStudent`
- `RawTelemetry`
- `UserActivationToken`, `PasswordResetToken`
- `Route`, `UserHasSchool`, `UserHasDistrict`, `UserHasSchoolShift`, `UserDistrictShift`

---

## Data Sensitivity

- `users.cpf` is marked as sensitive in entity documentation and should **never**
  be logged or returned in DTOs without explicit authorization.
- `users.password`, `users.remember_token`, `user_activation_tokens.token_hash`,
  and `password_reset_tokens.token` must also never be logged.
- Sentry must not receive CPF, password, token, or raw `notification_jobs.payload`.

---

## Deduplication of `users.cpf`

The legacy database contains duplicate CPFs. **Do not add a UNIQUE constraint on
`users.cpf` until the deduplication migration is complete.**

Planned flow (to be executed later by a dedicated migration task):

1. List duplicate CPFs.
2. Pick a canonical user for each CPF (prefer the one with `activated_at`,
   active children, and/or driver profile).
3. Migrate roles and relations to the canonical user.
4. Soft-delete or disable duplicates (`is_active = false`).
5. Add the UNIQUE constraint or a partial unique index when safe.

---

## Running Migrations Locally

Prerequisites:

- PostgreSQL running (e.g., Docker container `laravel-db`).
- `.env` configured with `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_SCHEMA`,
  `DB_USERNAME`, `DB_PASSWORD`.

Commands:

```bash
# Run pending migrations
npm run migration:run

# Revert the last migration
npm run migration:revert

# Generate a new migration from entity changes
npm run migration:generate -- src/database/migrations/MyMigrationName

# Run seeds (roles + fake superadmin)
npm run seed:run
```

---

## Notes for Other Agents

- **Dev NestJS**: use `buildDataSourceOptions()` from `src/config/database.config.ts`
  and the entity barrel in `src/database/entities/index.ts` when wiring
  `TypeOrmModule.forRootAsync`.
- **QA**: e2e tests should use a separate test database (e.g.,
  `faixaamarela_prod_test`) created from the same migrations. Reset via
  `DROP SCHEMA ... CASCADE` + `migration:run` between test suites.
- **Backend sync folder**: place coordination notes in `docs/agent-sync/`.

---

## Next Steps / Blockers

- [ ] Create a dedicated deduplication migration/script for `users.cpf`.
- [ ] Validate FKs marked as `NOT VALID` after legacy data cleanup.
- [ ] Implement the daily metrics worker that populates `daily_admin_metrics`.
- [ ] Decide retention policy for `raw_telemetry` and implement it (e.g.,
      TimescaleDB retention or scheduled DELETE).
- [ ] Confirm whether `parent` legacy role should be migrated to `user`.
- [ ] Confirm whether `client_driver_relationships` will be migrated to
      `transport_enrollments` or kept as read-only legacy.
