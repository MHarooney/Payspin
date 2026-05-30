# Conventions (agents)

Follow existing patterns. When in doubt, grep the nearest feature folder.

## General

- **Minimal scope** — fix only what the task requires.
- **No secrets in git** — `.env`, production keys, tokens stay local or on server.
- **pnpm** for JS workspace; **flutter pub** for mobile (not in pnpm workspace).
- **Turbo** runs `build` / `lint` / `typecheck` across packages.

## Naming

| Area | File | Class / export |
|------|------|----------------|
| Backend use case | `login-user.use-case.ts` | `LoginUserUseCase` |
| Backend mapper | `payment-links.mapper.ts` | `PaymentLinksMapper.toSummary()` |
| Backend module | `payment-links.module.ts` | `PaymentLinksModule` |
| Backend controller | `auth.controller.ts` | `AuthController` |
| Gateway | `yapily-pis.gateway.ts` | `YapilyPisGateway` |
| Validator | `create-link.schema.ts` | `createPaymentLinkSchema` |
| Shared type | `payment-link.ts` | `PaymentLinkSummary` |
| Flutter page | `home_page.dart` | `HomePage` |
| Flutter cubit | `onboarding_cubit.dart` | `OnboardingCubit` |
| Flutter repo | `auth_repository.dart` / `auth_repository_impl.dart` | `AuthRepository` |

## Backend anti-patterns

| Don't | Do instead |
|-------|------------|
| Business logic in controllers | Use case `execute()` |
| Nest `class-validator` DTOs for domain rules | Zod in `@payspin/validators` |
| Direct Yapily HTTP in use cases | `PIS_GATEWAY` / `AIS_GATEWAY` |
| New `backend/src/modules/` legacy layout | `application/` + `interfaces/` |
| Skip `YapilyModule` import when injecting gateways | Add to feature module `imports` |

## Mobile anti-patterns

| Don't | Do instead |
|-------|------------|
| White Material defaults / Tikkie purple | `PayspinTheme`, `PayspinDarkScaffold` |
| API calls from widgets directly | Repository or use case via `sl` |
| New global state framework | Cubit only where state is complex (onboarding) |
| Hardcode `localhost` in production builds | `--dart-define=API_URL=...` |

## Frontend anti-patterns

| Don't | Do instead |
|-------|------------|
| Auth/session on payer pages | Public pay flow only |
| Hardcode API URL | `NEXT_PUBLIC_API_URL` |
| Duplicate DTO types | Import from `@payspin/shared-types` |

## Git / commits

- Conventional intent: `feat`, `fix`, `refactor`, `docs`, `chore`.
- One logical change per commit when user asks to commit.
- Never commit `.env`, `backend/.env.production`, or credentials.

## Testing

| App | Runner | Location |
|-----|--------|----------|
| Backend | `node --import tsx --test` | `backend/test/*.test.ts` |
| Mobile unit | `flutter test` | `mobile/test/` |
| Mobile E2E | `flutter test integration_test/` | needs API + simulator |

Add tests only when they cover real behavior — not trivial asserts.
