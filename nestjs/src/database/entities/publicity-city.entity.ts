import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
} from 'typeorm';

@Entity({ name: 'publicities_has_cities', schema: 'faixaamarela_prod' })
export class PublicityCity {
  @PrimaryGeneratedColumn('increment')
  id: number;

  @Column({ name: 'publicity_id', type: 'bigint' })
  publicityId: number;

  @Column({ name: 'city_id', type: 'bigint' })
  cityId: number;
}
