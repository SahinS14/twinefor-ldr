import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum GameType { CHESS = 'chess', LUDO = 'ludo', TIC_TAC_TOE = 'tic_tac_toe', TRUTH_OR_DARE = 'truth_or_dare', QUIZ = 'quiz' }
export enum GameStatus { WAITING = 'waiting', ACTIVE = 'active', COMPLETED = 'completed', ABANDONED = 'abandoned' }

@Entity('game_sessions')
@Index(['coupleId', 'createdAt'])
export class GameSession {
  @PrimaryGeneratedColumn('uuid') id: string;

  @Index()
  @Column() coupleId: string;

  @Column() hostId: string;
  @Column({ type: 'enum', enum: GameType }) gameType: GameType;
  @Column({ type: 'enum', enum: GameStatus, default: GameStatus.WAITING }) status: GameStatus;
  @Column({ type: 'jsonb', nullable: true }) stateSnapshot: any;
  @Column({ nullable: true }) winnerId: string;
  @Column({ default: 0 }) xpAwarded: number;
  @Column({ default: 0 }) moveCount: number;
  @Column({ nullable: true }) endedAt: Date;

  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
}
