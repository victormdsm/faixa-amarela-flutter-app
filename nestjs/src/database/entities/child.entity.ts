import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity({ name: 'childrens', schema: 'faixaamarela_prod' })
export class Child {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ name: 'user_id', type: 'bigint' })
  userId: number;

  @Column({ name: 'relative_id', type: 'bigint' })
  relativeId: number;

  @Column({ type: 'varchar', nullable: true })
  name: string | null;

  @Column({ type: 'varchar', nullable: true })
  avatar: string | null;

  @Column({ type: 'varchar', nullable: true })
  sex: string | null;

  @Column({ type: 'int', nullable: true })
  age: number | null;

  @Column({ type: 'int', default: 1 })
  status: number;

  @Column({ name: 'school_id', type: 'bigint', nullable: true })
  schoolId: number | null;

  @Column({ name: 'plan_id', type: 'bigint', nullable: true })
  planId: number | null;

  @Column({ name: 'shift_id', type: 'bigint', nullable: true })
  shiftId: number | null;

  @Column({ name: 'is_inadimplent', type: 'boolean', default: false })
  isInadimplent: boolean;

  @Column({ type: 'varchar', nullable: true })
  cpf: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.children)
  @JoinColumn({ name: 'user_id' })
  parent: User;
}
