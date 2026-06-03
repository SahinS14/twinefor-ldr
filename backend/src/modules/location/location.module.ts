// ─── LOCATION MODULE ─────────────────────────────────────────────────
import { Module, Injectable, Controller, Get, Post, Body, UseGuards, Req } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LocationLog } from '../../database/entities/location.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RedisModule } from '../../config/redis.module';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

@Injectable()
export class LocationService {
  constructor(
    @InjectRepository(LocationLog) private repo: Repository<LocationLog>,
    @InjectRedis() private redis: Redis,
  ) {}

  async updateLocation(userId: string, coupleId: string, lat: number, lng: number, note?: string) {
    const log = this.repo.create({ userId, coupleId, latitude: lat, longitude: lng, note });
    await this.repo.save(log);
    await this.redis.setex(`location:${userId}`, 600, JSON.stringify({ lat, lng, note, updatedAt: new Date() }));
    return log;
  }

  async getPartnerLocation(coupleId: string, myUserId: string) {
    const keys = await this.redis.keys(`location:*`);
    return { message: 'Location updates via WebSocket — use location:update event' };
  }

  async getLocationHistory(coupleId: string) {
    return this.repo.find({ where: { coupleId }, order: { createdAt: 'DESC' }, take: 100 });
  }
}

@UseGuards(JwtAuthGuard)
@Controller('location')
export class LocationController {
  constructor(private svc: LocationService) {}
  @Post('update')
  update(@Req() req, @Body() dto: { lat: number; lng: number; note?: string }) {
    return this.svc.updateLocation(req.user.id, req.user.coupleId, dto.lat, dto.lng, dto.note);
  }
  @Get('history') history(@Req() req) { return this.svc.getLocationHistory(req.user.coupleId); }
}

@Module({ imports: [TypeOrmModule.forFeature([LocationLog]), RedisModule], controllers: [LocationController], providers: [LocationService], exports: [LocationService] })
export class LocationModule {}
