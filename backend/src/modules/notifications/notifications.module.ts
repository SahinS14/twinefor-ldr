import { Module, Injectable, Controller, Get, Post, Body, Param, UseGuards, Req, Logger } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification, NotificationType } from '../../database/entities/notification.entity';
import { User } from '../../database/entities/user.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RedisModule } from '../../config/redis.module';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  constructor(
    @InjectRepository(Notification) private repo: Repository<Notification>,
    @InjectRepository(User) private usersRepo: Repository<User>,
  ) {}

  async create(userId: string, type: NotificationType, title: string, body: string, data?: any) {
    const notification = this.repo.create({ userId, type, title, body, data });
    await this.repo.save(notification);
    await this.sendPush(userId, title, body, data);
    return notification;
  }

  async getAll(userId: string) {
    return this.repo.find({ where: { userId }, order: { createdAt: 'DESC' }, take: 50 });
  }

  async markRead(id: string, userId: string) {
    await this.repo.update({ id, userId }, { isRead: true, readAt: new Date() });
    return { success: true };
  }

  async markAllRead(userId: string) {
    await this.repo.update({ userId, isRead: false }, { isRead: true, readAt: new Date() });
    return { success: true };
  }

  async getUnreadCount(userId: string) {
    return { count: await this.repo.count({ where: { userId, isRead: false } }) };
  }

  private async sendPush(userId: string, title: string, body: string, data?: any) {
    const user = await this.usersRepo.findOne({ where: { id: userId }, select: ['fcmToken'] });
    if (!user?.fcmToken) return;
    // FCM push — integrate firebase-admin in production
    this.logger.debug(`[FCM] To: ${userId} | ${title}: ${body}`);
  }
}

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private svc: NotificationsService) {}
  @Get() getAll(@Req() req) { return this.svc.getAll(req.user.id); }
  @Get('unread') unread(@Req() req) { return this.svc.getUnreadCount(req.user.id); }
  @Post(':id/read') markRead(@Req() req, @Param('id') id: string) { return this.svc.markRead(id, req.user.id); }
  @Post('read-all') markAllRead(@Req() req) { return this.svc.markAllRead(req.user.id); }
}

@Module({ imports: [TypeOrmModule.forFeature([Notification, User]), RedisModule], controllers: [NotificationsController], providers: [NotificationsService], exports: [NotificationsService] })
export class NotificationsModule {}
