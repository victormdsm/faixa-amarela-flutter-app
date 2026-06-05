import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type TransportEnrollmentStatus =
  | 'pending'
  | 'active'
  | 'rejected'
  | 'canceled'
  | 'inactive'
  | 'finished';

@Entity({ name: 'transport_enrollments', schema: 'faixaamarela_prod' })
export class TransportEnrollment {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ name: 'driver_user_id', type: 'bigint' })
  driverUserId: number;

  @Column({ name: 'child_id', type: 'bigint' })
  childId: number;

  @Column({ name: 'parent_user_id', type: 'bigint', nullable: true })
  parentUserId: number | null;

  @Column({ type: 'varchar', default: 'pending' })
  status: TransportEnrollmentStatus;

  @Column({ name: 'requested_by_user_id', type: 'bigint', nullable: true })
  requestedByUserId: number | null;

  @Column({ name: 'accepted_by_user_id', type: 'bigint', nullable: true })
  acceptedByUserId: number | null;

  @Column({ name: 'rejected_by_user_id', type: 'bigint', nullable: true })
  rejectedByUserId: number | null;

  @Column({ name: 'canceled_by_user_id', type: 'bigint', nullable: true })
  canceledByUserId: number | null;

  @Column({
    name: 'inadimplency_warning_ack',
    type: 'boolean',
    default: false,
  })
  inadimplencyWarningAck: boolean;

  @Column({
    name: 'inadimplency_warning_ack_at',
    type: 'timestamp',
    nullable: true,
  })
  inadimplencyWarningAckAt: Date | null;

  @Column({ type: 'text', nullable: true })
  notes: string | null;

  @Column({ name: 'requested_at', type: 'timestamp', nullable: true })
  requestedAt: Date | null;

  @Column({ name: 'accepted_at', type: 'timestamp', nullable: true })
  acceptedAt: Date | null;

  @Column({ name: 'rejected_at', type: 'timestamp', nullable: true })
  rejectedAt: Date | null;

  @Column({ name: 'canceled_at', type: 'timestamp', nullable: true })
  canceledAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
