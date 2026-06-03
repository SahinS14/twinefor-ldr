import { Controller, Get, Patch, Delete, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('me') @ApiOperation({ summary: 'Get my profile' })
  me(@Req() req) { return this.usersService.findById(req.user.id); }

  @Patch('me') @ApiOperation({ summary: 'Update my profile' })
  update(@Req() req, @Body() dto: UpdateUserDto) { return this.usersService.update(req.user.id, dto); }

  @Delete('me') @ApiOperation({ summary: 'Delete my account (GDPR)' })
  delete(@Req() req) { return this.usersService.deleteAccount(req.user.id); }

  @Get(':username') @ApiOperation({ summary: 'Get user by username' })
  findOne(@Param('username') username: string) { return this.usersService.findByUsername(username); }

  @Get(':id/presence') @ApiOperation({ summary: 'Get user presence' })
  presence(@Param('id') id: string) { return this.usersService.getPresence(id); }
}
