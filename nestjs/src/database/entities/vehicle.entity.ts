import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'vehicles', schema: 'faixaamarela_prod' })
export class Vehicle {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ name: 'driver_id', type: 'bigint' })
  driverId: number;

  @Column({ type: 'varchar' })
  ano: string;

  @Column({ type: 'varchar' })
  cor: string;

  @Column({ type: 'varchar' })
  placa: string;

  @Column({ type: 'varchar' })
  marca: string;

  @Column({ name: 'image_url', type: 'varchar', nullable: true })
  imageUrl: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
