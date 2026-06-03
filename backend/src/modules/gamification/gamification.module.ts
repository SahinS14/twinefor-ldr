// ─── GAMIFICATION MODULE ─────────────────────────────────────────────
import { Module, Injectable, Controller, Get, Post, Body, UseGuards, Req } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { Couple } from '../../database/entities/couple.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RedisModule } from '../../config/redis.module';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

const XP_TABLE = { message: 2, game_complete: 30, question_answer: 10, streak: 20, memory: 5 };

@Injectable()
export class GamificationService {
  private LEVELS = [0,100,250,500,900,1400,2000,2800,3800,5000,7000,10000,15000,20000,30000];
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Couple) private couplesRepo: Repository<Couple>,
    @InjectRedis() private redis: Redis,
  ) {}

  async awardXp(userId: string, coupleId: string, action: keyof typeof XP_TABLE) {
    const xp = XP_TABLE[action] || 5;
    await this.usersRepo.increment({ id: userId }, 'xp', xp);
    if (coupleId) await this.couplesRepo.increment({ id: coupleId }, 'totalXp', xp);
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    const newLevel = this.calculateLevel(user.xp);
    if (newLevel > user.level) { await this.usersRepo.update(userId, { level: newLevel }); return { xp, levelUp: true, newLevel }; }
    return { xp, levelUp: false };
  }

  async checkAndUpdateStreak(coupleId: string) {
    const couple = await this.couplesRepo.findOne({ where: { id: coupleId } });
    if (!couple) return;
    const today = new Date().toDateString();
    const last = couple.lastStreakDate ? new Date(couple.lastStreakDate).toDateString() : null;
    if (last === today) return couple.streakDays;
    const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1);
    couple.streakDays = last === yesterday.toDateString() ? couple.streakDays + 1 : 1;
    couple.lastStreakDate = new Date();
    await this.couplesRepo.save(couple);
    return couple.streakDays;
  }

  async getProfile(userId: string, coupleId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    const couple = coupleId ? await this.couplesRepo.findOne({ where: { id: coupleId } }) : null;
    return { xp: user.xp, level: user.level, streakDays: couple?.streakDays || 0, totalXp: couple?.totalXp || 0, nextLevelXp: this.LEVELS[Math.min(user.level, this.LEVELS.length - 1)] };
  }

  private calculateLevel(xp: number) {
    for (let i = this.LEVELS.length - 1; i >= 0; i--) { if (xp >= this.LEVELS[i]) return i + 1; }
    return 1;
  }
}

@UseGuards(JwtAuthGuard)
@Controller('gamification')
export class GamificationController {
  constructor(private svc: GamificationService) {}
  @Get('profile') profile(@Req() req) { return this.svc.getProfile(req.user.id, req.user.coupleId); }
  @Post('streak') streak(@Req() req) { return this.svc.checkAndUpdateStreak(req.user.coupleId); }
}

@Module({ imports: [TypeOrmModule.forFeature([User, Couple]), RedisModule], controllers: [GamificationController], providers: [GamificationService], exports: [GamificationService] })
export class GamificationModule {}
