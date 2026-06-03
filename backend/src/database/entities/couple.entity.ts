import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { User } from './user.entity';

export enum CoupleStatus { PENDING = 'pending', ACTIVE = 'active', ENDED = 'ended' }

@Entity('couples')
export class Couple {
  @PrimaryGeneratedColumn('uuid') id: string;

  @Column() userAId: string;
  @Column() userBId: string;

  @ManyToOne(() => User) @JoinColumn({ name: 'userAId' }) userA: User;
  @ManyToOne(() => User) @JoinColumn({ name: 'userBId' }) userB: User;

  @Column({ type: 'enum', enum: CoupleStatus, default: CoupleStatus.PENDING }) status: CoupleStatus;
  @Column({ nullable: true, type: 'date' }) startedAt: Date;
  @Column({ nullable: true }) inviteCode: string;
  @Column({ default: 0 }) bondScore: number;
  @Column({ default: 0 }) totalXp: number;
  @Column({ default: 0 }) streakDays: number;
  @Column({ nullable: true }) lastStreakDate: Date;

  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
}
