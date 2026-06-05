# DBA Sênior - Atualização de Banco de Dados

**Data:** 2026-06-05
**Agente:** DBA Sênior

## O que foi entregue

### Configuração TypeORM
- `src/config/database.config.ts` - lê do `.env`, `synchronize=false`, schema `faixaamarela_prod`, SSL configurável.
- `src/database/data-source.ts` - DataSource CLI com `dotenv` carregado automaticamente.
- `src/common/entities/index.ts` - barrel exportando todas as entidades do `src/database/entities`.

### Migrations executadas com sucesso no `laravel-db`

| Arquivo | Objetivo |
|---------|----------|
| `1717600000000-AddActivatedAtAndDailyMetrics.ts` (existente) | Adiciona `users.activated_at` e cria `daily_admin_metrics` |
| `20260605172109-add-soft-delete-to-core-tables.ts` | Adiciona `deleted_at` em `childrens`, `transport_enrollments`, `vehicles`, `user_addresses`, `route_manifests`, `notifications` |
| `20260605172110-ensure-single-active-van-per-driver.ts` | Índice parcial único `vehicles_driver_active_unique` em `(driver_id) WHERE deleted_at IS NULL` |

### Entities criadas

Principais:
- `User`, `Role`, `UserRole`
- `Child`, `TransportEnrollment`, `InadimplencyStatus`
- `UserAddress`, `Vehicle`, `RouteManifest`
- `Notification`, `NotificationJob`, `DailyAdminMetric`

Catálogos/auxiliares:
- `School`, `Shift`, `Plan`, `Province`, `City`, `District`, `Publicity`, `PublicityCity`
- `Driver`, `DriverProfileChangeRequest`, `VehicleImage`, `RoutePreset`
- `Boarding`, `BoardingStudent`, `RawTelemetry`
- `UserActivationToken`, `PasswordResetToken`, `Route`
- `UserHasSchool`, `UserHasDistrict`, `UserHasSchoolShift`, `UserDistrictShift`

### Seeds
- `src/database/seeds/roles.seed.ts` - garante roles `user`, `driver`, `admin`, `superadmin`, `parent`.
- `src/database/seeds/superadmin.seed.ts` - cria superadmin fake para dev/test (`superadmin@faixaamarela.dev`).
- `src/database/seeds/run-seeds.ts` - runner.

Seed executado com sucesso: superadmin criado com `id=727`.

### Documentação
- `src/database/MIGRATION_NOTES.md` - decisões, como rodar migrations, regras de CPF, próximos passos.

### Correções auxiliares
- `test/fixtures/factories.ts` - ajuste de tipos genéricos para `Repository<T>`.
- `test/helpers/database.ts` - cast de `DataSourceOptions` para acessar `schema`.
- `src/modules/notifications/notifications.service.ts` - uso de `IsNull()` no `readAt` para build passar.

## Decisões importantes

1. **Van ativa por motorista**: usa soft delete. A van ativa é aquela com `deleted_at IS NULL`. Quando admin cadastra nova van, o service deve soft-deletar a van ativa anterior. Índice parcial único garante isso no banco.

2. **CPF duplicado**: NÃO foi adicionado UNIQUE em `users.cpf`. O banco legado ainda tem duplicatas. A deduplicação é um próximo passo explícito.

3. **Não dropar legado**: todas as migrations são aditivas. Tabelas legadas (`clients`, `client_driver_relationships`, etc.) permanecem intactas.

4. **Soft delete**: adicionado `deleted_at` nas tabelas novas/finais. Hard delete desabilitado via aplicação.

## Como usar localmente

```bash
cd /Users/victormatheusdesouzamuller/Documents/faixa-amarela-dev/nestjs

# Rodar migrations (o DB_HOST pode precisar ser localhost se não estiver dentro do Docker)
DB_HOST=localhost DB_PASSWORD='a@V1tr&}1MjT' npm run migration:run

# Rodar seeds
DB_HOST=localhost DB_PASSWORD='a@V1tr&}1MjT' npm run seed:run

# Gerar nova migration a partir das entities
DB_HOST=localhost DB_PASSWORD='a@V1tr&}1MjT' npm run migration:generate -- src/database/migrations/NomeDaMigration
```

## Bloqueios

Nenhum. O build (`npm run build`) passa, as migrations executam e as seeds funcionam.

## Próximos passos recomendados

1. **Dev NestJS**: integrar as entidades nos modules via `TypeOrmModule.forFeature([...])`.
2. **Dev NestJS**: implementar a regra de soft-delete da van ativa no serviço de criação de motorista/van.
3. **QA**: usar banco de testes separado (`faixaamarela_prod_test`) e rodar `migration:run` + `seed:run` no setup de e2e.
4. **DBA futuro**: criar migration/script de deduplicação de CPF e só então adicionar UNIQUE.
