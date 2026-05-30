# Payspin Mobile Wireframes — Specification v1

**Version:** 1.0 · **Date:** May 2026 · **Status:** Complete

## Deliverables

| Deliverable | Location | Status |
|-------------|----------|--------|
| Tikkie reference assets (renamed) | [`resources/assets/`](../assets/) | Done |
| Asset index README | [`resources/assets/README.md`](../assets/README.md) | Done |
| Interactive HTML wireframe gallery (56 screens) | [`resources/wireframes/index.html`](../wireframes/index.html) | Done |
| Wireframe styles | [`resources/wireframes/wireframes.css`](../wireframes/wireframes.css) | Done |
| Figma file (design system + partial frames) | [Figma — Mobile Wireframes v1](https://www.figma.com/design/QEy9wqxzUbvamVknKwc8Be) | Partial* |

\*Figma Starter plan limits: 3 pages max, MCP rate limit reached after design system setup. Full screen import can continue in Figma using the HTML gallery as reference.

## Figma file structure (3 pages — Starter plan)

1. **01 — Cover & Design System** — Cover frame, color variables (16 tokens), buttons, pills, bottom nav, link card
2. **02 — Mobile Wireframes** — Import mobile frames here
3. **03 — Web, Circles & Flows** — Payer web + Circles + flow annotations

**File key:** `QEy9wqxzUbvamVknKwc8Be`

## Design tokens (from `Payspin-portal/src/theme/theme.ts`)

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#FC00FF` | CTAs, active tab |
| Secondary | `#07D8DD` | Secondary actions, gradient end |
| Purple | `#8E0FF2` | Splash backgrounds |
| Blue | `#5C7AEA` | Circles accent |
| Yellow | `#FFC408` | Pending states |
| Success | `#10B981` | Paid |
| Error | `#EF4444` | Failed / expired |

**Typography:** Raleway (headings) · Inter (body)  
**Logo:** `Payspin-portal/src/assets/images/payspin-ic.png`, `Logo_Gradient-01.png`

## Screen inventory (56 frames)

### Onboarding — S01–S12 (Phase 1)
S01 Splash · S02–S04 Carousel · S05 Name · S06 Phone · S07 Cookies · S08 IBAN · S09 Success · S10 Hub · S11 Notifications · S12 Login

### P2P Links — P01–P14
P01 Home · P02 Empty · P03 Amount · P04 Description · P05 Review · P06 Share · P07 QR · P08 Detail · P09 Push · P10 Expired · P11 IBAN · P12–P14 Phase 2 placeholders

### Profile — R01–R08
R01 Overview · R02 Bank · R03 Monerium · R04 Notifications · R05 Language · R06 Legal · R07 Help · R08 Logout

### Payer Web — W01–W06
W01 Landing · W02 Yapily bank picker · W03 Bank SCA · W04 Processing · W05 Success · W06 Failed

### Circles ROSCA — C01–C16 (Phase 3)
C01 Empty · C02 List · C03–C04 Create · C05 Detail · C06 Members · C07 History · C08 Contribution · C09–C11 Monerium · C12 Wallet · C13 Payout · C14 Paused · C15 Join · C16 Locked teaser

## User flows

1. **P2P:** P03 → P04 → P05 → P06 → W01 → W02 → W05 → P09
2. **Circles contribution:** C08 → W01 → W02 → W05 → C05
3. **Monerium onboarding:** C09 → C10 → C11 → C12

## Integrations (UI touchpoints)

- **Yapily** — W02 bank picker, C08 contribution, footer on payer web
- **Monerium** — C09–C12, R03 profile
- **Circle MPC** — C12 wallet badge
- **Firebase** — S12 auth, P09 FCM push
- **WhatsApp** — P06 share sheet primary CTA

## View wireframes locally

Open in browser:

```bash
open resources/wireframes/index.html
```

## Architecture reference

See [`payspin-solution-architecture.md`](payspin-solution-architecture.md) for product and integration details.
