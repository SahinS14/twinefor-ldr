import { Injectable, BadRequestException, UnauthorizedException, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { v4 as uuidv4 } from 'uuid';
import { User } from '../../database/entities/user.entity';
import { RegisterDto, LoginDto, ForgotPasswordDto, ResetPasswordDto, ChangePasswordDto } from './dto/auth.dto';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    private jwtService: JwtService,
    private configService: ConfigService,
    @InjectRedis() private redis: Redis,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.usersRepo.findOne({ where: [{ email: dto.email }, { username: dto.username }] });
    if (existing) {
      if (existing.email === dto.email) throw new ConflictException('Email already registered');
      throw new ConflictException('Username already taken');
    }
    const passwordHash = await argon2.hash(dto.password, { type: argon2.argon2id, memoryCost: 65536, timeCost: 3, parallelism: 4 });
    const user = this.usersRepo.create({ email: dto.email, name: dto.name, username: dto.username.toLowerCase(), passwordHash });
    await this.usersRepo.save(user);
    const tokens = await this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);
    return { user: this.sanitizeUser(user), ...tokens };
  }

  async login(dto: LoginDto) {
    const user = await this.usersRepo.findOne({ where: { email: dto.email } });
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid credentials');
    const valid = await argon2.verify(user.passwordHash, dto.password);
    if (!valid) throw new UnauthorizedException('Invalid credentials');
    user.lastSeen = new Date();
    user.isOnline = true;
    await this.usersRepo.save(user);
    const tokens = await this.generateTokens(user);
    await this.storeRefreshToken(user.id, tokens.refreshToken);
    return { user: this.sanitizeUser(user), ...tokens };
  }

  async refreshTokens(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, { secret: this.configService.get('JWT_REFRESH_SECRET') || 'twine-refresh-secret' });
      const stored = await this.redis.get(`refresh:${payload.sub}`);
      if (!stored || stored !== refreshToken) throw new UnauthorizedException('Refresh token invalid or reused');
      const user = await this.usersRepo.findOne({ where: { id: payload.sub } });
      if (!user) throw new UnauthorizedException();
      const tokens = await this.generateTokens(user);
      await this.storeRefreshToken(user.id, tokens.refreshToken);
      return tokens;
    } catch {
      throw new UnauthorizedException('Refresh token expired or invalid');
    }
  }

  async logout(userId: string) {
    await this.redis.del(`refresh:${userId}`);
    await this.usersRepo.update(userId, { isOnline: false, lastSeen: new Date() });
    return { message: 'Logged out successfully' };
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user?.passwordHash) throw new BadRequestException('Cannot change password for OAuth accounts');
    const valid = await argon2.verify(user.passwordHash, dto.currentPassword);
    if (!valid) throw new UnauthorizedException('Current password incorrect');
    user.passwordHash = await argon2.hash(dto.newPassword, { type: argon2.argon2id });
    await this.usersRepo.save(user);
    await this.redis.del(`refresh:${userId}`);
    return { message: 'Password changed. Please log in again.' };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.usersRepo.findOne({ where: { email: dto.email } });
    if (!user) return { message: 'If that email exists, a reset link was sent.' };
    const token = uuidv4();
    await this.redis.setex(`reset:${token}`, 3600, user.id);
    // TODO: send email via nodemailer
    console.log(`[DEV] Password reset token for ${dto.email}: ${token}`);
    return { message: 'If that email exists, a reset link was sent.' };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const userId = await this.redis.get(`reset:${dto.token}`);
    if (!userId) throw new BadRequestException('Reset token invalid or expired');
    const user = await this.usersRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException();
    user.passwordHash = await argon2.hash(dto.newPassword, { type: argon2.argon2id });
    await this.usersRepo.save(user);
    await this.redis.del(`reset:${dto.token}`);
    return { message: 'Password reset successfully' };
  }

  private async generateTokens(user: User) {
    const payload = { sub: user.id, email: user.email, role: user.role };
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, { secret: this.configService.get('JWT_SECRET') || 'twine-dev-secret', expiresIn: '15m' }),
      this.jwtService.signAsync(payload, { secret: this.configService.get('JWT_REFRESH_SECRET') || 'twine-refresh-secret', expiresIn: '7d' }),
    ]);
    return { accessToken, refreshToken };
  }

  private async storeRefreshToken(userId: string, token: string) {
    await this.redis.setex(`refresh:${userId}`, 604800, token);
  }

  sanitizeUser(user: User) {
    const { passwordHash, ...safe } = user as any;
    return safe;
  }
}
