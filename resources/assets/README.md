# Payspin — Tikkie UX Reference Assets

Tikkie (ING) mobile app screenshots used as UX reference for Payspin wireframes.  
Source: [tikkie.me/particulier](https://www.tikkie.me/particulier)

## Naming convention

`ref-tikkie-{flow}-{step}-{variant}.jpeg`

Out-of-scope references (Groepie bill-splitting, duplicates) are in `archive/`.

## Screen index

| File | Figma frame | Flow | Payspin mapping |
|------|-------------|------|-----------------|
| `ref-tikkie-onboarding-splash-01.jpeg` | S01 | Onboarding | Splash — Payspin logo + "Let's get started" |
| `ref-tikkie-onboarding-carousel-p2p-01.jpeg` | S02 | Onboarding | Carousel 1/3 — P2P value prop |
| `ref-tikkie-onboarding-carousel-circles-01.jpeg` | S03 | Onboarding | Carousel 2/3 — Circles value prop (replaces Groepie slide) |
| `ref-tikkie-onboarding-name-01.jpeg` | S05 | Onboarding | Display name |
| `ref-tikkie-onboarding-phone-01.jpeg` | S06 | Onboarding | Phone verification (+49 / +31) |
| `ref-tikkie-onboarding-cookies-01.jpeg` | S07 | Onboarding | Cookie / GDPR consent |
| `ref-tikkie-onboarding-success-01.jpeg` | S09 | Onboarding | Onboarding complete |
| `ref-tikkie-hub-post-onboarding-01.jpeg` | S10 | Onboarding | First-run hub — Create link / Explore Circles |
| `ref-tikkie-p2p-home-links-list-01.jpeg` | P01 | P2P Links | Links home with payment history |
| `ref-tikkie-p2p-create-amount-01.jpeg` | P03 | P2P Links | Create link — amount entry |
| `ref-tikkie-p2p-create-description-empty-01.jpeg` | P04 | P2P Links | Create link — description (empty) |
| `ref-tikkie-p2p-create-description-filled-01.jpeg` | P04 | P2P Links | Create link — description (filled) |
| `ref-tikkie-p2p-share-link-sheet-01.jpeg` | P06 | P2P Links | Share link sheet pattern |
| `ref-tikkie-p2p-share-review-01.jpeg` | P06 | P2P Links | Share review — WhatsApp / QR / share |
| `ref-tikkie-p2p-qr-payer-01.jpeg` | P07 | P2P Links | QR code for payer |
| `ref-tikkie-p2p-iban-restriction-01.jpeg` | P11 / S08 | P2P / Onboarding | IBAN restriction — DE/NL note |

## Archived (out of scope)

| File | Reason |
|------|--------|
| `archive/ref-tikkie-onboarding-splash-02.jpeg` | Duplicate splash |
| `archive/ref-tikkie-hub-post-onboarding-02.jpeg` | Duplicate hub variant |
| `archive/ref-tikkie-p2p-split-bill-01.jpeg` | Groepie bill-split — not in Payspin P2P scope |
| `archive/ref-tikkie-groepie-detail-01.jpeg` | Groepie detail — Circles uses different ROSCA UX |

## User flows mapped

### Flow 1 — Create & share payment link (P2P)
P03 → P04 → P05 → P06 → (W01 → W02 → W05) → P09

### Flow 2 — Circles contribution (Phase 3)
C08 → W01 → W02 → W05 → C05

### Flow 3 — Monerium onboarding (Phase 3)
C09 → C10 → C11 → C12

## Figma file

Wireframes: **[Payspin — Mobile Wireframes v1](https://www.figma.com/design/QEy9wqxzUbvamVknKwc8Be)** (file key: `QEy9wqxzUbvamVknKwc8Be`)

Interactive HTML gallery (all 56 screens): [`resources/wireframes/index.html`](../wireframes/index.html)

Full spec: [`resources/docs/wireframe-spec.md`](../docs/wireframe-spec.md)
