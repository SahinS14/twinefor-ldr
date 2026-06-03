import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RealtimeGateway } from './realtime.gateway';
import { User } from '../database/entities/user.entity';
import { ChatModule } from '../modules/chat/chat.module';
import { GamesModule } from '../modules/games/games.module';
import { AuthModule } from '../modules/auth/auth.module';
import { RedisModule } from '../config/redis.module';

@Module({
  imports: [TypeOrmModule.forFeature([User]), ChatModule, GamesModule, AuthModule, RedisModule],
  providers: [RealtimeGateway],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
