import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'route_presets', schema: 'faixaamarela_prod' })
export class RoutePreset {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'driver_id', type: 'bigint' })
  driverId: number;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ name: 'operation_id', type: 'varchar', length: 100, nullable: true })
  operationId: string | null;

  @Column({ name: 'trip_mode', type: 'varchar', length: 50, nullable: true })
  tripMode: string | null;

  @Column({ type: 'json' })
  selections: Record<string, unknown>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
