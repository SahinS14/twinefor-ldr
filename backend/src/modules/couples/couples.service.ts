import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Couple, CoupleStatus } from '../../database/entities/couple.entity';
import { User } from '../../database/entities/user.entity';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

@Injectable()
export class CouplesService {
  constructor(
    @InjectRepository(Couple) private repo: Repository<Couple>,
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRedis() private redis: Redis,
  ) {}

  async generateInvite(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (user.coupleId) {
      const couple = await this.repo.findOne({ where: { id: user.coupleId } });
      if (couple?.status === CoupleStatus.ACTIVE) throw new ConflictException('Already in a couple');
    }
    const code = this.generateCode();
    await this.redis.setex(`invite:${code}`, 86400, userId); // 24h TTL
    return { code, link: `https://twine.app/pair/${code}`, expiresIn: '24 hours' };
  }

  async acceptInvite(code: string, acceptorId: string) {
    const inviterId = await this.redis.get(`invite:${code}`);
    if (!inviterId) throw new NotFoundException('Invite code invalid or expired');
    if (inviterId === acceptorId) throw new BadRequestException('Cannot pair with yourself');

    const inviter = await this.usersRepo.findOne({ where: { id: inviterId } });
    const acceptor = await this.usersRepo.findOne({ where: { id: acceptorId } });
    if (!inviter || !acceptor) throw new NotFoundException('User not found');

    // Check both are unpaired
    if (inviter.coupleId || acceptor.coupleId) throw new ConflictException('One or both users already in a couple');

    const couple = this.repo.create({
      userAId: inviterId, userBId: acceptorId,
      status: CoupleStatus.ACTIVE, startedAt: new Date() as any,
    });
    await this.repo.save(couple);

    // Link both users
    await this.usersRepo.update(inviterId, { coupleId: couple.id });
    await this.usersRepo.update(acceptorId, { coupleId: couple.id });
    await this.redis.del(`invite:${code}`);

    return { couple, message: `You're now paired with ${inviter.name}! 💕` };
  }

  async getMyCouple(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user?.coupleId) throw new NotFoundException('You are not in a couple yet');
    const couple = await this.repo.findOne({
      where: { id: user.coupleId },
      relations: ['userA', 'userB'],
    });
    if (!couple) throw new NotFoundException('Couple not found');
    // Sanitize passwords
    if (couple.userA) delete (couple.userA as any).passwordHash;
    if (couple.userB) delete (couple.userB as any).passwordHash;
    return couple;
  }

  async unpair(userId: string) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user?.coupleId) throw new BadRequestException('Not in a couple');
    const couple = await this.repo.findOne({ where: { id: user.coupleId } });
    couple.status = CoupleStatus.ENDED;
    await this.repo.save(couple);
    await this.usersRepo.update(couple.userAId, { coupleId: null });
    await this.usersRepo.update(couple.userBId, { coupleId: null });
    await this.redis.del(`couple:${couple.id}`);
    return { message: 'Unpaired successfully' };
  }

  async updateBondScore(coupleId: string, delta: number) {
    const couple = await this.repo.findOne({ where: { id: coupleId } });
    if (!couple) return;
    couple.bondScore = Math.min(100, Math.max(0, couple.bondScore + delta));
    await this.repo.save(couple);
    await this.redis.set(`bond:${coupleId}`, couple.bondScore.toString());
  }

  async updateStreak(coupleId: string) {
    const couple = await this.repo.findOne({ where: { id: coupleId } });
    if (!couple) return;
    const today = new Date().toDateString();
    const lastDate = couple.lastStreakDate ? new Date(couple.lastStreakDate).toDateString() : null;
    if (lastDate === today) return;
    const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1);
    const wasYesterday = lastDate === yesterday.toDateString();
    couple.streakDays = wasYesterday ? couple.streakDays + 1 : 1;
    couple.lastStreakDate = new Date();
    await this.repo.save(couple);
    return couple.streakDays;
  }

  async getStats(coupleId: string) {
    const couple = await this.repo.findOne({ where: { id: coupleId } });
    if (!couple) throw new NotFoundException();
    const daysTogether = couple.startedAt
      ? Math.floor((Date.now() - new Date(couple.startedAt).getTime()) / 86400000) : 0;
    return { bondScore: couple.bondScore, streakDays: couple.streakDays, totalXp: couple.totalXp, daysTogether };
  }

  private generateCode() {
    const words = ['ROSE', 'LOVE', 'STAR', 'MOON', 'KISS', 'DEAR', 'WARM', 'SOUL'];
    const word = words[Math.floor(Math.random() * words.length)];
    const num = Math.floor(1000 + Math.random() * 9000);
    return `${word}-${num}`;
  }
}
