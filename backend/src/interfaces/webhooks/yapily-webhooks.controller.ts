import {
  BadRequestException,
  Controller,
  Headers,
  Inject,
  Post,
  Req,
} from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Request } from 'express';
import { createHash } from 'crypto';
import { PIS_GATEWAY, PisGateway } from '@payspin/pisp-provider';
import { PrismaService } from '../../infrastructure/persistence/prisma.module';
import {
  YAPILY_WEBHOOK_QUEUE,
  YapilyWebhookJob,
} from '../../infrastructure/queue/yapily-webhook.processor';

// Yapily can burst webhook deliveries (and retries); the global 100/min IP
// throttle must not drop legitimate settlement callbacks. Replay safety is
// enforced by the webhook_events unique constraint + HMAC signature instead.
@SkipThrottle()
@Controller('webhooks/yapily')
export class YapilyWebhooksController {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(PIS_GATEWAY) private readonly pisGateway: PisGateway,
    @InjectQueue(YAPILY_WEBHOOK_QUEUE) private readonly queue: Queue<YapilyWebhookJob>,
  ) {}

  @Post()
  async handle(
    @Req() req: Request & { rawBody?: Buffer },
    @Headers('webhook-signature') signature?: string,
  ) {
    const rawBody = req.rawBody?.toString('utf8') ?? JSON.stringify(req.body);
    if (!this.pisGateway.verifyWebhookSignature(rawBody, signature ?? '')) {
      throw new BadRequestException('Invalid webhook signature');
    }

    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    // Deterministic id so exact replays collide on the unique constraint
    // instead of slipping through with a fresh random id each time.
    const eventId =
      (payload.id as string | undefined) ??
      (payload.eventId as string | undefined) ??
      createHash('sha256').update(rawBody).digest('hex');
    const eventType = (payload.type as string | undefined) ?? 'payment.status.updated';

    try {
      await this.prisma.webhookEvent.create({
        data: {
          eventId,
          eventType,
          payload: payload as object,
        },
      });
    } catch {
      return { received: true, duplicate: true };
    }

    await this.queue.add(
      'process',
      { eventId, eventType, payload },
      {
        jobId: eventId,
        removeOnComplete: true,
        // Retry transient processing failures with exponential backoff and
        // keep failed jobs for inspection (acts as a lightweight DLQ) instead
        // of silently dropping a settlement update.
        attempts: 5,
        backoff: { type: 'exponential', delay: 5000 },
        removeOnFail: false,
      },
    );

    return { received: true };
  }
}
