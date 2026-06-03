import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan, IsNull } from 'typeorm';
import { Message, MessageType } from '../../database/entities/message.entity';
import { InjectRedis } from '../../common/decorators/redis.decorator';
import Redis from 'ioredis';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Message) private repo: Repository<Message>,
    @InjectRedis() private redis: Redis,
  ) {}

  async sendMessage(coupleId: string, senderId: string, content: string, type: MessageType = MessageType.TEXT, extra?: Partial<Message>) {
    const message = this.repo.create({ coupleId, senderId, content, type, ...extra });
    await this.repo.save(message);
    // Cache latest 50 messages per couple
    const key = `messages:${coupleId}`;
    await this.redis.lpush(key, JSON.stringify(message));
    await this.redis.ltrim(key, 0, 49);
    await this.redis.expire(key, 3600);
    return message;
  }

  async getMessages(coupleId: string, userId: string, cursor?: string, limit = 30) {
    // Try Redis cache for first page
    if (!cursor) {
      const cached = await this.redis.lrange(`messages:${coupleId}`, 0, limit - 1);
      if (cached.length >= limit) {
        const messages = cached.map(m => JSON.parse(m));
        return { messages, nextCursor: messages[messages.length - 1]?.id, hasMore: cached.length >= limit };
      }
    }

    const where: any = { coupleId, deletedAt: IsNull() };
    if (cursor) {
      const ref = await this.repo.findOne({ where: { id: cursor } });
      if (ref) where.createdAt = LessThan(ref.createdAt);
    }

    const [messages, total] = await this.repo.findAndCount({
      where, order: { createdAt: 'DESC' }, take: limit + 1,
    });

    const hasMore = messages.length > limit;
    const result = hasMore ? messages.slice(0, limit) : messages;
    return { messages: result.reverse(), nextCursor: hasMore ? result[0]?.id : null, hasMore };
  }

  async markRead(coupleId: string, userId: string) {
    await this.repo.createQueryBuilder()
      .update(Message)
      .set({ isRead: true, readAt: new Date() })
      .where('coupleId = :coupleId AND senderId != :userId AND isRead = false', { coupleId, userId })
      .execute();
    await this.redis.del(`messages:${coupleId}`);
    return { success: true };
  }

  async editMessage(messageId: string, userId: string, content: string) {
    const msg = await this.repo.findOne({ where: { id: messageId } });
    if (!msg) throw new NotFoundException();
    if (msg.senderId !== userId) throw new ForbiddenException();
    msg.content = content;
    msg.isEdited = true;
    await this.repo.save(msg);
    await this.redis.del(`messages:${msg.coupleId}`);
    return msg;
  }

  async deleteMessage(messageId: string, userId: string) {
    const msg = await this.repo.findOne({ where: { id: messageId } });
    if (!msg) throw new NotFoundException();
    if (msg.senderId !== userId) throw new ForbiddenException();
    await this.repo.softDelete(messageId);
    await this.redis.del(`messages:${msg.coupleId}`);
    return { success: true };
  }

  async reactToMessage(messageId: string, userId: string, emoji: string) {
    const msg = await this.repo.findOne({ where: { id: messageId } });
    if (!msg) throw new NotFoundException();
    msg.reactedWith = emoji;
    await this.repo.save(msg);
    return msg;
  }

  async pinMessage(messageId: string, userId: string) {
    const msg = await this.repo.findOne({ where: { id: messageId } });
    if (!msg) throw new NotFoundException();
    msg.isPinned = !msg.isPinned;
    await this.repo.save(msg);
    return msg;
  }

  async getPinnedMessages(coupleId: string) {
    return this.repo.find({ where: { coupleId, isPinned: true }, order: { createdAt: 'DESC' } });
  }

  async getUnreadCount(coupleId: string, userId: string) {
    const count = await this.repo.count({ where: { coupleId, isRead: false } });
    return { count };
  }
}
