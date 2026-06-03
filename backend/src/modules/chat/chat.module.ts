import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum } from 'class-validator';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { MessageType } from '../../database/entities/message.entity';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Message } from '../../database/entities/message.entity';
import { RedisModule } from '../../config/redis.module';

class SendMessageDto {
  @IsString() content: string;
  @IsOptional() @IsEnum(MessageType) type?: MessageType;
  @IsOptional() @IsString() replyToId?: string;
  @IsOptional() @IsString() mediaUrl?: string;
}

@ApiTags('Chat')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private svc: ChatService) {}

  @Post('send')
  send(@Req() req, @Body() dto: SendMessageDto) {
    return this.svc.sendMessage(req.user.coupleId, req.user.id, dto.content, dto.type, { replyToId: dto.replyToId, mediaUrl: dto.mediaUrl } as any);
  }

  @Get('messages')
  getMessages(@Req() req, @Query('cursor') cursor: string, @Query('limit') limit: number) {
    return this.svc.getMessages(req.user.coupleId, req.user.id, cursor, limit || 30);
  }

  @Post('read') markRead(@Req() req) { return this.svc.markRead(req.user.coupleId, req.user.id); }
  @Get('pinned') getPinned(@Req() req) { return this.svc.getPinnedMessages(req.user.coupleId); }
  @Get('unread') unread(@Req() req) { return this.svc.getUnreadCount(req.user.coupleId, req.user.id); }

  @Patch(':id')
  edit(@Req() req, @Param('id') id: string, @Body() dto: { content: string }) {
    return this.svc.editMessage(id, req.user.id, dto.content);
  }

  @Delete(':id')
  delete(@Req() req, @Param('id') id: string) { return this.svc.deleteMessage(id, req.user.id); }

  @Post(':id/react')
  react(@Req() req, @Param('id') id: string, @Body() dto: { emoji: string }) {
    return this.svc.reactToMessage(id, req.user.id, dto.emoji);
  }

  @Post(':id/pin')
  pin(@Req() req, @Param('id') id: string) { return this.svc.pinMessage(id, req.user.id); }
}

@Module({
  imports: [TypeOrmModule.forFeature([Message]), RedisModule],
  controllers: [ChatController],
  providers: [ChatService],
  exports: [ChatService],
})
export class ChatModule {}
