import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, DeleteDateColumn, OneToMany, Index } from 'typeorm';
import { Exclude } from 'class-transformer';

export enum LoveLanguage { WORDS = 'words', TOUCH = 'touch', GIFTS = 'gifts', TIME = 'time', ACTS = 'acts' }
export enum UserRole { USER = 'user', ADMIN = 'admin' }

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid') id: string;

  @Index({ unique: true })
  @Column({ unique: true }) email: string;

  @Index({ unique: true })
  @Column({ unique: true }) username: string;

  @Column() name: string;

  @Exclude()
  @Column({ nullable: true }) passwordHash: string;

  @Column({ nullable: true }) avatarUrl: string;
  @Column({ nullable: true }) bio: string;
  @Column({ nullable: true, type: 'date' }) birthday: Date;
  @Column({ nullable: true }) phone: string;
  @Column({ type: 'simple-array', nullable: true }) interests: string[];
  @Column({ type: 'enum', enum: LoveLanguage, nullable: true }) loveLanguage: LoveLanguage;
  @Column({ type: 'enum', enum: UserRole, default: UserRole.USER }) role: UserRole;
  @Column({ nullable: true }) moodStatus: string;
  @Column({ nullable: true }) themePreference: string;
  @Column({ default: false }) isEmailVerified: boolean;
  @Column({ nullable: true }) googleId: string;
  @Column({ nullable: true }) appleId: string;
  @Column({ nullable: true }) fcmToken: string;
  @Column({ nullable: true }) lastSeen: Date;
  @Column({ default: false }) isOnline: boolean;
  @Column({ default: 0 }) xp: number;
  @Column({ default: 1 }) level: number;
  @Column({ default: 0 }) streakDays: number;
  @Column({ nullable: true }) lastStreakDate: Date;
  @Column({ nullable: true }) coupleId: string;

  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
  @DeleteDateColumn() deletedAt: Date;
}
