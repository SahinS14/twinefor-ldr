import { Module, Injectable, Controller, Get, Post, Body, UseGuards, Req, Logger } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Subscription, SubscriptionPlan, SubscriptionStatus } from '../../database/entities/subscription.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RedisModule } from '../../config/redis.module';

@Injectable()
export class SubscriptionsService {
  private readonly logger = new Logger(SubscriptionsService.name);
  constructor(
    @InjectRepository(Subscription) private repo: Repository<Subscription>,
    private config: ConfigService,
  ) {}

  async getStatus(coupleId: string) {
    let sub = await this.repo.findOne({ where: { coupleId } });
    if (!sub) {
      sub = this.repo.create({ coupleId, plan: SubscriptionPlan.FREE, status: SubscriptionStatus.ACTIVE });
      await this.repo.save(sub);
    }
    return sub;
  }

  async isPremium(coupleId: string) {
    const sub = await this.getStatus(coupleId);
    return sub.plan === SubscriptionPlan.TOGETHER && (sub.status === SubscriptionStatus.ACTIVE || sub.status === SubscriptionStatus.TRIAL);
  }

  async startTrial(coupleId: string) {
    const sub = await this.getStatus(coupleId);
    if (sub.plan !== SubscriptionPlan.FREE) return { error: 'Trial already used or already premium' };
    const trialEnd = new Date(); trialEnd.setDate(trialEnd.getDate() + 7);
    sub.plan = SubscriptionPlan.TOGETHER;
    sub.status = SubscriptionStatus.TRIAL;
    sub.trialEnd = trialEnd;
    await this.repo.save(sub);
    return { message: 'Free trial started! 7 days of premium.', trialEnd };
  }

  async createCheckoutSession(coupleId: string, userId: string) {
    const stripeKey = this.config.get('STRIPE_SECRET_KEY');
    if (!stripeKey) return { url: 'https://buy.stripe.com/test_placeholder', message: 'Configure STRIPE_SECRET_KEY to enable payments' };
    // Stripe checkout session creation — wire up in production
    return { url: `https://twine.app/subscribe?couple=${coupleId}`, message: 'Stripe integration ready — add STRIPE_SECRET_KEY' };
  }

  async handleWebhook(payload: any, signature: string) {
    this.logger.log(`Stripe webhook: ${payload.type}`);
    if (payload.type === 'customer.subscription.created' || payload.type === 'invoice.paid') {
      const coupleId = payload.data?.object?.metadata?.coupleId;
      if (coupleId) {
        const sub = await this.getStatus(coupleId);
        sub.plan = SubscriptionPlan.TOGETHER;
        sub.status = SubscriptionStatus.ACTIVE;
        sub.currentPeriodEnd = new Date(payload.data.object.current_period_end * 1000);
        await this.repo.save(sub);
      }
    }
  }
}

@UseGuards(JwtAuthGuard)
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private svc: SubscriptionsService) {}
  @Get('status') status(@Req() req) { return this.svc.getStatus(req.user.coupleId); }
  @Post('trial') trial(@Req() req) { return this.svc.startTrial(req.user.coupleId); }
  @Post('checkout') checkout(@Req() req) { return this.svc.createCheckoutSession(req.user.coupleId, req.user.id); }
}

@Module({ imports: [TypeOrmModule.forFeature([Subscription]), RedisModule], controllers: [SubscriptionsController], providers: [SubscriptionsService], exports: [SubscriptionsService] })
export class SubscriptionsModule {}
