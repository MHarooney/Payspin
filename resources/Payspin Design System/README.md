# Payspin Design System

## Overview

**Payspin** is a peer-to-peer (P2P) payment platform that facilitates payments to the crowd — specifically enabling community savings circles ("tontines" / rotating savings groups). Users can create or join a "circle," contribute monthly installments, and receive their payout on a scheduled rotation. The product handles secure payment collection, contributor tracking, and circle administration.

**Tagline:** "Your money, your community, and your peace of mind."  
**Value prop:** Trusted & Secured · Same Trust · Secured payments powered by top EU providers.

---

## Products

| Product | Description |
|---|---|
| **Payspin Mobile App (iOS)** | The primary product — a mobile-first app for iPhone (428×926 pt). Covers onboarding, sign-up, home dashboard, circle creation, contributor management, notifications, and admin views. |

---

## Sources

- **Figma file:** `Payspin.fig` (virtual filesystem at `/Design-System` and `/UI-Design`, 69 top-level frames)
  - Design System page: 11 frames covering colour, typography, spacing, effects, components
  - UI Design page: 58 frames covering every major screen of the app
- **Uploaded logo assets:**
  - `uploads/Logo_White-01.png` — full horizontal wordmark, white
  - `uploads/Emblem_Gradient-01.png` — emblem/icon, magenta-to-cyan gradient
  - `uploads/Emblem_White-01.png` — emblem/icon, white

---

## CONTENT FUNDAMENTALS

### Voice & Tone
- **Warm, community-first, trustworthy.** Copy emphasises safety, belonging, and ease.
- **Inclusive language:** "Your money, your community" — possessive "your" throughout to create ownership.
- **Short, directive CTAs:** "Next", "Continuo", "Sign Up", "Follow Us", "Join" — action-first, no filler.
- **Sentence case** used for body text; **Title Case** used for screen headings ("Enter your Phone Number", "Create Your Own Circle").
- **No emoji** in the UI — clean and professional.
- **Numbers formatted with commas:** "1,800 EUR", "2,000 EUR" — always with currency code suffix (EUR).
- **Friendly but not casual.** Not slangy; more like a trustworthy local bank or co-op.
- **I/We vs You:** The app addresses the user as "you" ("We'll let you know…"). Brand communications use "we".
- **Example copy:**
  - "Enter your phone number, We will send you a confirmation code there."
  - "Your trusted tradition, now is smarter not harder."
  - "We'll let you know when there will be something to update you."
  - "There is no association that you are currently affiliated with. To create an association or join an association, click 'join.'"
  - "Create an account or log in to explore about our app"

### Casing
- Screen titles: Title Case with Raleway Bold
- Section labels: Title/Sentence case, Raleway Bold
- Body / supporting text: Sentence case, Inter Regular
- Buttons: Sentence case (not ALL CAPS)

---

## VISUAL FOUNDATIONS

### Colors

**Primary palette (Magenta–Cyan gradient system):**
| Token | Value | Usage |
|---|---|---|
| `--primary` | `#FC00FF` (rgb 252,0,255) | Primary CTA buttons, key accents, gradient start |
| `--primary-light` | `#D94DF8` / `rgb(217,77,248)` | Join FAB, active progress steps, accent pill |
| `--secondary` | `#07D8DD` (rgb 7,216,221) | Gradient end, dividers in stepper, teal accents |
| `--secondary-dark` | `#008D8F` (rgb 0,141,143) | Home banner card bg |
| `--primary-40` | `#E800F2` (rgb 232,0,242) | Mid-primary |
| `--purple-mid` | `#6B4EC4` / `rgb(101,85,143)` | Filled button bg (secondary variant) |
| `--purple-deep` | `#6929C4` (rgb 105,41,196) | Deep accent fills |

**Gradient:** `linear-gradient(#FC00FF 0%, #07D8DD 100%)` — the signature Payspin gradient used on splash screen background, progress bars, and emblem.

**Neutral / Surface:**
| Token | Value | Usage |
|---|---|---|
| `--bg-page` | `#F9F9F9` | Page/screen background |
| `--surface` | `#FFFFFF` | Cards, nav bar, input fields |
| `--surface-alt` | `#F8F8F8` | Header area, skeleton bg |
| `--border` | `#F5F5F5` | Card borders |
| `--border-mid` | `#EDF1F3` | Input borders, dividers |
| `--neutral-100` | `#F5F5F5` | Light fill |
| `--neutral-200` | `#D5D6D8` (rgb 213,214,216) | Strokes |

**Text:**
| Token | Value | Usage |
|---|---|---|
| `--text-primary` | `#0A0D13` (rgb 10,13,19) | Primary text |
| `--text-heading` | `#212B36` (rgb 33,43,54) | Screen headings |
| `--text-body` | `#263238` (rgb 38,50,56) | Body copy |
| `--text-secondary` | `#6C7278` (rgb 108,114,120) | Supporting/hint text |
| `--text-muted` | `#606060` (rgb 96,96,96) | Muted labels |
| `--text-on-dark` | `#FFFFFF` | Text on coloured/dark backgrounds |

**Semantic:**
| Token | Value | Usage |
|---|---|---|
| `--success` | `#07D8DD` | (teal = positive/live) |
| `--on-primary` | `#FFFFFF` | Text on primary buttons |

### Typography

**Primary font: Raleway** (display, headings, section titles)
- Used for all screen titles, headings H1–H6, navigation labels
- Weights used: Regular, Medium, Semi-Bold, Bold, ExtraBold, Black
- H1: 64px / Bold · H2: 48px / 600 · H3: 32px / 600 · H4: 24px / 600 · H5: 20px / 600 · H6: 18px / 600
- Google Fonts CDN available: `Raleway`

**Secondary font: Inter** (body, UI labels, inputs, captions)
- Used for body text, input values, captions, supporting text, numeric data
- Weights: Regular (400), Medium (500), Semi-Bold (600), Bold (700)
- body1: 16px / 500 · body2: 14px / 500 · subtitle1: 16px / 600 · subtitle2: 14px / 600 · caption: 12px / 500
- Buttons: 14–16px / Bold (700)

**Accent/display: Mulish** (design system headers, large callout numbers)  
**Data/UI: Roboto** (component labels in material-derived components — tabs, chips)  
**Tertiary: Public Sans** (some labels)

### Spacing Scale
Base unit: **4px**. All spacing is multiples of 4.
Common values: 4, 8, 12, 16, 20, 24, 32, 40, 48, 56px

### Corner Radii
- Buttons: `100px` (pill/full-radius)
- Cards: `16px`
- Input fields: `10px`
- Tags/chips: `12–16px`
- Progress indicators: `8px`
- Avatars: `50%`

### Shadows / Elevation
- **Card shadow:** `0px 8px 16px 0px rgba(0,0,0,0.08)`
- **Input shadow:** `0px 1px 2px 0px rgba(228,229,231,0.24)`
- **FAB/button shadow:** `0px 8px 16px 0px rgba(0,0,0,0.24)` (stronger)

### Borders
- Card border: `1px solid #F5F5F5`
- Input border: `1px solid #EDF1F3`
- Active input: `1px solid rgb(217,77,248)`

### Backgrounds
- Page bg: `#F9F9F9` (very light grey, not pure white)
- Screens use **white cards on grey page bg** — classic list-based mobile layout
- Banner cards use solid colours: teal (`#008D8F`), muted cyan (`#B6FAF9`), indigo (`#ECF0FF`)
- No heavy textures or full-bleed photography — clean, flat mobile UI

### Animation
- No complex animations described in designs
- Transitions are implied to be simple: fade/slide between screens
- Progress bar: gradient fill with rounded caps
- Pagination dots: width-expanding active dot (pill) vs round inactive dot

### Hover / Press States
- Buttons: slightly darker fill (opacity-based tint)
- List items: `rgba(0,0,0,0.08)` state-layer overlay (Material-influenced)
- FABs: `rgba(0,0,0,0.08)` shadow on hover

### Cards
- White background, `16px` radius, `1px solid #F5F5F5` border, `0px 8px 16px rgba(0,0,0,0.08)` shadow
- Internal padding: `16px`
- Consistent list-item dividers (thin lines) inside list cards

### Navigation
- **Bottom navigation bar:** white bar, 80px tall, with Home Indicator (32px) beneath — total ~112px from bottom
- Nav icons: 3 primary destinations (Home, [Circle/Groups], [Profile/Settings])
- **Top bar:** white, 64px tall, with page title (Raleway Bold 24px) left-aligned and optional icon right

### Use of Transparency/Blur
- No heavy frosted-glass effects
- Scrim overlays use `rgba(0,0,0,0.3)` for modals/bottom sheets
- State layers use `rgba(0,0,0,0.08)` for pressed states

### Imagery
- Illustrations are flat, vector-based characters (diverse characters/people)
- Colour palette: teal `#07D8DD` and dark `#263238` prominently in illustrations
- Onboarding uses a hero illustration (people with phones)
- Empty states use cute character illustrations

---

## ICONOGRAPHY

Icons come from multiple sources in the Figma file:

1. **Material Symbols / Material Icons** — the primary icon library
   - `arrow_right`, `person`, `settings`, `close`, `add`, `check_small`, `chevron-down`, `local_taxi`, `mobile_friendly`, `flag`, `edit`, `bell_notification`, `finance-mode-rounded`
   - Usage: 24×24px, stroke-fill style
   - CDN: Material Symbols via Google Fonts

2. **Custom SVG icons:**
   - `arrow-narrow-left` — used for back navigation (24×24)
   - `weui-arrow-outlined` — arrow variant (24×24)

3. **Emblem / Logo:**
   - Full wordmark: `assets/Logo_White-01.png` — white version (use on dark/gradient bg)
   - Gradient emblem: `assets/Emblem_Gradient-01.png` — used on white bg (sign-up screen)
   - White emblem: `assets/Emblem_White-01.png` — used in Join FAB, nav contexts on dark bg
   - Gradient logo (with wordmark): `assets/logo-gradient.png` (from Figma, used on onboarding)

4. **Country flags:** Used inline in phone number input (UK flag as default)

5. **No emoji** used anywhere in the product UI.

6. **No custom icon font** — icons are CDN-sourced or embedded SVG.

---

## File Index

```
README.md                    ← This file
SKILL.md                     ← Agent skill definition
colors_and_type.css          ← All CSS custom properties (colors, typography, spacing)

assets/
  Logo_White-01.png          ← Full wordmark, white (1067×1067 upload)
  Emblem_Gradient-01.png     ← Emblem, gradient (upload)
  Emblem_White-01.png        ← Emblem, white (upload)
  logo-white-full.png        ← Full logo on transparent (Figma splash)
  logo-gradient.png          ← Logo with gradient treatment (Figma onboarding)
  onboarding-hero.png        ← Hero illustration for onboarding
  emblem-gradient-fig.png    ← Emblem from Figma sign-up
  emblem-white-fig.png       ← Emblem white from Figma home
  home-banner-illustration.png ← Banner/community illustration

preview/
  colors-primary.html        ← Primary & gradient color swatches
  colors-neutral.html        ← Neutral & surface colors
  colors-semantic.html       ← Text color tokens
  type-primary.html          ← Raleway type specimens
  type-secondary.html        ← Inter type specimens
  type-scale.html            ← Full type scale overview
  spacing.html               ← Spacing tokens
  effects.html               ← Shadows, borders, radii
  components-buttons.html    ← Button variants
  components-inputs.html     ← Input fields
  components-cards.html      ← Card variants
  components-nav.html        ← Navigation bar component
  brand-logos.html           ← Logo/emblem showcase
  brand-gradient.html        ← Gradient system

ui_kits/app/
  README.md                  ← App UI kit overview
  index.html                 ← Interactive app prototype (click-thru)
  Screens.jsx                ← All core screens
  Components.jsx             ← Reusable UI components
```
