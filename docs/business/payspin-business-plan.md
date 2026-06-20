# Payspin — Business Model & 3-Year Financial Plan

> Investor-facing plan for the three revenue lines. Built bottom-up; every number is reproducible from
> `build_payspin_model.py` and the workbook `payspin-financial-model.xlsx`.
> Figures are EUR, ex-VAT. **Every assumption is labelled `ASSUMPTION:` so it can be challenged or swapped.**

---

## 0. Executive summary (1 page)

Payspin is a **non-custodial** SEPA-Instant **payment-link + savings-circle (ROSCA)** fintech for the
Netherlands and Germany. By design it stays outside BaFin/MiCA e-money licensing by never holding funds:
payments are initiated bank-to-bank through a PISP (**Yapily** today, **IbanXS** as DNB-licensed backup).
A swappable `PisProvider` layer and a planned Phase-3 stack (Monerium EURe, Circle MPC wallets, Gnosis Chain)
aim to push marginal cost toward zero, especially for ROSCA. An Islamic legal opinion (fatwa) underpins a
flat-fee, non-interest, ethical-finance positioning.

**Three revenue lines:** (1) consumer payment links, (2) business payment links, (3) ROSCA "Circles".

**The honest verdict.** Two of the three lines are strong *strategically* but weak *as near-term revenue*:

- **Consumer payment links barely monetise.** P2P "request money" is free at Tikkie, bank apps and PayPal.me.
  Willingness-to-pay for €0.50/link is structurally near zero. This line is a **viral acquisition funnel**, not a P&L line.
- **ROSCA is the differentiated, sticky, low-CAC wedge** — but small in absolute euros at €1/user/month.
- **Business payment links are the only real profit engine** — and the base-case ceiling (≈900 SMEs at ~€11 ARPA)
  is **too small to cover the cost base**. Break-even needs **~2,600 business accounts** (or ARPA ~€35) — i.e. a
  bigger TAM bet than "a Tikkie alternative for individuals".

**Numbers (base case, conservative):** Y1 revenue €1.6k, Y2 €23.5k, Y3 €117k; exit-M36 MRR ≈ €13k against a
~€33k/month cost base. **Monthly break-even is NOT reached within 36 months** (and not by M72 at these caps).
Peak cumulative funding need within 36 months ≈ **€0.55M**; to fund a credible run at business-led break-even,
**≈€0.8–1.2M** total across pre-seed + seed.

**Investability verdict:** Fundable as a **pre-seed bet (€300–450k)** on the wedge (ROSCA + ethical/diaspora
niche + DE coverage where Tikkie is absent), the swappable-rail resilience story, and the Phase-3 cost collapse —
**not** on consumer unit economics. A seed round (€1.0–1.5M) is justified **only after** the business line shows
~€8–15k MRR and healthy LTV:CAC. **Recommended ask now: €400k pre-seed** (18-month runway), use of funds:
60% product/eng (business-link tooling + ROSCA), 25% GTM (NL/DE diaspora + SME), 15% compliance/legal + buffer.

---

## A. Revenue model — 36-month adoption & revenue

**Adoption is modelled as logistic S-curves** (not flat ramps), reflecting slow trust-building early, an
inflection mid-curve, and saturation toward the cap. Volumes are inputs on the `Model` sheet; revenue is a live
formula (`users × price`).

**ASSUMPTION (base-case caps, NL+DE, 36-month horizon):**
- Consumer registered users → ~15,000 cap (≈11,000 by M36). Big base, tiny ARPU.
- Business accounts → ~900 cap (≈820 by M36). Slower, sales-led, starts M4.
- ROSCA → ~650 active circles cap (≈580 circles / ~3,500 users by M36). Community-led, starts M6.

**Per-stream behavioural assumptions:**
- Consumer: 55% of registered are active senders; 2.2 links sent/active/month; 70% of links get paid (= PISP tx);
  **3% of active users exceed the 3-free-link tier** (benchmark: 2–5% freemium→paid); payers send 4 billable links/mo.
- Business: 35 completed tx/account/month; **blended ARPA €11/mo** (subscription + per-tx).
- ROSCA: 6 users/circle, €1/user/month, 7 PISP tx/circle/month (6 contributions + 1 payout).

**Resulting revenue (base):**

| Stream | Y1 | Y2 | Y3 | M36 MRR |
|---|---|---|---|---|
| Consumer links | ~€0.2k | ~€0.4k | ~€0.5k | ~€0.46k |
| Business links | ~€1.1k | ~€18k | ~€100k | ~€9.0k |
| ROSCA | ~€0.3k | ~€5k | ~€16k | ~€3.5k |
| **Total** | **€1.6k** | **€23.5k** | **€117k** | **€13.0k** |

The shape is the story: **business dominates by Y3, consumer is rounding error, ROSCA is a steady minority.**

---

## B. Marketing plan & CAC

**ASSUMPTION (channels & monthly spend ramp):** €800/mo (M1–3) → €1.5k (M4–6) → €3k (M7–12) → €6k (Y2) → €10k (Y3).

| Channel | Best for | CAC trend (Y1→Y3) | Notes |
|---|---|---|---|
| Founder-led + diaspora/community partnerships (mosques, Egyptian/Turkish/Moroccan student & expat groups, ROSCA communities) | ROSCA + consumer | €6 → €3 | Cheapest, highest-trust; the fatwa/ethical angle is a wedge here |
| Content/SEO ("betaalverzoek", "geld terugvragen"; DE "Geld zurückfordern"; Islamic-finance) | Consumer + business | €15 → €5 | Slow ramp (6–12 mo), compounding |
| Referral / "give-a-link" | Consumer | €8 → €4 | Viral loop; the only justifiable consumer acquisition |
| Performance social (Meta/TikTok/IG), NL/DE + diaspora | Consumer + ROSCA | €18 → €10 | EMEA CPI €2–4; DE upper end; use sparingly |
| Founder sales + LinkedIn (SMEs) | Business | €120 → €60 | High CAC, high LTV; the channel that pays back |

**LTV:CAC by segment** (see `Unit_Economics` sheet):

| Segment | ARPU/mo | Margin | Life | LTV | CAC | LTV:CAC | Verdict |
|---|---|---|---|---|---|---|---|
| Consumer (paying) | €2.0 | 60% | 18m | €21.6 | €6 | 3.6 | OK only if acquired organically |
| Consumer (blended, all users) | €0.10 | 60% | 14m | €0.84 | €6 | 0.14 | **Never buy paid consumer traffic** |
| Business account | €11 | 75% | 30m | €247 | €90 | 2.7 | **Primary engine** |
| ROSCA user | €1 | 80% | 12m | €9.6 | €5 | 1.9 | Sticky, but acquire per-circle |
| ROSCA per 6-person circle | €6 | 80% | 12m | €57.6 | €18 | 3.2 | Acquire 6 users per CAC event |

**Takeaway:** paid acquisition is only defensible for **business** (and ROSCA *circles*, not individuals).
Consumer growth must be **viral/organic** — any meaningful paid spend on consumer destroys money.

---

## C. Full cost structure (36-month, with scaled Yapily)

**Yapily scaling — ASSUMPTION (Yapily does not publish per-tx pricing; grounded in "<1%/tx" market):**
- Fixed: €500 licence + €300 data + €300 platform base = **€1,100/mo, includes first 500 successful PIS tx/mo.**
- Overage (negotiated volume estimate): **€0.20/tx (501–5,000), €0.12/tx (5,001–25,000), €0.08/tx (25,000+).**
- *Implication:* the €1,100 bundle dominates early (average cost per tx is very high at low volume); marginal cost
  only falls below the per-link price once volume builds. The first 500 tx/month are effectively "free", so early
  incremental revenue is ~100% gross margin until volume crosses the bundle.

**Other cost lines & ASSUMPTIONS:**
- **Tech/dev:** the €300/mo CTO is a **non-market placeholder** (≈5–6 freelance hours). Modelled to rise to market:
  €1.5k (M7–12) → €4k (M13–18, CTO near-full-time) → **+2nd technical hire from M19 (€4k)** → €9k (M25+).
- **Founder salary:** NL **DGA minimum salary is €58,000/yr (2026)**. Modelled as **deferred** while loss-making
  (token €1.5k from M13, €3k from M25). **RISK/FLAG:** the tax authority only tolerates a sub-minimum DGA salary
  temporarily; once profitable (or after a few years) the full €58k obligation lands and adds ~€5k+/mo of burden
  — this is the single biggest hidden cost in the founder's original numbers.
- **NL BV recurring:** ASSUMPTION €450/mo (bookkeeping €250 + registered address €75 + filings/CIT/UBO amortised €125).
  Market range €2.5–6.5k/yr. One-time incorporation €1,200 (M1).
- **German UG:** ASSUMPTION incorporate M7 for DE operations, one-time €1,000; recurring Steuerberater/filings €300/mo.
- **Legal/compliance:** ASSUMPTION €150/mo ongoing (GDPR/terms upkeep) + one-time €3,000 fatwa/legal opinion (≈M9) +
  €3,000 initial legal (M1). PSD2 note: Payspin relies on the **PISP's** licence; it does not hold funds, so it
  avoids its own EMI/PI licence — this is the core regulatory-cost advantage and must be preserved.
- **Tools/infra:** €200 → €400 → €800/mo (hosting, SMS/Twilio, email, analytics, app-store).
- **PISP redundancy (IbanXS):** ASSUMPTION €350/mo from M13 (resilience after the Yapily instability).
- **Contingency:** 10% of core opex every month.

**Annual cost totals (base):** Y1 ≈ €77k · Y2 ≈ €233k · Y3 ≈ €385k.

**Tax treatment — ASSUMPTION:** two-entity structure (NL Flex BV holding + German UG operating in DE).
NL CIT 19% (≤€200k) / 25.8% (above); DE UG ~30–33% combined (KSt 15% + Soli 0.825% + Gewerbesteuer ~14–17%).
Blended **effective 22%** applied **only after loss carry-forward** is exhausted. Given losses throughout the
modelled horizon, **cash tax ≈ €0** for 36 months; losses carry forward (NL: €1m fully + 50% above; DE similar).

---

## D. P&L / cash-flow

Delivered as the live workbook (`payspin-financial-model.xlsx`, `Model` + `Annual_Summary` sheets).
Summary (base):

| | Y1 | Y2 | Y3 |
|---|---|---|---|
| Revenue | €1.6k | €23.5k | €117.4k |
| Cost | €76.6k | €233.0k | €385.4k |
| Net | −€75.0k | −€209.5k | −€267.9k |
| Cum cash (year-end) | −€75k | −€284k | **−€552k** |

---

## E. Break-even & sensitivity

- **Base & worst: monthly break-even NOT reached within 36 months** (nor by M72 at base caps).
- **Best: break-even just past M36** (M36 MRR ≈ €31k vs ~€33k cost), driven almost entirely by business scaling.
- **Volume required for monthly break-even** at the M36 cost base (~€33k/mo): **≈2,600 business accounts at €11 ARPA**,
  or **ARPA ~€35** at ~820 accounts, or a combination. Consumer + ROSCA together contribute only ~€4k MRR at M36.

| Scenario | Levers | Y1 rev | Y2 rev | Y3 rev | M36 MRR | Break-even | Peak funding (36m) |
|---|---|---|---|---|---|---|---|
| **Worst** | conv ×0.5, biz ×0.55, ARPA €9, ROSCA ×0.6, Yapily ×1.3 | €0.8k | €11.7k | €57.8k | €6.4k | beyond M36 | −€623k |
| **Base** | as modelled | €1.6k | €23.5k | €117.4k | €13.0k | beyond M36 | −€552k |
| **Best** | conv ×1.5, biz ×2.2, ARPA €14, ROSCA ×1.4, Yapily ×0.85 | €3.6k | €54.6k | €278.6k | €30.9k | ~M37–38 | −€380k |

**Stress conclusion:** the model is *fragile to the business stream and the cost base*, not to consumer conversion.
Halving consumer conversion barely moves the result; the business ceiling and ARPA are everything.

---

## F. Pricing recommendations (answers to every open question)

1. **Is flat €0.50/consumer link sound?** No — not as a revenue line. Consumers won't pay when Tikkie/banks are
   free. **Recommendation:** keep **3 free links/month**, charge **€0.50** beyond it only to capture the rare power
   user, but **model consumer as a funnel, not revenue**. Do not invest in consumer monetisation mechanics.
2. **Flat vs blended for consumer?** A flat €0.50 over-charges micro-amounts (€0.50 on a €5 link = 10%) and
   under-charges large ones. But since volume is tiny, **keep it simple: flat €0.50** — complexity isn't worth it here.
3. **Realistic freemium→paid conversion:** **3% of active users** (base), 2% (worst), 5% (best). Benchmarks: 2–5%
   typical consumer fintech, 6–8% exceptional.
4. **Is €0.50/business tx high or low?** **Mixed.** Versus cards (1.5–3.5%) it's very cheap on high tickets; versus
   **Tikkie Business** (€7.50/mo incl. 20, then €0.25/€0.20/€0.15) flat €0.50 is **expensive at volume** and on small
   tickets (€0.50 on a €15 sale = 3.3%). A single flat €0.50 is **not defensible** across all business sizes.
5. **Segment business?** Yes. **Recommendation — three tiers:**
   - **Starter (PAYG):** €0/mo + **€0.40/tx** (beats card fees; for low-volume sellers).
   - **Pro:** **€9/mo** incl. 50 tx, then **€0.20/tx** (undercuts Tikkie's €7.50+€0.25; adds DE coverage + SEPA Instant + multi-bank).
   - **Scale:** **€29/mo** incl. 300 tx, then **€0.15/tx** (matches Tikkie's floor, adds value).
   - Add a **min fee €0.20/tx** floor so micro-tickets stay profitable above Yapily marginal cost.
6. **ROSCA — is €1/user/month adequate?** It's **low** vs comps (Roond 1.5% of each pot or €5.99/mo; StepLadder
   £1–18/mo). But the **flat, non-% fee is a positioning asset** (Sharia-compliant, transparent). **Recommendation:**
   keep flat, raise to **€1.50/user/month** and add a **one-time €2.99 KYC/onboarding fee per member** (mirrors Roond/Cirkkle).
   This ~lifts circle lifetime revenue from €36 to €72 with negligible churn impact.

**Final recommended price list:**

| Service | Price |
|---|---|
| Consumer links | 3 free/mo, then €0.50/link (funnel, not a growth lever) |
| Business — Starter | €0/mo + €0.40/tx (min €0.20) |
| Business — Pro | €9/mo incl. 50 tx, then €0.20/tx |
| Business — Scale | €29/mo incl. 300 tx, then €0.15/tx |
| ROSCA | €1.50/user/month + €2.99 one-time KYC/member |

---

## G. Additional Yapily-enabled revenue opportunities

| Opportunity | Feasibility | Potential | Note |
|---|---|---|---|
| **AIS — account verification / balance check** (e.g. confirm payer solvency, IBAN-name match) | High (Yapily AIS) | Med | Sell to business tier as add-on; +€300/mo Yapily data line |
| **Recurring / subscription collection (VRP-style sweeping)** | Med (rail-dependent) | **High** | Best B2B upsell; recurring rent/tuition/membership collection — sticky, higher ARPA |
| **B2B bulk disbursement / payouts** (payroll, marketplace seller payouts, refunds) | Med-High | **High** | Natural extension of payment links; marketplaces are the highest-ARPA business segment |
| **White-label payment links** (embed Payspin links in another SaaS) | Med | Med-High | Platform/API revenue; leverages the `PisProvider` abstraction |
| **Confirmation-of-payee / fraud-reduction data** | Med | Low-Med | Compliance-adjacent add-on |

**Priority:** recurring collection + B2B disbursement + marketplace payouts — these raise **business ARPA** toward
the ~€35 needed for break-even, and are the most direct fix to the model's central weakness.

---

## H. Strategic focus — Year 1

**Prioritise the ROSCA + consumer-funnel wedge in Y1; turn on business monetisation hard from late Y1/Y2.**

Reasoning: a solo founder + one (under-priced) dev cannot run a consumer viral product, a B2B sales motion, *and*
a ROSCA ops product simultaneously. ROSCA has the **lowest CAC** (community-led), **highest stickiness**, and the
**clearest differentiation** (flat-fee, ethical, fatwa-backed, diaspora-native) — it builds the trusted user base and
brand. The consumer links ride the same audience virally and feed the funnel. **Business has the best LTV:CAC and is
the eventual engine**, but it needs product maturity, case studies and sales bandwidth — so it scales in Y2 once the
base and brand exist. *Caveat:* because break-even is business-dependent, business validation must begin (a few
pilot SMEs) by ~M6 even while ROSCA leads.

---

## I. Capital requirement (derived from monthly burn)

| Period | Net burn | Cumulative |
|---|---|---|
| Year 1 | ~€75k | ~€75k |
| Year 2 | ~€210k | ~€285k |
| Year 3 | ~€268k | ~€552k |
| To reach business-led break-even (~M42–46 in upside) | +€250–350k | **~€0.8–1.2M** |

**Recommended tranches:** **Pre-seed €400k** (covers Y1 + buffer to ~M16–18 and the first business-traction proof) →
**Seed €1.0–1.5M** once business MRR is proven, to scale the SME/marketplace engine and (optionally) Phase-3.

---

## J. Fundraising timing

**Approach investors when you can show:** (1) **2,500–5,000 active users** across consumer+ROSCA with strong
retention (ROSCA repeat rate, weekly active links), **(2) the first €3–8k of business MRR with LTV:CAC > 2.5**, and
**(3) ROSCA cohort economics** proving stickiness. **Not earlier** (no proof the only profit engine works — you'd
raise on a free consumer product nobody pays for, at a bad price). **Not later** (cash runs out ~M14–18 at base burn).
Practically: **start conversations ~M9–12, close pre-seed by ~M12–15.**

---

## K. Investor attractiveness verdict + Yapily-independence analysis

**Is it fundable?** Yes, **as a pre-seed bet** — on (a) the ROSCA/ethical/diaspora wedge in a real, underserved EU
niche where Tikkie doesn't operate (DE) and incumbents ignore the community/fatwa angle, (b) the non-custodial
regulatory-light structure, (c) the swappable-rail resilience, and (d) the Phase-3 cost collapse. **Not fundable** on
a "we charge consumers €0.50/link" thesis. **Investor profile:** **pre-seed fintech angels + ethical/Islamic-finance
or diaspora-focused angels**, then a **fintech-focused seed fund** once business MRR exists. **Realistic terms:**
pre-seed €300–450k on a SAFE/convertible at a €2–3.5M cap.

**Cost to become Yapily-independent.** Replacing a PISP aggregator means **becoming/contracting a licensed PISP
yourself**: a PSD2 **Payment Initiation** authorisation (BaFin in DE or DNB in NL), regulatory capital, a compliance
function, and direct bank API integration + maintenance across NL/DE banks. **ASSUMPTION:** licence + legal + capital
+ compliance hires + multi-bank integration ≈ **€600k–€1.2M one-time and ≈€250–400k/yr to run** — *larger than the
entire 3-year operating plan.*

**Recommendation: do NOT pursue Yapily-independence.** Stay on a **PISP-aggregation model**, but **de-risk via
multi-provider redundancy** (Yapily + IbanXS through the existing `PisProvider` abstraction — already the right call
given Yapily's instability). Aggregation keeps Payspin **out of direct licensing**, which is the company's core
strategic advantage. Direct licensing only makes sense at a *much* larger scale (when per-tx aggregator margin on
millions of transactions exceeds the run-cost of a licence) — far beyond this plan's horizon. The **Phase-3 stablecoin
rail (Monerium/Gnosis)** is a *different* and cheaper route to reducing rail dependence for the **ROSCA** product
specifically, and is the better long-term lever than a PISP licence.

---

## L. Blockchain (Phase-3) migration timing

Phase 3 (Monerium EURe, Circle MPC wallets, Gnosis Chain ROSCA contracts) targets near-zero marginal cost for ROSCA
payout coordination.

**Recommended trigger — migrate ROSCA to Phase-3 when ALL hold:**
1. **ROSCA volume > ~3,000 PISP tx/month** (so Yapily overage on ROSCA alone is material — at ~€0.20/tx that's
   €600+/mo of avoidable cost), AND
2. **Funded** (seed closed — Phase-3 needs real eng time and audited contracts), AND
3. **Product-market fit on ROSCA proven** (don't re-platform a product you might kill).

**Regulatory trade-off (MiCA):** touching crypto rails (EURe, MPC wallets) risks pulling Payspin **into MiCA scope**
(CASP obligations) and undermines the very non-custodial/regulatory-light advantage that makes the company cheap to
run and easy to fund. **Migrate later, not earlier.** Earlier = premature MiCA exposure + eng burn before PMF.
Later = you only take on MiCA complexity once ROSCA is proven and the cost saving is real. **Use Monerium (a regulated
EMI issuing EURe) and keep custody non-custodial** to minimise MiCA surface; get a specific MiCA legal opinion before
any mainnet ROSCA flow. Until the trigger fires, **ROSCA stays on the PISP rail** — €1.50/user already yields high
margin there because the €1,100 Yapily bundle covers early volume.

---

### Appendix — sources for benchmarks
Tikkie Business pricing (ABN AMRO developer portal); Yapily/TrueLayer pricing (RFP.wiki, XYZEO, OpenBankingTracker —
"<1%/tx", custom); ROSCA comps (Roond, StepLadder, Cirkkle, Money Fellows); conversion & CAC (CrazyEgg/Lenny's,
First Page Sage 2026, Adapty, PM Toolkit); NL BV costs & CIT (KVK, Belastingdienst, MijnBV); DE UG tax (germancompanyformation, Norman Finance, Stripe). Researched June 2026.
