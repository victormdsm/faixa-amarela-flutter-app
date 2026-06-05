import {
  Entity,
  Column,
  PrimaryColumn,
} from 'typeorm';

/**
 * raw_telemetry entity.
 *
 * TimescaleDB-style narrow table for historical telemetry.
 * No soft-delete: retention policy should be applied separately.
 */
@Entity({ name: 'raw_telemetry', schema: 'faixaamarela_prod' })
export class RawTelemetry {
  @PrimaryColumn({ name: 'van_id', type: 'bigint' })
  vanId: number;

  @PrimaryColumn({ name: 'route_manifest_id', type: 'uuid' })
  routeManifestId: string;

  @PrimaryColumn({ type: 'timestamptz' })
  timestamp: Date;

  @Column({ type: 'geometry', spatialFeatureType: 'Point', srid: 4326 })
  location: string;

  @Column({ type: 'smallint', nullable: true })
  speed: number | null;

  @Column({ type: 'smallint', nullable: true })
  heading: number | null;
}
