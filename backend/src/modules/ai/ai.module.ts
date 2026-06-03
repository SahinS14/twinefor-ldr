import { Controller, Get, Post, Body, Query, UseGuards, Req, Module } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiService } from './ai.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { DailyQuestion, QuestionAnswer } from '../../database/entities/question.entity';
import { RedisModule } from '../../config/redis.module';

@ApiTags('AI & Questions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('ai')
export class AiController {
  constructor(private svc: AiService) {}

  @Get('question/daily') dailyQuestion(@Req() req) { return this.svc.getDailyQuestion(req.user.coupleId); }
  @Get('insights') insights(@Req() req) { return this.svc.getCompatibilityReport(req.user.coupleId); }
  @Get('summary/weekly') weekly(@Req() req) { return this.svc.getWeeklySummary(req.user.coupleId); }

  @Post('question/answer')
  answer(@Req() req, @Body() dto: { questionId: string; answer: string }) {
    return this.svc.submitAnswer(req.user.coupleId, req.user.id, dto.questionId, dto.answer);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([DailyQuestion, QuestionAnswer]), RedisModule],
  controllers: [AiController],
  providers: [AiService],
  exports: [AiService],
})
export class AiModule {}
