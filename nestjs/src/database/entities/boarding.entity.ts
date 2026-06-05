import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'boarding', schema: 'faixaamarela_prod' })
export class Boarding {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'idroute', type: 'bigint' })
  routeId: number;

  @Column({ name: 'date_boarding', type: 'date' })
  dateBoarding: string;

  @Column({ name: 'hour_boarding', type: 'varchar', length: 20, nullable: true })
  hourBoarding: string | null;

  @Column({ type: 'varchar', length: 30, default: 'started' })
  status: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
