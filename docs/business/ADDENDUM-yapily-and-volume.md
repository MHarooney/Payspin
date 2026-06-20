# Addendum — corrected Yapily pricing & volume-target reality check

This addendum supersedes the Yapily cost treatment in `payspin-business-plan.md` and adds a
transaction-volume analysis driven by the founder's targets. Model: `build_payspin_model_v2.py`,
workbook `payspin-financial-model-v2.xlsx`.

## 1. Corrected Yapily cost (did v1 count it? No.)

**v1 was wrong.** It assumed tiered overage (€0.20/€0.12/€0.08) above **500** tx. The real deal is:

> **€1,100/mo fixed (license €500 + data €300 + platform €300) including up to 3,000 tx/month.
> Above 3,000 tx/month: €0.30 per transaction. License + data stay fixed at any volume.**

`Yapily(tx) = 1,100 + 0.30 × MAX(0, monthly_tx − 3,000)`

The corrected rate (€0.30) is **higher** than v1 assumed, so the cost picture is materially worse,
especially at the volumes targeted below.

## 2. Volume targets: 100k (Y1) / 200k (Y2) / ~350k (Y3)

ASSUMPTION: Y3 = 350k (founder gave Y1/Y2). Monthly ramp is an S-curve scaled to hit each annual total.
Transaction MIX (ASSUMPTION, the most important driver):

| Year | Consumer-free | Consumer-billable | Business | ROSCA |
|---|---|---|---|---|
| Y1 | 62% | 3% | 23% | 12% |
| Y2 | 55% | 3.5% | 28% | 13.5% |
| Y3 | 50% | 4% | 32% | 14% |

## 3. The finding: on a €0.30 rented rail, VOLUME LOSES MONEY

**Config A — your targets at €0.30/tx and current ("beat-Tikkie") pricing:**

| | Y1 | Y2 | Y3 |
|---|---|---|---|
| Transactions | 100k | 200k | 350k |
| Revenue | €22.0k | €50.5k | €94.6k |
| **Yapily cost** | **€32.4k** | **€62.4k** | **€107.4k** |
| **Gross margin** | **−47%** | **−24%** | **−14%** |
| Net (EBT) | −€139k | −€382k | −€542k |

Over 3 years: **revenue €167k vs Yapily €202k** — the rail alone costs more than everything you earn.
Peak cash need **−€1.06M**. Each additional *free* consumer transaction above 3,000/mo is a pure −€0.30,
and business per-tx yield (~€0.11–0.22 under low pricing) is **below** the €0.30 cost. **Growth accelerates losses.**

### Why the Tikkie comparison is misleading
Tikkie does huge volume in one country **because it IS a bank (ABN AMRO) and owns the rail** — its
marginal cost per transaction is ~zero. Payspin **rents** the rail from Yapily at €0.30/tx. You cannot
win a per-transaction price war against a bank-owned rail. Operating in NL **and** DE doubles the
addressable users but **also doubles the transactions you pay €0.30 for**. Volume is only an asset if
each transaction yields more than it costs.

## 4. The fix — Config B (viable)

Four levers, modelled together:
1. **Renegotiate Yapily to ~€0.10/tx** using the volume as leverage (100k+/yr is real negotiating power).
2. **Reprice business to ~€0.40/tx effective** (per-tx + subscription) so yield > rail cost.
3. **Cap free-consumer share at ≤40%** of mix (the free tail is the loss-maker) and push the rest to monetised flows.
4. **Move ROSCA to Phase-3 (Monerium/Gnosis, ~€0.02/tx) from ~M18** — kills the rail cost on the highest-tx-per-euro product.

| | Y1 | Y2 | Y3 |
|---|---|---|---|
| Revenue | €34.9k | €72.6k | €128.8k |
| Yapily cost | €19.6k | €28.0k | €40.7k |
| **Gross margin** | **+44%** | **+61%** | **+68%** |

3-year Yapily drops from €202k → **€88k**; gross margin flips from negative to **+68%** by Y3.
Still net-negative (needs more scale to cover opex) but now **structurally sound** — every transaction earns more than it costs.

## 5. Are the targets realistic, and how to achieve them?

**Volume-wise: yes, 100k/Y1 is achievable** (it's a rounding error vs Tikkie's millions) with aggressive
viral + diaspora GTM across NL+DE. **But raw volume is the wrong target.** The right targets are:
- **Paid/monetised transaction share** (keep free-consumer ≤40%).
- **Blended yield/tx > rail cost** (price so every tx earns more than Yapily charges).
- **Business accounts + ROSCA users** (the segments that actually carry margin).

**How to hit a *viable* 100k:**
- **GTM:** diaspora/community partnerships (mosques, student & expat associations, ROSCA communities),
  referral "give-a-link" virality, content/SEO in NL+DE, founder-led SME sales. DE is greenfield (no Tikkie).
- **Rail:** sign the IbanXS redundancy *and* use the volume to renegotiate Yapily to ≤€0.10/tx; start Phase-3 design.
- **Mix:** lead with ROSCA (best yield/tx) + business subscriptions; treat consumer-free as a capped funnel, not a goal.
- **Pricing:** business min €0.40/tx-equivalent; ROSCA €1.50/user/mo + €2.99 KYC; consumer 3 free then €0.50.

## 6. Other services you can publish on Yapily (expanded)

| Service | Yapily capability | Yield vs €0.30 cost | Priority |
|---|---|---|---|
| **Recurring / subscription collection** (rent, tuition, memberships, ROSCA contributions) | PIS / VRP-style | High (recurring, sub-priced) | **1** |
| **B2B bulk disbursement / marketplace payouts** (seller payouts, payroll, refunds) | Bulk PIS | High (per-batch + %) | **1** |
| **Account verification / IBAN-name & solvency check** | AIS | Med (per-check fee) | 2 |
| **Confirmation-of-payee / fraud signals** | AIS | Med (add-on to business) | 2 |
| **White-label payment links / embedded API** | PIS via PisProvider | High (platform fee) | 2 |
| **Account aggregation / balance & cashflow view** | AIS | Med (subscription) | 3 |
| **Sweeping / auto-top-up between own accounts** | VRP (rail-dependent) | Med | 3 |

The top priorities (recurring collection, B2B/marketplace payouts) are the ones that **raise yield per
transaction above the rail cost** — i.e. they fix the Config-A problem directly, rather than adding more
low-yield volume.
