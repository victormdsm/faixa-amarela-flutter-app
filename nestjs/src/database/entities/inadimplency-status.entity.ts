import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export type InadimplencyRequestStatus =
  | 'pending'
  | 'approved'
  | 'rejected';

@Entity({ name: 'inadimplency_statuses', schema: 'faixaamarela_prod' })
export class InadimplencyStatus {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ name: 'client_id', type: 'bigint' })
  clientId: number;

  @Column({ name: 'is_inadimplent', type: 'boolean', default: false })
  isInadimplent: boolean;

  @Column({ type: 'text', nullable: true })
  reason: string | null;

  @Column({ name: 'marked_at', type: 'timestamp', nullable: true })
  markedAt: Date | null;

  @Column({ name: 'marked_by_admin_id', type: 'bigint', nullable: true })
  markedByAdminId: number | null;

  @Column({ name: 'resolved_at', type: 'timestamp', nullable: true })
  resolvedAt: Date | null;

  @Column({ type: 'numeric', nullable: true })
  amount: number | null;

  @Column({ name: 'marked_by_driver_id', type: 'bigint', nullable: true })
  markedByDriverId: number | null;

  @Column({ name: 'request_status', type: 'varchar', default: 'approved' })
  requestStatus: InadimplencyRequestStatus;

  @Column({
    name: 'requested_is_inadimplent',
    type: 'boolean',
    nullable: true,
  })
  requestedIsInadimplent: boolean | null;

  @Column({ name: 'requested_amount', type: 'numeric', nullable: true })
  requestedAmount: number | null;

  @Column({ name: 'requested_reason', type: 'varchar', nullable: true })
  requestedReason: string | null;

  @Column({ name: 'requested_at', type: 'timestamp', nullable: true })
  requestedAt: Date | null;

  @Column({ name: 'review_note', type: 'varchar', nullable: true })
  reviewNote: string | null;

  @Column({ name: 'reviewed_at', type: 'timestamp', nullable: true })
  reviewedAt: Date | null;

  @Column({ name: 'reviewed_by_admin_id', type: 'bigint', nullable: true })
  reviewedByAdminId: number | null;

  @Column({ name: 'child_id', type: 'bigint', nullable: true })
  childId: number | null;

  @Column({ name: 'parent_user_id', type: 'bigint', nullable: true })
  parentUserId: number | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
