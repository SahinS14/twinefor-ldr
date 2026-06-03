import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum SubscriptionPlan { FREE = 'free', TOGETHER = 'together' }
export enum SubscriptionStatus { ACTIVE = 'active', CANCELLED = 'cancelled', EXPIRED = 'expired', TRIAL = 'trial' }

@Entity('subscriptions')
export class Subscription {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Index() @Column() coupleId: string;
  @Column({ type: 'enum', enum: SubscriptionPlan, default: SubscriptionPlan.FREE }) plan: SubscriptionPlan;
  @Column({ type: 'enum', enum: SubscriptionStatus, default: SubscriptionStatus.ACTIVE }) status: SubscriptionStatus;
  @Column({ nullable: true }) stripeSubscriptionId: string;
  @Column({ nullable: true }) stripeCustomerId: string;
  @Column({ nullable: true }) currentPeriodEnd: Date;
  @Column({ nullable: true }) trialEnd: Date;
  @Column({ nullable: true }) cancelledAt: Date;
  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
}
