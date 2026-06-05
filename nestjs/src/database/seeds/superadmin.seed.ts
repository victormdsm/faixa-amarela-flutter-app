import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../entities/user.entity';
import { Role } from '../entities/role.entity';
import { UserRole } from '../entities/user-role.entity';

/**
 * Seed a fake superadmin user for local development and testing.
 *
 * WARNING:
 *   - This is intentionally hardcoded for local/dev environments only.
 *   - In production, the superadmin must be created through a controlled
ndas:   *     onboarding process or a one-time secure seed, NEVER via a public endpoint.
 *   - The CPF and password below are fake values for development convenience.
 *   - Change these values or disable this seed in production.
 */
export const seedSuperadmin = async (dataSource: DataSource): Promise<void> => {
  const userRepository = dataSource.getRepository(User);
  const roleRepository = dataSource.getRepository(Role);
  const userRoleRepository = dataSource.getRepository(UserRole);

  const superadminEmail = 'superadmin@faixaamarela.dev';
  const superadminCpf = '00000000191'; // Fake CPF for local development only
  const superadminPassword = 'FaixaAmarela@SuperAdmin2026'; // CHANGE IN PRODUCTION

  const existing = await userRepository.findOne({ where: { email: superadminEmail } });
  if (existing) {
    console.log('[seed:superadmin] Superadmin user already exists');
    return;
  }

  const superadminRole = await roleRepository.findOne({ where: { code: 'superadmin' } });
  if (!superadminRole) {
    throw new Error('[seed:superadmin] Role "superadmin" not found. Run seed:roles first.');
  }

  const hashedPassword = await bcrypt.hash(superadminPassword, 10);

  const user = userRepository.create({
    name: 'Super Admin',
    email: superadminEmail,
    cpf: superadminCpf,
    password: hashedPassword,
    isActive: true,
    activatedAt: new Date(),
    role: 'superadmin',
    status: 1,
    isActivated: true,
    hasDriverProfile: false,
  });

  const savedUser = await userRepository.save(user);

  await userRoleRepository.save(
    userRoleRepository.create({
      userId: savedUser.id,
      roleId: superadminRole.id,
    }),
  );

  console.log(`[seed:superadmin] Created superadmin user id=${savedUser.id}`);
};
