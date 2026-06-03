import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum QuestionCategory { ROMANTIC = 'romantic', DEEP = 'deep', FUNNY = 'funny', FUTURE = 'future', INTIMATE = 'intimate' }

@Entity('daily_questions')
export class DailyQuestion {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ type: 'text' }) question: string;
  @Column({ type: 'enum', enum: QuestionCategory, default: QuestionCategory.DEEP }) category: QuestionCategory;
  @Column({ default: false }) isAiGenerated: boolean;
  @CreateDateColumn() createdAt: Date;
}

@Entity('question_answers')
@Index(['coupleId', 'questionId'])
export class QuestionAnswer {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() coupleId: string;
  @Column() userId: string;
  @Column() questionId: string;
  @Column({ type: 'text' }) answer: string;
  @Column({ nullable: true }) aiInsight: string;
  @CreateDateColumn() createdAt: Date;
}
