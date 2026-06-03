import { Controller, Post, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { IsEnum, IsObject } from 'class-validator';
import { GamesService } from './games.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GameType } from '../../database/entities/game-session.entity';
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GameSession } from '../../database/entities/game-session.entity';
import { RedisModule } from '../../config/redis.module';

class CreateGameDto { @IsEnum(GameType) gameType: GameType; }
class MakeMoveDto { @IsObject() move: any; }

@ApiTags('Games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('games')
export class GamesController {
  constructor(private svc: GamesService) {}

  @Post('session')
  create(@Req() req, @Body() dto: CreateGameDto) {
    return this.svc.createSession(req.user.coupleId, req.user.id, dto.gameType);
  }

  @Get('session/:id')
  getSession(@Param('id') id: string) { return this.svc.getSession(id); }

  @Post('session/:id/move')
  move(@Req() req, @Param('id') id: string, @Body() dto: MakeMoveDto) {
    return this.svc.processMove(id, req.user.id, dto.move);
  }

  @Get('history')
  history(@Req() req) { return this.svc.getHistory(req.user.coupleId); }

  @Get('leaderboard')
  leaderboard(@Req() req) { return this.svc.getLeaderboard(req.user.coupleId); }
}

@Module({
  imports: [TypeOrmModule.forFeature([GameSession]), RedisModule],
  controllers: [GamesController],
  providers: [GamesService],
  exports: [GamesService],
})
export class GamesModule {}
