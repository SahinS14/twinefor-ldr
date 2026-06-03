import { Controller, Post, Get, Delete, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { IsString } from 'class-validator';
import { CouplesService } from './couples.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

class AcceptInviteDto { @IsString() code: string; }

@ApiTags('Couples')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('couples')
export class CouplesController {
  constructor(private svc: CouplesService) {}

  @Post('invite') invite(@Req() req) { return this.svc.generateInvite(req.user.id); }
  @Post('accept') accept(@Req() req, @Body() dto: AcceptInviteDto) { return this.svc.acceptInvite(dto.code, req.user.id); }
  @Get('me') getMyCouple(@Req() req) { return this.svc.getMyCouple(req.user.id); }
  @Get('me/stats') getStats(@Req() req) { return this.svc.getStats(req.user.coupleId); }
  @Delete('unpair') unpair(@Req() req) { return this.svc.unpair(req.user.id); }
}
