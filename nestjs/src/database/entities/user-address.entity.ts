import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'user_addresses', schema: 'faixaamarela_prod' })
export class UserAddress {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ type: 'varchar' })
  zipcode: string;

  @Column({ type: 'varchar' })
  street: string;

  @Column({ type: 'varchar' })
  number: string;

  @Column({ type: 'varchar', nullable: true })
  reference: string | null;

  @Column({ type: 'varchar', nullable: true })
  latitude: string | null;

  @Column({ type: 'varchar', nullable: true })
  longitude: string | null;

  @Column({ name: 'main_address', type: 'int', default: 0 })
  mainAddress: number;

  @Column({ name: 'district_id', type: 'bigint' })
  districtId: number;

  @Column({ name: 'city_id', type: 'bigint' })
  cityId: number;

  @Column({ name: 'user_id', type: 'bigint' })
  userId: number;

  @Column({ type: 'int', default: 1 })
  status: number;

  @Column({ name: 'child_id', type: 'bigint', nullable: true })
  childId: number | null;

  @Column({ type: 'varchar', default: 'home' })
  type: string;

  @Column({ name: 'is_default', type: 'boolean', default: false })
  isDefault: boolean;

  @Column({ type: 'geography', nullable: true })
  location: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
