import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'boarding_has_students', schema: 'faixaamarela_prod' })
export class BoardingStudent {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'idstudent', type: 'bigint' })
  studentId: number;

  @Column({ name: 'idboarding', type: 'bigint' })
  boardingId: number;

  @Column({ type: 'varchar', length: 30, nullable: true })
  status: string | null;

  @Column({ name: 'hour_boarding', type: 'varchar', length: 20, nullable: true })
  hourBoarding: string | null;

  @Column({ name: 'hour_landing', type: 'varchar', length: 20, nullable: true })
  hourLanding: string | null;

  @Column({ name: 'hour_boarding_school', type: 'varchar', length: 20, nullable: true })
  hourBoardingSchool: string | null;

  @Column({ name: 'hour_landing_house', type: 'varchar', length: 20, nullable: true })
  hourLandingHouse: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}
