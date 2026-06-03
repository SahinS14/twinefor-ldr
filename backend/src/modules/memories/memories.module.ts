import {
  Module, Injectable, Controller,
  Get, Post, Patch, Delete,
  Body, Param, Query, UseGuards, Req,
  NotFoundException, ForbiddenException,
} from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IsString, IsOptional, IsBoolean, IsDateString, IsArray } from 'class-validator';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Memory } from '../../database/entities/memory.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

class CreateMemoryDto {
  @IsString() title: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() mediaUrl?: string;
  @IsOptional() @IsString() location?: string;
  @IsOptional() @IsDateString() memoryDate?: string;
  @IsOptional() @IsArray() tags?: string[];
}

class UpdateMemoryDto {
  @IsOptional() @IsString() title?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() mediaUrl?: string;
  @IsOptional() @IsString() location?: string;
  @IsOptional() @IsArray() tags?: string[];
  @IsOptional() @IsBoolean() isFavorite?: boolean;
}

@Injectable()
export class MemoriesService {
  constructor(@InjectRepository(Memory) private repo: Repository<Memory>) {}

  async create(coupleId: string, userId: string, dto: CreateMemoryDto) {
    const memory = this.repo.create({
      coupleId, createdById: userId,
      title: dto.title,
      description: dto.description,
      mediaUrl: dto.mediaUrl,
      location: dto.location,
      memoryDate: dto.memoryDate ? new Date(dto.memoryDate) : new Date(),
      tags: dto.tags,
    });
    return this.repo.save(memory);
  }

  async findAll(coupleId: string, page = 1, limit = 20) {
    const [memories, total] = await this.repo.findAndCount({
      where: { coupleId },
      order: { memoryDate: 'DESC' },
      take: limit,
      skip: (page - 1) * limit,
    });
    return { memories, total, page, pages: Math.ceil(total / limit) };
  }

  async findFavorites(coupleId: string) {
    return this.repo.find({ where: { coupleId, isFavorite: true }, order: { memoryDate: 'DESC' } });
  }

  async findOne(id: string, coupleId: string) {
    const m = await this.repo.findOne({ where: { id, coupleId } });
    if (!m) throw new NotFoundException('Memory not found');
    return m;
  }

  async update(id: string, coupleId: string, dto: UpdateMemoryDto) {
    const m = await this.findOne(id, coupleId);
    Object.assign(m, dto);
    return this.repo.save(m);
  }

  async toggleFavorite(id: string, coupleId: string) {
    const m = await this.findOne(id, coupleId);
    m.isFavorite = !m.isFavorite;
    return this.repo.save(m);
  }

  async remove(id: string, coupleId: string, userId: string) {
    const m = await this.findOne(id, coupleId);
    if (m.createdById !== userId) throw new ForbiddenException('Only creator can delete');
    await this.repo.softDelete(id);
    return { success: true };
  }

  async getTimeline(coupleId: string) {
    const memories = await this.repo.find({
      where: { coupleId },
      order: { memoryDate: 'ASC' },
    });
    // Group by year/month
    const grouped: Record<string, Memory[]> = {};
    memories.forEach(m => {
      const key = m.memoryDate
        ? `${new Date(m.memoryDate).getFullYear()}-${String(new Date(m.memoryDate).getMonth() + 1).padStart(2, '0')}`
        : 'Unknown';
      if (!grouped[key]) grouped[key] = [];
      grouped[key].push(m);
    });
    return grouped;
  }
}

@ApiTags('Memories')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('memories')
export class MemoriesController {
  constructor(private svc: MemoriesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a shared memory' })
  create(@Req() req, @Body() dto: CreateMemoryDto) {
    return this.svc.create(req.user.coupleId, req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all memories (paginated)' })
  findAll(@Req() req, @Query('page') page = 1, @Query('limit') limit = 20) {
    return this.svc.findAll(req.user.coupleId, +page, +limit);
  }

  @Get('timeline')
  @ApiOperation({ summary: 'Get memories grouped by month (timeline view)' })
  timeline(@Req() req) { return this.svc.getTimeline(req.user.coupleId); }

  @Get('favorites')
  @ApiOperation({ summary: 'Get favorite memories' })
  favorites(@Req() req) { return this.svc.findFavorites(req.user.coupleId); }

  @Get(':id')
  findOne(@Req() req, @Param('id') id: string) {
    return this.svc.findOne(id, req.user.coupleId);
  }

  @Patch(':id')
  update(@Req() req, @Param('id') id: string, @Body() dto: UpdateMemoryDto) {
    return this.svc.update(id, req.user.coupleId, dto);
  }

  @Post(':id/favorite')
  @ApiOperation({ summary: 'Toggle favorite status' })
  toggleFavorite(@Req() req, @Param('id') id: string) {
    return this.svc.toggleFavorite(id, req.user.coupleId);
  }

  @Delete(':id')
  remove(@Req() req, @Param('id') id: string) {
    return this.svc.remove(id, req.user.coupleId, req.user.id);
  }
}

@Module({
  imports: [TypeOrmModule.forFeature([Memory])],
  controllers: [MemoriesController],
  providers: [MemoriesService],
  exports: [MemoriesService],
})
export class MemoriesModule {}
