import { DataSource } from 'typeorm';
import { Role } from '../entities/role.entity';

/**
 * Seed the core roles expected by the NestJS application.
 *
 * Roles:
 *   - user       : public responsible account
 *   - driver     : driver account
 *   - admin      : operational admin
 *   - superadmin : super administrator (created by seed only)
 *
 * The legacy 'parent' role is kept as a compatibility entry if needed,
 * but the NestJS API should use 'user' for new responsible accounts.
 */
export const seedRoles = async (dataSource: DataSource): Promise<void> => {
  const roleRepository = dataSource.getRepository(Role);

  const roles = [
    { code: 'user', name: 'User' },
    { code: 'driver', name: 'Driver' },
    { code: 'admin', name: 'Administrator' },
    { code: 'superadmin', name: 'Superadmin' },
    { code: 'parent', name: 'Parent (legacy)' },
  ];

  for (const role of roles) {
    const existing = await roleRepository.findOne({ where: { code: role.code } });
    if (!existing) {
      await roleRepository.save(roleRepository.create(role));
      console.log(`[seed:roles] Created role "${role.code}"`);
    } else {
      console.log(`[seed:roles] Role "${role.code}" already exists`);
    }
  }
};
