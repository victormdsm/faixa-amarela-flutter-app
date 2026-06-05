import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'route_manifests', schema: 'faixaamarela_prod' })
export class RouteManifest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'route_id', type: 'bigint' })
  routeId: number;

  @Column({ name: 'driver_id', type: 'bigint' })
  driverId: number;

  @Column({ name: 'van_id', type: 'bigint', nullable: true })
  vanId: number | null;

  @Column({ name: 'boarding_id', type: 'bigint', nullable: true })
  boardingId: number | null;

  @Column({ type: 'varchar', default: 'active' })
  status: string;

  @Column({ name: 'started_at', type: 'timestamptz' })
  startedAt: Date;

  @Column({ name: 'finished_at', type: 'timestamptz', nullable: true })
  finishedAt: Date | null;

  @Column({ type: 'json', nullable: true })
  meta: Record<string, unknown> | null;

  @Column({ name: 'shift_id', type: 'bigint', nullable: true })
  shiftId: number | null;

  @Column({ type: 'jsonb', default: {} })
  document: Record<string, unknown>;

  @Column({ type: 'jsonb', default: [] })
  stops: unknown[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
