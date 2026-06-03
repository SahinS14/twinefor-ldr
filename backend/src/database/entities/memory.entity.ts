import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, DeleteDateColumn, Index } from 'typeorm';

@Entity('memories')
@Index(['coupleId', 'createdAt'])
export class Memory {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() coupleId: string;
  @Column() createdById: string;
  @Column() title: string;
  @Column({ nullable: true, type: 'text' }) description: string;
  @Column({ nullable: true }) mediaUrl: string;
  @Column({ nullable: true }) location: string;
  @Column({ nullable: true, type: 'date' }) memoryDate: Date;
  @Column({ type: 'simple-array', nullable: true }) tags: string[];
  @Column({ default: false }) isFavorite: boolean;

  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
  @DeleteDateColumn() deletedAt: Date;
}
