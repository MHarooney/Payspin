import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { ZodError } from 'zod';
import { YapilyApiError } from '../../../infrastructure/yapily/yapily-http.client';

/**
 * Maps known error types to safe HTTP responses:
 * - ZodError       -> 400 with field-level issues
 * - YapilyApiError -> 502 (never leaks the upstream body)
 * - HttpException  -> its own status/response
 * - anything else  -> 500 with a generic message (no stack leak)
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();

    if (exception instanceof ZodError) {
      res.status(HttpStatus.BAD_REQUEST).json({
        statusCode: HttpStatus.BAD_REQUEST,
        error: 'Bad Request',
        message: 'Validation failed',
        issues: exception.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      });
      return;
    }

    if (exception instanceof YapilyApiError) {
      // Log status + a safe summary of the Yapily error (never log raw body — it
      // may contain consent tokens or payment identifiers).
      let yapilyCode = 'UNKNOWN';
      let yapilyMessage = '';
      try {
        const parsed = JSON.parse(exception.message) as { error?: { code?: number; status?: string; message?: string; source?: string } };
        yapilyCode = String(parsed?.error?.code ?? exception.status);
        yapilyMessage = parsed?.error?.message?.slice(0, 120) ?? '';
      } catch {
        yapilyMessage = exception.message?.slice(0, 120) ?? '';
      }
      this.logger.error(
        `Yapily error ${exception.status} [${yapilyCode}]: ${yapilyMessage}`,
      );
      res.status(HttpStatus.BAD_GATEWAY).json({
        statusCode: HttpStatus.BAD_GATEWAY,
        error: 'Bad Gateway',
        message: 'Upstream banking provider error',
      });
      return;
    }

    if (exception instanceof HttpException) {
      res.status(exception.getStatus()).json(exception.getResponse());
      return;
    }

    this.logger.error(
      exception instanceof Error ? (exception.stack ?? exception.message) : String(exception),
    );
    res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      error: 'Internal Server Error',
      message: 'Internal server error',
    });
  }
}
