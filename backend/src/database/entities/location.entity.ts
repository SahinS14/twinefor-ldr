import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('location_logs')
@Index(['userId', 'createdAt'])
export class LocationLog {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() userId: string;
  @Column() coupleId: string;
  @Column({ type: 'decimal', precision: 10, scale: 7 }) latitude: number;
  @Column({ type: 'decimal', precision: 10, scale: 7 }) longitude: number;
  @Column({ nullable: true }) address: string;
  @Column({ nullable: true }) note: string;
  @Column({ default: true }) isSharing: boolean;
  @Column({ nullable: true }) expiresAt: Date;
  @CreateDateColumn() createdAt: Date;
}
