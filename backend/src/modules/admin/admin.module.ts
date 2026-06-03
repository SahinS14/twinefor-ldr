import { Module, Injectable, Controller, Get, UseGuards, Req, ForbiddenException } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from '../../database/entities/user.entity';
import { Couple } from '../../database/entities/couple.entity';
import { Message } from '../../database/entities/message.entity';
import { GameSession } from '../../database/entities/game-session.entity';
import { Subscription } from '../../database/entities/subscription.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Couple) private couplesRepo: Repository<Couple>,
    @InjectRepository(Message) private messagesRepo: Repository<Message>,
    @InjectRepository(GameSession) private gamesRepo: Repository<GameSession>,
    @InjectRepository(Subscription) private subsRepo: Repository<Subscription>,
  ) {}

  async getDashboardStats() {
    const [totalUsers, totalCouples, totalMessages, totalGames, premiumCouples] = await Promise.all([
      this.usersRepo.count(),
      this.couplesRepo.count(),
      this.messagesRepo.count(),
      this.gamesRepo.count(),
      this.subsRepo.count({ where: { plan: 'together' as any } }),
    ]);
    return { totalUsers, totalCouples, totalMessages, totalGames, premiumCouples, generatedAt: new Date() };
  }

  async getUsers(page = 1, limit = 50) {
    const [users, total] = await this.usersRepo.findAndCount({ order: { createdAt: 'DESC' }, take: limit, skip: (page - 1) * limit, select: ['id', 'name', 'email', 'username', 'isOnline', 'level', 'xp', 'createdAt'] });
    return { users, total, page, pages: Math.ceil(total / limit) };
  }

  async getCouples(page = 1, limit = 50) {
    return this.couplesRepo.findAndCount({ order: { createdAt: 'DESC' }, take: limit, skip: (page - 1) * limit, relations: ['userA', 'userB'] });
  }
}

@UseGuards(JwtAuthGuard)
@Controller('admin')
export class AdminController {
  constructor(private svc: AdminService) {}

  private guard(req: any) { if (req.user.role !== UserRole.ADMIN) throw new ForbiddenException('Admin only'); }

  @Get('stats') stats(@Req() req) { this.guard(req); return this.svc.getDashboardStats(); }
  @Get('users') users(@Req() req) { this.guard(req); return this.svc.getUsers(); }
  @Get('couples') couples(@Req() req) { this.guard(req); return this.svc.getCouples(); }
}

@Module({
  imports: [TypeOrmModule.forFeature([User, Couple, Message, GameSession, Subscription])],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
