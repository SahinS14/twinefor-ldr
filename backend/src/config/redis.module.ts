import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../common/decorators/redis.decorator';

@Global()
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const url = config.get('REDIS_URL') || 'redis://localhost:6379';
        const client = new Redis(url, { maxRetriesPerRequest: 3, enableReadyCheck: true, lazyConnect: false });
        client.on('connect', () => console.log('✅ Redis connected'));
        client.on('error', (err) => console.error('Redis error:', err.message));
        return client;
      },
    },
  ],
  exports: [REDIS_CLIENT],
})
export class RedisModule {}
