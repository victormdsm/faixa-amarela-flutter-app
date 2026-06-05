import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'daily_admin_metrics', schema: 'faixaamarela_prod' })
export class DailyAdminMetric {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id: number;

  @Column({ name: 'metric_date', type: 'date', unique: true })
  metricDate: Date;

  @Column({ name: 'total_users', type: 'bigint', default: 0 })
  totalUsers: number;

  @Column({ name: 'total_parents', type: 'bigint', default: 0 })
  totalParents: number;

  @Column({ name: 'total_drivers', type: 'bigint', default: 0 })
  totalDrivers: number;

  @Column({ name: 'total_children', type: 'bigint', default: 0 })
  totalChildren: number;

  @Column({ name: 'total_active_enrollments', type: 'bigint', default: 0 })
  totalActiveEnrollments: number;

  @Column({ name: 'total_pending_enrollments', type: 'bigint', default: 0 })
  totalPendingEnrollments: number;

  @Column({ name: 'total_active_routes', type: 'bigint', default: 0 })
  totalActiveRoutes: number;

  @Column({ name: 'total_finished_routes', type: 'bigint', default: 0 })
  totalFinishedRoutes: number;

  @Column({ name: 'total_boardings', type: 'bigint', default: 0 })
  totalBoardings: number;

  @Column({ name: 'total_disembarkings', type: 'bigint', default: 0 })
  totalDisembarkings: number;

  @Column({ name: 'total_inadimplent_children', type: 'bigint', default: 0 })
  totalInadimplentChildren: number;

  @Column({ name: 'total_pending_requests', type: 'bigint', default: 0 })
  totalPendingRequests: number;

  @Column({ name: 'total_publicity_clicks', type: 'bigint', default: 0 })
  totalPublicityClicks: number;

  @Column({ name: 'total_publicity_impressions', type: 'bigint', default: 0 })
  totalPublicityImpressions: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;

  @Column({ name: 'deleted_at', type: 'timestamp', nullable: true })
  deletedAt: Date | null;
}
