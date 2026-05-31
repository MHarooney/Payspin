import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { readFileSync } from 'fs';
import * as admin from 'firebase-admin';

export interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface PushResult {
  sent: number;
  /** Tokens rejected by FCM (unregistered/invalid) that callers should prune. */
  invalidTokens: string[];
}

/**
 * Thin wrapper around firebase-admin. Initialization is lazy and fault-tolerant:
 * when `FIREBASE_SERVICE_ACCOUNT_JSON` is absent (local dev, tests, un-provisioned
 * env) every method becomes a safe no-op so the rest of the app keeps working.
 */
@Injectable()
export class FirebaseAdminService {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private app: admin.app.App | null = null;
  private initAttempted = false;

  constructor(private readonly config: ConfigService) {}

  isEnabled(): boolean {
    return this.getApp() !== null;
  }

  async sendToTokens(tokens: string[], payload: PushPayload): Promise<PushResult> {
    const app = this.getApp();
    if (!app || tokens.length === 0) {
      return { sent: 0, invalidTokens: [] };
    }

    const response = await admin.messaging(app).sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: payload.data ?? {},
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? '';
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-argument') ||
          code.includes('invalid-registration-token')
        ) {
          invalidTokens.push(tokens[i]);
        } else {
          this.logger.warn(`FCM send error for a token: ${code}`);
        }
      }
    });

    return { sent: response.successCount, invalidTokens };
  }

  /** Verify a Firebase ID token (used for Phone Auth). Returns null when disabled/invalid. */
  async verifyIdToken(idToken: string): Promise<admin.auth.DecodedIdToken | null> {
    const app = this.getApp();
    if (!app) return null;
    try {
      return await admin.auth(app).verifyIdToken(idToken);
    } catch (err) {
      this.logger.warn(`verifyIdToken failed: ${(err as Error).message}`);
      return null;
    }
  }

  private getApp(): admin.app.App | null {
    if (this.initAttempted) return this.app;
    this.initAttempted = true;

    const raw = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (!raw) {
      this.logger.warn(
        'FIREBASE_SERVICE_ACCOUNT_JSON not set — FCM push and phone verification are disabled',
      );
      return null;
    }

    try {
      const serviceAccount = this.parseServiceAccount(raw);
      this.app = admin.apps.length
        ? admin.app()
        : admin.initializeApp({
            credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
            projectId:
              this.config.get<string>('FIREBASE_PROJECT_ID') ?? serviceAccount.project_id,
          });
      this.logger.log('firebase-admin initialized');
      return this.app;
    } catch (err) {
      this.logger.error(`Failed to initialize firebase-admin: ${(err as Error).message}`);
      return null;
    }
  }

  /** Accepts raw JSON, base64-encoded JSON, or a filesystem path to the JSON. */
  private parseServiceAccount(raw: string): { project_id?: string } & Record<string, unknown> {
    const trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      return JSON.parse(trimmed);
    }
    try {
      return JSON.parse(readFileSync(trimmed, 'utf8'));
    } catch {
      return JSON.parse(Buffer.from(trimmed, 'base64').toString('utf8'));
    }
  }
}
