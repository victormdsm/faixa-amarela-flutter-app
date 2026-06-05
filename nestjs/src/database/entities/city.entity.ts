import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Province } from './province.entity';

@Entity({ name: 'cities', schema: 'faixaamarela_prod' })
export class City {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ type: 'varchar', length: 100 })
  name: string;

  @Column({ name: 'ibge_code', type: 'bigint' })
  ibgeCode: number;

  @Column({ name: 'province_id', type: 'bigint' })
  provinceId: number;

  @ManyToOne(() => Province)
  @JoinColumn({ name: 'province_id' })
  province: Province;
}
