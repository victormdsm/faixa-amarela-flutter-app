import * as bcrypt from 'bcrypt';
import { DataSource, Repository } from 'typeorm';
import { generateCpf, uniqueCpf } from './cpf-helper';

// Use the entities created by the DBA / NestJS dev team.
import { User } from '../../src/database/entities/user.entity';
import { Role } from '../../src/database/entities/role.entity';
import { UserRole } from '../../src/database/entities/user-role.entity';
import { Child } from '../../src/database/entities/child.entity';
import { Driver } from '../../src/database/entities/driver.entity';
import { Vehicle } from '../../src/database/entities/vehicle.entity';
import { TransportEnrollment } from '../../src/database/entities/transport-enrollment.entity';
import { UserAddress } from '../../src/database/entities/user-address.entity';
import { Notification } from '../../src/database/entities/notification.entity';
import { NotificationJob } from '../../src/database/entities/notification-job.entity';
import { InadimplencyStatus } from '../../src/database/entities/inadimplency-status.entity';
import { RouteManifest } from '../../src/database/entities/route-manifest.entity';
import { DailyAdminMetric } from '../../src/database/entities/daily-admin-metric.entity';

export interface FactoryContext {
  dataSource: DataSource;
  usedCpfs?: Set<string>;
  usedEmails?: Set<string>;
}

export interface UserOptions {
  name?: string;
  email?: string;
  cpf?: string;
  password?: string;
  isActive?: boolean;
  activatedAt?: Date | null;
  cellPhone?: string;
}

export interface RoleOptions {
  code?: string;
  name?: string;
}

export interface ChildOptions {
  userId: number;
  name?: string;
  cpf?: string;
  schoolId?: number;
  shiftId?: number;
  relativeId?: number;
  planId?: number;
  status?: number;
}

export interface DriverOptions {
  userId: number;
  licenseNumber?: string;
  isActive?: boolean;
}

export interface VehicleOptions {
  driverId: number;
  ano?: string;
  cor?: string;
  placa?: string;
  marca?: string;
  imageUrl?: string;
}

export interface TransportEnrollmentOptions {
  driverUserId: number;
  childId: number;
  parentUserId: number;
  requestedByUserId?: number;
  status?: 'pending' | 'active' | 'rejected' | 'canceled' | 'inactive' | 'finished';
}

export interface AddressOptions {
  userId?: number;
  childId?: number;
  zipcode?: string;
  street?: string;
  number?: string;
  districtId?: number;
  cityId?: number;
  latitude?: number | string;
  longitude?: number | string;
  type?: string;
  isDefault?: boolean;
}

export interface NotificationOptions {
  userId: number;
  title?: string;
  body?: string;
  type?: string;
  data?: Record<string, unknown>;
  isRead?: boolean;
}

export interface NotificationJobOptions {
  notificationId?: string;
  userId?: number;
  channel?: string;
  payload?: Record<string, unknown>;
  maxAttempts?: number;
}

export interface InadimplencyOptions {
  childId: number;
  parentUserId?: number;
  clientId?: number;
  isInadimplent?: boolean;
  requestedIsInadimplent?: boolean;
  requestStatus?: string;
  requestedAt?: Date;
}

export interface RouteManifestOptions {
  routeId?: number;
  driverId: number;
  vanId?: number;
  shiftId?: number;
  status?: string;
  startedAt?: Date;
  document?: Record<string, unknown>;
  stops?: unknown[];
}

export interface DailyMetricOptions {
  metricDate: Date;
  totalUsers?: number;
  totalParents?: number;
  totalDrivers?: number;
  totalChildren?: number;
  totalActiveEnrollments?: number;
  totalPendingEnrollments?: number;
}

function repo<T extends object>(ctx: FactoryContext, entity: new () => T): Repository<T> {
  return ctx.dataSource.getRepository(entity) as Repository<T>;
}

function freshEmail(ctx: FactoryContext, prefix = 'user'): string {
  if (!ctx.usedEmails) ctx.usedEmails = new Set<string>();
  let email: string;
  do {
    email = `${prefix}.${Date.now()}.${Math.floor(Math.random() * 1_000_000)}@test.faixa`;
  } while (ctx.usedEmails.has(email));
  ctx.usedEmails.add(email);
  return email;
}

function freshCpf(ctx: FactoryContext): string {
  if (!ctx.usedCpfs) ctx.usedCpfs = new Set<string>();
  return uniqueCpf(ctx.usedCpfs);
}

export async function createUser(ctx: FactoryContext, opts: UserOptions = {}): Promise<User> {
  const userRepo = repo(ctx, User);
  const cpf = opts.cpf ?? freshCpf(ctx);
  const plainPassword = opts.password ?? 'Test@123456';
  const hash = await bcrypt.hash(plainPassword, 10);
  const user = userRepo.create({
    name: opts.name ?? `Test User ${Date.now()}`,
    email: opts.email ?? freshEmail(ctx, 'user'),
    cpf,
    password: hash,
    isActive: opts.isActive ?? true,
    activatedAt: opts.activatedAt === undefined ? new Date() : opts.activatedAt,
    cellPhone: opts.cellPhone ?? `119${String(Math.floor(Math.random() * 1e8)).padStart(8, '0')}`,
    role: 'user',
    status: 1,
    isActivated: false,
  });
  return userRepo.save(user);
}

export async function createRole(ctx: FactoryContext, opts: RoleOptions = {}): Promise<Role> {
  const roleRepo = repo(ctx, Role);
  const code = opts.code ?? `role_${Date.now()}_${Math.floor(Math.random() * 1e6)}`;
  const role = roleRepo.create({
    code,
    name: opts.name ?? code,
  });
  return roleRepo.save(role);
}

export async function assignRole(
  ctx: FactoryContext,
  userId: number,
  roleCode: string,
): Promise<UserRole> {
  const roleRepo = repo(ctx, Role);
  const userRoleRepo = repo(ctx, UserRole);
  let role = await roleRepo.findOne({ where: { code: roleCode } });
  if (!role) {
    role = await createRole(ctx, { code: roleCode, name: roleCode });
  }
  const userRole = userRoleRepo.create({ userId, roleId: role.id });
  return userRoleRepo.save(userRole);
}

export async function createUserWithRole(
  ctx: FactoryContext,
  roleCode: string,
  userOpts: UserOptions = {},
): Promise<{ user: User; role: Role; userRole: UserRole }> {
  const user = await createUser(ctx, userOpts);
  const userRole = await assignRole(ctx, user.id, roleCode);
  const role = await ctx.dataSource.getRepository(Role).findOneOrFail({ where: { id: userRole.roleId } });
  return { user, role, userRole };
}

export async function createChild(ctx: FactoryContext, opts: ChildOptions): Promise<Child> {
  const childRepo = repo(ctx, Child);
  const cpf = opts.cpf ?? freshCpf(ctx);
  const child = childRepo.create({
    userId: opts.userId,
    name: opts.name ?? `Child ${Date.now()}`,
    cpf,
    schoolId: opts.schoolId ?? 1,
    shiftId: opts.shiftId ?? 1,
    relativeId: opts.relativeId ?? 1,
    planId: opts.planId ?? 1,
    status: opts.status ?? 1,
  });
  return childRepo.save(child);
}

export async function createDriver(ctx: FactoryContext, opts: DriverOptions): Promise<Driver> {
  const driverRepo = repo(ctx, Driver);
  const driver = driverRepo.create({
    userId: opts.userId,
    cnh: opts.licenseNumber ?? `CNH${Date.now()}`,
    isActive: opts.isActive ?? true,
  });
  return driverRepo.save(driver);
}

export async function createVehicle(ctx: FactoryContext, opts: VehicleOptions): Promise<Vehicle> {
  const vehicleRepo = repo(ctx, Vehicle);
  const vehicle = vehicleRepo.create({
    driverId: opts.driverId,
    ano: opts.ano ?? '2020',
    cor: opts.cor ?? 'Branco',
    placa: opts.placa ?? `TES${String(Math.floor(Math.random() * 1e4)).padStart(4, '0')}`,
    marca: opts.marca ?? 'Marca Teste',
    imageUrl: opts.imageUrl ?? null,
  });
  return vehicleRepo.save(vehicle);
}

export async function createDriverWithVan(
  ctx: FactoryContext,
  userId: number,
): Promise<{ driver: Driver; vehicle: Vehicle }> {
  const driver = await createDriver(ctx, { userId });
  const vehicle = await createVehicle(ctx, { driverId: driver.id });
  return { driver, vehicle };
}

export async function createAdmin(ctx: FactoryContext, userOpts: UserOptions = {}) {
  return createUserWithRole(ctx, 'admin', userOpts);
}

export async function createSuperadmin(ctx: FactoryContext, userOpts: UserOptions = {}) {
  return createUserWithRole(ctx, 'superadmin', userOpts);
}

export async function createParent(
  ctx: FactoryContext,
  userOpts: UserOptions = {},
): Promise<{ user: User; role: Role; userRole: UserRole }> {
  return createUserWithRole(ctx, 'user', userOpts);
}

export async function createTransportEnrollment(
  ctx: FactoryContext,
  opts: TransportEnrollmentOptions,
): Promise<TransportEnrollment> {
  const enrollmentRepo = repo(ctx, TransportEnrollment);
  const enrollment = enrollmentRepo.create({
    driverUserId: opts.driverUserId,
    childId: opts.childId,
    parentUserId: opts.parentUserId,
    requestedByUserId: opts.requestedByUserId ?? opts.driverUserId,
    status: opts.status ?? 'pending',
    requestedAt: new Date(),
  });
  return enrollmentRepo.save(enrollment);
}

export async function createAddress(ctx: FactoryContext, opts: AddressOptions): Promise<UserAddress> {
  const addressRepo = repo(ctx, UserAddress);
  const address = addressRepo.create({
    userId: opts.userId ?? 0,
    childId: opts.childId ?? null,
    zipcode: opts.zipcode ?? '85851000',
    street: opts.street ?? 'Rua Teste',
    number: opts.number ?? '123',
    districtId: opts.districtId ?? 1,
    cityId: opts.cityId ?? 1,
    latitude: opts.latitude != null ? String(opts.latitude) : '-25.5',
    longitude: opts.longitude != null ? String(opts.longitude) : '-54.5',
    type: opts.type ?? 'home',
    isDefault: opts.isDefault ?? true,
    status: 1,
    mainAddress: 0,
  });
  return addressRepo.save(address);
}

export async function createNotification(
  ctx: FactoryContext,
  opts: NotificationOptions,
): Promise<Notification> {
  const notificationRepo = repo(ctx, Notification);
  const notification = notificationRepo.create({
    type: opts.type ?? 'generic',
    notifiableType: 'users',
    notifiableId: opts.userId,
    data: JSON.stringify({
      title: opts.title ?? 'Test notification',
      body: opts.body ?? 'Body',
      ...(opts.data ?? {}),
    }),
    readAt: opts.isRead ? new Date() : null,
  });
  return notificationRepo.save(notification);
}

export async function createNotificationJob(
  ctx: FactoryContext,
  opts: NotificationJobOptions = {},
): Promise<NotificationJob> {
  const jobRepo = repo(ctx, NotificationJob);
  const job = jobRepo.create({
    notificationId: opts.notificationId ?? null,
    userId: opts.userId ?? null,
    channel: opts.channel ?? 'push',
    payload: opts.payload ?? {},
    maxAttempts: opts.maxAttempts ?? 3,
    status: 'pending',
    attempts: 0,
    availableAt: new Date(),
  });
  return jobRepo.save(job);
}

export async function createInadimplencyRequest(
  ctx: FactoryContext,
  opts: InadimplencyOptions,
): Promise<InadimplencyStatus> {
  const repoIna = repo(ctx, InadimplencyStatus);
  const ina = repoIna.create({
    clientId: opts.clientId ?? 0,
    childId: opts.childId,
    parentUserId: opts.parentUserId ?? null,
    isInadimplent: opts.isInadimplent ?? false,
    requestedIsInadimplent: opts.requestedIsInadimplent ?? true,
    requestStatus: (opts.requestStatus as 'pending' | 'approved' | 'rejected') ?? 'pending',
    requestedAt: opts.requestedAt ?? new Date(),
  });
  return repoIna.save(ina);
}

export async function createRouteManifest(
  ctx: FactoryContext,
  opts: RouteManifestOptions,
): Promise<RouteManifest> {
  const manifestRepo = repo(ctx, RouteManifest);
  const manifest = manifestRepo.create({
    routeId: opts.routeId ?? 1,
    driverId: opts.driverId,
    vanId: opts.vanId ?? null,
    shiftId: opts.shiftId ?? null,
    status: opts.status ?? 'active',
    startedAt: opts.startedAt ?? new Date(),
    document: opts.document ?? {},
    stops: opts.stops ?? [],
  });
  return manifestRepo.save(manifest);
}

export async function createDailyMetric(
  ctx: FactoryContext,
  opts: DailyMetricOptions,
): Promise<DailyAdminMetric> {
  const metricRepo = repo(ctx, DailyAdminMetric);
  const metric = metricRepo.create({
    metricDate: opts.metricDate,
    totalUsers: opts.totalUsers ?? 0,
    totalParents: opts.totalParents ?? 0,
    totalDrivers: opts.totalDrivers ?? 0,
    totalChildren: opts.totalChildren ?? 0,
    totalActiveEnrollments: opts.totalActiveEnrollments ?? 0,
    totalPendingEnrollments: opts.totalPendingEnrollments ?? 0,
  });
  return metricRepo.save(metric);
}

// Re-export helpers
export { generateCpf, isValidCpf, uniqueCpf } from './cpf-helper';
