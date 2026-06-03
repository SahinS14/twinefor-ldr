import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, DeleteDateColumn, Index } from 'typeorm';

export enum MessageType { TEXT = 'text', IMAGE = 'image', VOICE = 'voice', GIF = 'gif', REACTION = 'reaction', SYSTEM = 'system' }

@Entity('messages')
@Index(['coupleId', 'createdAt'])
export class Message {
  @PrimaryGeneratedColumn('uuid') id: string;

  @Index()
  @Column() coupleId: string;

  @Column() senderId: string;
  @Column({ type: 'text', nullable: true }) content: string;
  @Column({ type: 'enum', enum: MessageType, default: MessageType.TEXT }) type: MessageType;
  @Column({ nullable: true }) mediaUrl: string;
  @Column({ nullable: true }) replyToId: string;
  @Column({ nullable: true }) reactedWith: string;
  @Column({ default: false }) isRead: boolean;
  @Column({ nullable: true }) readAt: Date;
  @Column({ default: false }) isEdited: boolean;
  @Column({ nullable: true }) expiresAt: Date;
  @Column({ default: false }) isPinned: boolean;
  @Column({ nullable: true }) scheduledAt: Date;

  @CreateDateColumn() createdAt: Date;
  @UpdateDateColumn() updatedAt: Date;
  @DeleteDateColumn() deletedAt: Date;
}
