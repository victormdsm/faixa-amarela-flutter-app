import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { Notification } from '../../database/entities/notification.entity';
import { NotificationJob } from '../../database/entities/notification-job.entity';
import { NotificationResponseDto } from './dto/notification-response.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
    @InjectRepository(NotificationJob)
    private readonly jobRepo: Repository<NotificationJob>,
  ) {}

  async create(
    userId: number,
    type: string,
    data: Record<string, unknown>,
  ): Promise<NotificationResponseDto> {
    const id = uuidv4();
    const notification = this.notificationRepo.create({
      id,
      type,
      notifiableType: 'App\\Models\\User',
      notifiableId: userId,
      data: JSON.stringify(data),
    });
    const saved = await this.notificationRepo.save(notification);

    await this.jobRepo.save(
      this.jobRepo.create({
        notificationId: saved.id,
        userId,
        channel: 'push',
        status: 'pending',
        payload: data,
      }),
    );

    return this.mapNotification(saved);
  }

  async listByUser(userId: number): Promise<NotificationResponseDto[]> {
    const items = await this.notificationRepo.find({
      where: { notifiableId: userId },
      order: { createdAt: 'DESC' },
    });
    return items.map((n) => this.mapNotification(n));
  }

  async unreadCount(userId: number): Promise<number> {
    return this.notificationRepo.count({
      where: { notifiableId: userId, readAt: IsNull() },
    });
  }

  async markRead(userId: number, id: string): Promise<void> {
    const notification = await this.notificationRepo.findOne({
      where: { id, notifiableId: userId },
    });
    if (!notification) {
      throw new NotFoundException('Notificação não encontrada.');
    }
    notification.readAt = new Date();
    await this.notificationRepo.save(notification);
  }

  async markAllRead(userId: number): Promise<void> {
    await this.notificationRepo.update(
      { notifiableId: userId, readAt: IsNull() },
      { readAt: new Date() },
    );
  }

  private mapNotification(n: Notification): NotificationResponseDto {
    return {
      id: n.id,
      type: n.type,
      data: n.data,
      readAt: n.readAt,
      createdAt: n.createdAt,
    };
  }
}
