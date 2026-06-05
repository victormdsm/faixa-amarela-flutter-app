import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

@Entity({ name: 'driver_profile_change_requests', schema: 'faixaamarela_prod' })
export class DriverProfileChangeRequest {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'driver_user_id', type: 'bigint' })
  driverUserId: number;

  @Column({ name: 'requested_by_user_id', type: 'bigint' })
  requestedByUserId: number;

  @Column({ type: 'varchar', length: 30, default: 'pending' })
  status: string;

  @Column({ name: 'requested_school_ids', type: 'json', nullable: true })
  requestedSchoolIds: number[] | null;

  @Column({ name: 'requested_district_shift_map', type: 'json', nullable: true })
  requestedDistrictShiftMap: Record<string, unknown> | null;

  @Column({ name: 'current_school_ids', type: 'json', nullable: true })
  currentSchoolIds: number[] | null;

  @Column({ name: 'current_district_shift_map', type: 'json', nullable: true })
  currentDistrictShiftMap: Record<string, unknown> | null;

  @Column({ name: 'request_note', type: 'text', nullable: true })
  requestNote: string | null;

  @Column({ name: 'review_note', type: 'text', nullable: true })
  reviewNote: string | null;

  @Column({ name: 'reviewed_by_admin_id', type: 'bigint', nullable: true })
  reviewedByAdminId: number | null;

  @Column({ name: 'reviewed_at', type: 'timestamp', nullable: true })
  reviewedAt: Date | null;

  @Column({ name: 'requested_avatar_path', type: 'varchar', length: 500, nullable: true })
  requestedAvatarPath: string | null;

  @Column({ name: 'current_avatar_path', type: 'varchar', length: 500, nullable: true })
  currentAvatarPath: string | null;

  @Column({ name: 'requested_vehicle_image_path', type: 'varchar', length: 500, nullable: true })
  requestedVehicleImagePath: string | null;

  @Column({ name: 'current_vehicle_image_path', type: 'varchar', length: 500, nullable: true })
  currentVehicleImagePath: string | null;

  @Column({ name: 'vehicle_id', type: 'bigint', nullable: true })
  vehicleId: number | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'driver_user_id' })
  driver: User;
}
