import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'shifts', schema: 'faixaamarela_prod' })
export class Shift {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'shift_name', type: 'varchar', length: 100 })
  shiftName: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
