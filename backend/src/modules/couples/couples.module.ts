import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CouplesController } from './couples.controller';
import { CouplesService } from './couples.service';
import { Couple } from '../../database/entities/couple.entity';
import { User } from '../../database/entities/user.entity';
import { RedisModule } from '../../config/redis.module';

@Module({
  imports: [TypeOrmModule.forFeature([Couple, User]), RedisModule],
  controllers: [CouplesController],
  providers: [CouplesService],
  exports: [CouplesService],
})
export class CouplesModule {}
