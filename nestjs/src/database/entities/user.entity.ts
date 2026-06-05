import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { UserRole } from './user-role.entity';
import { Child } from './child.entity';

@Entity({ name: 'users', schema: 'faixaamarela_prod' })
export class User {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'varchar' })
  name: string;

  @Column({ type: 'varchar', unique: true })
  email: string;

  @Column({ name: 'email_verified_at', type: 'timestamp', nullable: true })
  emailVerifiedAt: Date | null;

  @Column({ name: 'cell_phone', type: 'varchar', nullable: true })
  cellPhone: string | null;

  @Column({ type: 'varchar', nullable: true })
  imei: string | null;

  @Column({ type: 'varchar' })
  cpf: string;

  @Column({ type: 'varchar' })
  password: string;

  @Column({ name: 'remember_token', type: 'varchar', nullable: true })
  rememberToken: string | null;

  @Column({ type: 'varchar' })
  role: string;

  @Column({ type: 'varchar', nullable: true })
  avatar: string | null;

  @Column({ type: 'varchar', nullable: true })
  sex: string | null;

  @Column({ type: 'int', default: 1 })
  status: number;

  @Column({ name: 'device_token', type: 'varchar', nullable: true })
  deviceToken: string | null;

  @Column({ name: 'is_activated', type: 'boolean', default: false })
  isActivated: boolean;

  @Column({ name: 'activation_token', type: 'varchar', nullable: true })
  activationToken: string | null;

  @Column({ name: 'activation_expires_at', type: 'timestamp', nullable: true })
  activationExpiresAt: Date | null;

  @Column({ name: 'primary_driver_id', type: 'bigint', nullable: true })
  primaryDriverId: number | null;

  @Column({ type: 'jsonb', nullable: true, default: [] })
  roles: string[];

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @Column({ name: 'has_driver_profile', type: 'boolean', default: false })
  hasDriverProfile: boolean;

  @Column({ name: 'avatar_url', type: 'varchar', nullable: true })
  avatarUrl: string | null;

  @Column({ name: 'activated_at', type: 'timestamp', nullable: true })
  activatedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;

  @OneToMany(() => UserRole, (userRole) => userRole.user)
  userRoles: UserRole[];

  @OneToMany(() => Child, (child) => child.parent)
  children: Child[];
}
