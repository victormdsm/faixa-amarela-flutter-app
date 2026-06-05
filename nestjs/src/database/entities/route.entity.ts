import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'routes', schema: 'faixaamarela_prod' })
export class Route {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'iduser', type: 'bigint' })
  userId: number;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 20 })
  hour: string;

  @Column({ type: 'smallint', default: 0 })
  type: number;

  @Column({ type: 'varchar', length: 30, default: 'idle' })
  status: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
