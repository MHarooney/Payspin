import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './interfaces/http/filters/all-exceptions.filter';

const BODY_LIMIT = '64kb';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    rawBody: true,
    bodyParser: true,
  });

  // Behind the Caddy reverse proxy: trust the first hop so client IPs (used by
  // the rate limiter) and protocol are correct.
  app.set('trust proxy', 1);
  app.use(helmet());
  app.useBodyParser('json', { limit: BODY_LIMIT });
  app.useBodyParser('urlencoded', { limit: BODY_LIMIT, extended: true });

  app.setGlobalPrefix('v1');
  app.enableCors({
    origin: [
      process.env.PAYER_WEB_URL ?? 'http://localhost:3000',
    ],
    credentials: true,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());

  // Flush in-flight requests / queue jobs and close DB connections cleanly on
  // SIGTERM/SIGINT (e.g. during `docker compose up -d` container recreation).
  app.enableShutdownHooks();

  const port = process.env.PORT ?? 3001;
  await app.listen(port);
}

bootstrap();
