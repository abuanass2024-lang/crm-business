import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

const VERSION = process.env.APP_VERSION || '1.4.0';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async health() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { ok: true, service: 'crm-business-api', version: VERSION, database: 'ok' };
    } catch {
      throw new ServiceUnavailableException({ ok: false, service: 'crm-business-api', version: VERSION, database: 'unavailable' });
    }
  }

  @Get('live')
  live() {
    return { ok: true, service: 'crm-business-api', version: VERSION };
  }

  @Get('ready')
  async ready() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { ok: true, ready: true, database: 'ok', version: VERSION };
    } catch {
      throw new ServiceUnavailableException({ ok: false, ready: false, database: 'unavailable', version: VERSION });
    }
  }
}
