import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum NotificationType { GAME_INVITE = 'game_invite', MESSAGE = 'message', STREAK = 'streak', QUESTION = 'question', AI_INSIGHT = 'ai_insight', MEMORY = 'memory', SYSTEM = 'system' }

@Entity('notifications')
@Index(['userId', 'createdAt'])
export class Notification {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() userId: string;
  @Column({ type: 'enum', enum: NotificationType }) type: NotificationType;
  @Column() title: string;
  @Column({ type: 'text' }) body: string;
  @Column({ type: 'jsonb', nullable: true }) data: any;
  @Column({ default: false }) isRead: boolean;
  @Column({ nullable: true }) readAt: Date;
  @CreateDateColumn() createdAt: Date;
}
