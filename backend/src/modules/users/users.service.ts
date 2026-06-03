import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { UpdateUserDto } from './dto/update-user.dto';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private repo: Repository<User>,
    @InjectRedis() private redis: Redis,
  ) {}

  async findById(id: string) {
    const cached = await this.redis.get(`user:${id}`);
    if (cached) return JSON.parse(cached);
    const user = await this.repo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    await this.redis.setex(`user:${id}`, 300, JSON.stringify(this.sanitize(user)));
    return this.sanitize(user);
  }

  async findByUsername(username: string) {
    const user = await this.repo.findOne({ where: { username } });
    if (!user) throw new NotFoundException('User not found');
    return this.sanitize(user);
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.repo.update(id, dto as any);
    await this.redis.del(`user:${id}`);
    return this.findById(id);
  }

  async updateFcmToken(userId: string, token: string) {
    await this.repo.update(userId, { fcmToken: token });
    await this.redis.del(`user:${userId}`);
  }

  async setOnlineStatus(userId: string, isOnline: boolean) {
    await this.repo.update(userId, { isOnline, lastSeen: new Date() });
    await this.redis.setex(`presence:${userId}`, 300, isOnline ? '1' : '0');
    await this.redis.del(`user:${userId}`);
  }

  async deleteAccount(userId: string) {
    await this.repo.softDelete(userId);
    await this.redis.del(`user:${userId}`);
    await this.redis.del(`refresh:${userId}`);
    return { message: 'Account scheduled for deletion. Data will be fully removed in 30 days.' };
  }

  async getPresence(userId: string) {
    const online = await this.redis.get(`presence:${userId}`);
    const user = await this.repo.findOne({ where: { id: userId }, select: ['lastSeen', 'isOnline'] });
    return { isOnline: online === '1', lastSeen: user?.lastSeen };
  }

  sanitize(user: User) {
    const { passwordHash, ...safe } = user as any;
    return safe;
  }
}
