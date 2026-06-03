import {
  WebSocketGateway, WebSocketServer, SubscribeMessage, MessageBody,
  ConnectedSocket, OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../database/entities/user.entity';
import { ChatService } from '../modules/chat/chat.service';
import { GamesService } from '../modules/games/games.service';
import { MessageType } from '../database/entities/message.entity';
import { InjectRedis } from '../common/decorators/redis.decorator';
import Redis from 'ioredis';

@WebSocketGateway({
  cors: { origin: '*', credentials: true },
  namespace: '/ws',
  transports: ['websocket', 'polling'],
})
@Injectable()
export class RealtimeGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;
  private readonly logger = new Logger(RealtimeGateway.name);
  private connectedUsers = new Map<string, string>(); // socketId -> userId

  constructor(
    private jwtService: JwtService,
    private config: ConfigService,
    @InjectRepository(User) private usersRepo: Repository<User>,
    private chatService: ChatService,
    private gamesService: GamesService,
    @InjectRedis() private redis: Redis,
  ) {}

  afterInit(server: Server) {
    this.logger.log('🔌 WebSocket Gateway initialized');
  }

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token || client.handshake.headers?.authorization?.replace('Bearer ', '');
      if (!token) { client.disconnect(); return; }

      const payload = this.jwtService.verify(token, { secret: this.config.get('JWT_SECRET') || 'twine-dev-secret' });
      const user = await this.usersRepo.findOne({ where: { id: payload.sub } });
      if (!user) { client.disconnect(); return; }

      // Attach user to socket
      (client as any).user = user;
      this.connectedUsers.set(client.id, user.id);

      // Join couple room
      if (user.coupleId) {
        client.join(`couple:${user.coupleId}`);
        client.join(`user:${user.id}`);
      }

      // Mark online
      await this.usersRepo.update(user.id, { isOnline: true, lastSeen: new Date() });
      await this.redis.setex(`presence:${user.id}`, 300, '1');

      // Notify partner
      if (user.coupleId) {
        client.to(`couple:${user.coupleId}`).emit('presence:update', {
          userId: user.id, isOnline: true, timestamp: new Date(),
        });
      }

      this.logger.log(`✅ User ${user.username} connected [${client.id}]`);
    } catch (e) {
      this.logger.error(`Connection rejected: ${e.message}`);
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = this.connectedUsers.get(client.id);
    if (userId) {
      this.connectedUsers.delete(client.id);
      await this.usersRepo.update(userId, { isOnline: false, lastSeen: new Date() });
      await this.redis.del(`presence:${userId}`);
      const user = await this.usersRepo.findOne({ where: { id: userId } });
      if (user?.coupleId) {
        this.server.to(`couple:${user.coupleId}`).emit('presence:update', {
          userId, isOnline: false, lastSeen: new Date(),
        });
      }
      this.logger.log(`❌ User ${userId} disconnected`);
    }
  }

  // ─── CHAT ───────────────────────────────────────────────────────────
  @SubscribeMessage('chat:send')
  async handleSendMessage(@ConnectedSocket() client: Socket, @MessageBody() data: { content: string; type?: MessageType; replyToId?: string; mediaUrl?: string }) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return { error: 'Not in a couple' };
    try {
      const message = await this.chatService.sendMessage(user.coupleId, user.id, data.content, data.type || MessageType.TEXT, { replyToId: data.replyToId, mediaUrl: data.mediaUrl } as any);
      this.server.to(`couple:${user.coupleId}`).emit('chat:message', { message, senderId: user.id });
      return { success: true, message };
    } catch (e) { return { error: e.message }; }
  }

  @SubscribeMessage('chat:typing')
  handleTyping(@ConnectedSocket() client: Socket, @MessageBody() data: { isTyping: boolean }) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    client.to(`couple:${user.coupleId}`).emit('chat:typing', { userId: user.id, isTyping: data.isTyping });
  }

  @SubscribeMessage('chat:read')
  async handleRead(@ConnectedSocket() client: Socket) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    await this.chatService.markRead(user.coupleId, user.id);
    client.to(`couple:${user.coupleId}`).emit('chat:read', { userId: user.id, readAt: new Date() });
  }

  @SubscribeMessage('chat:react')
  async handleReact(@ConnectedSocket() client: Socket, @MessageBody() data: { messageId: string; emoji: string }) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    const msg = await this.chatService.reactToMessage(data.messageId, user.id, data.emoji);
    this.server.to(`couple:${user.coupleId}`).emit('chat:reaction', { messageId: data.messageId, emoji: data.emoji, userId: user.id });
    return { success: true };
  }

  // ─── GAMES ──────────────────────────────────────────────────────────
  @SubscribeMessage('game:join')
  async handleGameJoin(@ConnectedSocket() client: Socket, @MessageBody() data: { sessionId: string }) {
    const user = (client as any).user as User;
    client.join(`game:${data.sessionId}`);
    const state = await this.gamesService.getSession(data.sessionId);
    client.to(`game:${data.sessionId}`).emit('game:player_joined', { userId: user.id, name: user.name });
    return { state };
  }

  @SubscribeMessage('game:move')
  async handleGameMove(@ConnectedSocket() client: Socket, @MessageBody() data: { sessionId: string; move: any }) {
    const user = (client as any).user as User;
    try {
      const result = await this.gamesService.processMove(data.sessionId, user.id, data.move);
      this.server.to(`game:${data.sessionId}`).emit('game:state', result.state);
      if (result.state.status === 'completed') {
        this.server.to(`game:${data.sessionId}`).emit('game:end', { winnerId: result.state.winnerId, isDraw: result.state.isDraw });
      }
      return { success: true };
    } catch (e) {
      return { error: e.message };
    }
  }

  @SubscribeMessage('game:resign')
  async handleResign(@ConnectedSocket() client: Socket, @MessageBody() data: { sessionId: string }) {
    const user = (client as any).user as User;
    await this.gamesService.endSession(data.sessionId, null);
    this.server.to(`game:${data.sessionId}`).emit('game:end', { resignedBy: user.id, isDraw: false });
    return { success: true };
  }

  // ─── LOCATION ───────────────────────────────────────────────────────
  @SubscribeMessage('location:update')
  async handleLocation(@ConnectedSocket() client: Socket, @MessageBody() data: { lat: number; lng: number; note?: string }) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    const loc = { userId: user.id, lat: data.lat, lng: data.lng, note: data.note, timestamp: new Date() };
    await this.redis.setex(`location:${user.id}`, 600, JSON.stringify(loc));
    client.to(`couple:${user.coupleId}`).emit('location:update', loc);
    return { success: true };
  }

  @SubscribeMessage('location:get')
  async handleGetLocation(@ConnectedSocket() client: Socket) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return { error: 'Not in a couple' };
    // Get partner's location
    const couple = await this.redis.get(`couple_members:${user.coupleId}`);
    return { success: true };
  }

  // ─── VOICE / PRESENCE ───────────────────────────────────────────────
  @SubscribeMessage('voice:join')
  handleVoiceJoin(@ConnectedSocket() client: Socket, @MessageBody() data: { mode: string }) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    client.join(`voice:${user.coupleId}`);
    client.to(`couple:${user.coupleId}`).emit('voice:partner_joined', { userId: user.id, mode: data.mode });
    return { success: true };
  }

  @SubscribeMessage('voice:leave')
  handleVoiceLeave(@ConnectedSocket() client: Socket) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    client.leave(`voice:${user.coupleId}`);
    client.to(`couple:${user.coupleId}`).emit('voice:partner_left', { userId: user.id });
  }

  @SubscribeMessage('voice:signal')
  handleVoiceSignal(@ConnectedSocket() client: Socket, @MessageBody() data: { signal: any }) {
    const user = (client as any).user as User;
    if (!user?.coupleId) return;
    client.to(`voice:${user.coupleId}`).emit('voice:signal', { from: user.id, signal: data.signal });
  }

  @SubscribeMessage('mood:update')
  async handleMoodUpdate(@ConnectedSocket() client: Socket, @MessageBody() data: { mood: string }) {
    const user = (client as any).user as User;
    await this.usersRepo.update(user.id, { moodStatus: data.mood });
    if (user?.coupleId) {
      client.to(`couple:${user.coupleId}`).emit('mood:partner_update', { userId: user.id, mood: data.mood });
    }
    return { success: true };
  }

  // ─── UTILITY ────────────────────────────────────────────────────────
  broadcastToCouple(coupleId: string, event: string, data: any) {
    this.server.to(`couple:${coupleId}`).emit(event, data);
  }
}
