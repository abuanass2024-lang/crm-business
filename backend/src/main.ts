import 'dotenv/config';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const secret = process.env.JWT_SECRET || '';

  if (
    secret.length < 32 ||
    secret === 'CHANGE_ME_IN_PRODUCTION'
  ) {
    throw new Error(
      'JWT_SECRET must be a strong secret of at least 32 characters.',
    );
  }

  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api');

  app.use(helmet());

  const origins = (process.env.CORS_ORIGINS || '')
    .split(',')
    .map(x => x.trim())
    .filter(Boolean);

  app.enableCors({
    origin: origins.length ? origins : false,
    credentials: true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  await app.listen(
    process.env.PORT ? Number(process.env.PORT) : 3000,
    '0.0.0.0',
  );
}

bootstrap();