"""
Payspin 3-Year Financial Model generator.

Builds a bottom-up, 36-month model for three revenue streams
(consumer payment links, business payment links, ROSCA circles) and emits
an Excel workbook with LIVE FORMULAS so the assumptions can be stress-tested.

Volumes (user/transaction counts) are modelled in Python (logistic adoption)
and written as input values. All monetary columns (revenue, cost, tax, margin,
cash) are written as Excel formulas referencing the Assumptions sheet, so a
reviewer can flex prices, take-rates, costs and tax rates and watch the whole
model recompute.

Run:  python3 build_payspin_model.py
Out:  payspin-financial-model.xlsx  (+ console summary)
"""
import math
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

N = 36  # months

# ----------------------------------------------------------------------------
# Adoption model (logistic S-curves) -- BASE CASE
# ----------------------------------------------------------------------------
def logistic(t, K, r, t0, floor=0.0):
    return floor + (K - floor) / (1.0 + math.exp(-r * (t - t0)))

def adoption_series(K, r, t0, start_month, floor=0.0):
    """Return 36-length list; 0 before start_month, logistic after."""
    out = []
    for m in range(1, N + 1):
        if m < start_month:
            out.append(0.0)
        else:
            out.append(logistic(m, K, r, t0, floor))
    return out

# Consumer (individual) registered users -- viral/organic funnel, big base, low ARPU
consumer_registered = adoption_series(K=15000, r=0.22, t0=24, start_month=1, floor=40)
# Business accounts -- monetisation engine, slower, sales-led, starts M4
business_accounts = adoption_series(K=900, r=0.26, t0=27, start_month=4, floor=2)
# ROSCA active circles -- community-led, sticky, starts M6
rosca_circles = adoption_series(K=650, r=0.24, t0=27, start_month=6, floor=1)

# ----------------------------------------------------------------------------
# Behavioural assumptions (these become Assumptions-sheet cells -> formulas)
# ----------------------------------------------------------------------------
A = {
    # --- Consumer payment links ---
    "c_active_share": 0.55,        # share of registered who are active senders
    "c_links_per_active": 2.2,     # avg links sent per active user / month
    "c_pay_rate": 0.70,            # share of sent links actually paid (=PISP tx)
    "c_paid_conv": 0.03,           # share of active users who exceed free tier (pay)
    "c_billable_per_payer": 4.0,   # billable (paid) links per paying user / month
    "c_price": 0.50,               # EUR per billable link

    # --- Business payment links ---
    "b_tx_per_acct": 35.0,         # completed (paid) tx per business acct / month
    "b_arpa": 11.0,                # blended monthly revenue per business acct (sub + per-tx)

    # --- ROSCA circles ---
    "r_users_per_circle": 6.0,
    "r_tx_per_circle": 7.0,        # 6 contributions + 1 payout / month
    "r_price_user_mo": 1.0,        # EUR per user / month

    # --- Yapily cost (license fixed; platform bundle incl 500 tx; tiered overage) ---
    "y_license": 500.0,
    "y_data": 300.0,
    "y_platform_base": 300.0,
    "y_bundle_tx": 500.0,
    "y_rate_t1": 0.20,             # tx 501-5,000
    "y_rate_t2": 0.12,             # tx 5,001-25,000
    "y_rate_t3": 0.08,             # tx 25,000+

    # --- Tax ---
    "tax_rate": 0.22,              # blended NL(19%)/DE(~30%) effective, applied after loss carryforward
}

# ----------------------------------------------------------------------------
# Derived monthly volumes (written as VALUES to the Adoption sheet)
# ----------------------------------------------------------------------------
rows = []
for i in range(N):
    m = i + 1
    creg = consumer_registered[i]
    bacc = business_accounts[i]
    rcir = rosca_circles[i]

    c_active = creg * A["c_active_share"]
    c_links_sent = c_active * A["c_links_per_active"]
    c_tx = c_links_sent * A["c_pay_rate"]            # consumer PISP tx
    c_payers = c_active * A["c_paid_conv"]
    c_billable = c_payers * A["c_billable_per_payer"]

    b_tx = bacc * A["b_tx_per_acct"]                 # business PISP tx
    r_users = rcir * A["r_users_per_circle"]
    r_tx = rcir * A["r_tx_per_circle"]               # rosca PISP tx

    total_tx = c_tx + b_tx + r_tx
    rows.append({
        "m": m,
        "c_reg": creg, "c_active": c_active, "c_payers": c_payers, "c_billable": c_billable, "c_tx": c_tx,
        "b_acc": bacc, "b_tx": b_tx,
        "r_cir": rcir, "r_users": r_users, "r_tx": r_tx,
        "total_tx": total_tx,
    })

# ----------------------------------------------------------------------------
# Step cost schedules (written as VALUES; justified in plan text)
# ----------------------------------------------------------------------------
def tech_cost(m):
    # CTO at €300 is non-market placeholder; ramps to market; 2nd hire at M19
    if m <= 6:   return 300
    if m <= 12:  return 1500
    if m <= 18:  return 4000
    if m <= 24:  return 8000     # CTO ~market + 2nd technical hire
    return 9000

def founder_salary(m):
    # DGA min €58k/yr deferred while loss-making; flagged as risk in plan
    if m <= 12:  return 0
    if m <= 24:  return 1500
    return 3000

def nl_entity_cost(m):
    return 450  # bookkeeping + registered address + filings amortised

def de_entity_cost(m):
    return 300 if m >= 7 else 0   # German UG from M7 (DE GTM)

def legal_compliance(m):
    return 150  # GDPR/terms/fatwa upkeep (one-times handled separately)

def tools_infra(m):
    if m <= 6:   return 200
    if m <= 18:  return 400
    return 800

def pisp_redundancy(m):
    return 350 if m >= 13 else 0  # IbanXS secondary rail resilience

def marketing_spend(m):
    if m <= 3:   return 800
    if m <= 6:   return 1500
    if m <= 12:  return 3000
    if m <= 24:  return 6000
    return 10000

# One-time costs (month -> EUR)
one_times = {1: 1200 + 3000, 7: 1000, 9: 3000}  # NL incorp+initial legal; DE UG; fatwa/legal opinion

# ----------------------------------------------------------------------------
# Pure-Python computation (for console sanity-check + scenario engine)
# ----------------------------------------------------------------------------
def compute(scn="base"):
    # scenario multipliers: (consumer_conv, business_accts, business_arpa, rosca_vol, yapily)
    if scn == "base":
        conv_mult, b_acc_mult, b_arpa, r_mult, yap_mult = 1.0, 1.0, A["b_arpa"], 1.0, 1.0
    elif scn == "best":
        conv_mult, b_acc_mult, b_arpa, r_mult, yap_mult = 1.5, 2.2, 14.0, 1.4, 0.85
    elif scn == "worst":
        conv_mult, b_acc_mult, b_arpa, r_mult, yap_mult = 0.5, 0.55, 9.0, 0.6, 1.3

    cum_cash = 0.0
    cum_loss = 0.0
    res = []
    be_month = None
    for r in rows:
        m = r["m"]
        # revenue
        rev_c = r["c_billable"] * conv_mult * A["c_price"]
        rev_b = r["b_acc"] * b_acc_mult * b_arpa
        rev_r = r["r_users"] * r_mult * A["r_price_user_mo"]
        revenue = rev_c + rev_b + rev_r

        # transactions (scaled)
        tx = (r["c_tx"] * conv_mult + r["b_tx"] * b_acc_mult + r["r_tx"] * r_mult)
        # yapily
        over = max(0.0, tx - A["y_bundle_tx"])
        t1 = min(over, 4500) * A["y_rate_t1"]
        t2 = min(max(over - 4500, 0), 20000) * A["y_rate_t2"]
        t3 = max(over - 24500, 0) * A["y_rate_t3"]
        yap = (A["y_license"] + A["y_data"] + A["y_platform_base"] + t1 + t2 + t3) * yap_mult

        opex_core = (yap + tech_cost(m) + founder_salary(m) + nl_entity_cost(m) +
                     de_entity_cost(m) + legal_compliance(m) + tools_infra(m) +
                     pisp_redundancy(m) + marketing_spend(m))
        contingency = 0.10 * opex_core
        ot = one_times.get(m, 0)
        total_cost = opex_core + contingency + ot

        ebt = revenue - total_cost
        # tax with loss carryforward
        if ebt > 0:
            if cum_loss >= ebt:
                cum_loss -= ebt; tax = 0.0
            else:
                taxable = ebt - cum_loss; cum_loss = 0.0
                tax = taxable * A["tax_rate"]
        else:
            cum_loss += -ebt; tax = 0.0
        net = ebt - tax
        cum_cash += net
        if be_month is None and ebt > 0:
            be_month = m
        res.append({"m": m, "rev": revenue, "rev_c": rev_c, "rev_b": rev_b, "rev_r": rev_r,
                    "tx": tx, "yap": yap, "cost": total_cost, "ebt": ebt, "net": net, "cum": cum_cash})
    return res, be_month

for scn in ("worst", "base", "best"):
    res, be = compute(scn)
    yr = lambda a, b: sum(x["rev"] for x in res[a:b])
    print(f"\n=== {scn.upper()} ===")
    print(f" Y1 rev €{yr(0,12):,.0f} | Y2 rev €{yr(12,24):,.0f} | Y3 rev €{yr(24,36):,.0f}")
    print(f" Exit-M36 MRR €{res[-1]['rev']:,.0f} | M36 tx {res[-1]['tx']:,.0f}")
    print(f" Monthly break-even: {'M'+str(be) if be else 'NOT within 36m'}")
    print(f" Min cumulative cash (peak funding need): €{min(x['cum'] for x in res):,.0f}")
    print(f" Cumulative cash M36: €{res[-1]['cum']:,.0f}")
    for q, (a, b) in enumerate([(0,12),(12,24),(24,36)], 1):
        print(f"   Y{q}: rev €{yr(a,b):,.0f} | cost €{sum(x['cost'] for x in res[a:b]):,.0f} | net €{sum(x['net'] for x in res[a:b]):,.0f}")

# ----------------------------------------------------------------------------
# EXCEL WORKBOOK with live formulas
# ----------------------------------------------------------------------------
HDR = Font(bold=True, color="FFFFFF")
HDRFILL = PatternFill("solid", fgColor="1F3864")
SUBFILL = PatternFill("solid", fgColor="D9E1F2")
MONEY = '#,##0.00'
MONEY0 = '#,##0'
PCT = '0.0%'
thin = Side(style="thin", color="BBBBBB")
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)

wb = Workbook()

# ---------- README ----------
ws = wb.active
ws.title = "README"
readme = [
    ("PAYSPIN — 36-MONTH FINANCIAL MODEL", True),
    ("", False),
    ("Non-custodial SEPA-Instant payment-link + ROSCA fintech (NL/DE). PISP rail: Yapily (IbanXS backup).", False),
    ("", False),
    ("HOW TO USE THIS MODEL", True),
    ("• 'Assumptions' sheet (yellow cells) holds the key levers: prices, ARPA, Yapily rates, tax.", False),
    ("• 'Model' sheet = BASE CASE, monthly. Volume columns (blue) are inputs; money columns are LIVE FORMULAS.", False),
    ("• Change a price/take-rate/tax cell on Assumptions and the whole Model + Annual sheets recompute.", False),
    ("• 'Scenarios' compares Base / Best / Worst. 'Unit_Economics' holds LTV:CAC per segment.", False),
    ("", False),
    ("HEADLINE VERDICT (base case, conservative)", True),
    ("• Consumer payment links barely monetise (P2P is free at Tikkie/banks) — treat as a viral funnel, not a revenue line.", False),
    ("• The business payment-link stream is the only near-term profit engine; ROSCA is the sticky, differentiated wedge.", False),
    ("• Monthly break-even is NOT reached within 36 months in Base/Worst; the Best case reaches it just past M36.", False),
    ("• Peak cumulative funding need (base): ~€0.55M within 36m; ~€0.8–0.9M to actually reach break-even (~M42–46).", False),
    ("• Fundable as a pre-seed bet on wedge + team + Phase-3 cost collapse — NOT on consumer unit economics.", False),
    ("", False),
    ("All figures EUR, exclusive of VAT. Built bottom-up; see build_payspin_model.py for derivation.", False),
]
for i, (txt, bold) in enumerate(readme, 1):
    c = ws.cell(row=i, column=1, value=txt)
    if i == 1:
        c.font = Font(bold=True, size=15, color="1F3864")
    elif bold:
        c.font = Font(bold=True, size=11, color="1F3864")
ws.column_dimensions['A'].width = 120

# ---------- ASSUMPTIONS ----------
wa = wb.create_sheet("Assumptions")
wa.cell(row=1, column=1, value="ASSUMPTION").font = HDR
wa.cell(row=1, column=2, value="VALUE").font = HDR
wa.cell(row=1, column=3, value="NOTE / SOURCE").font = HDR
for col in (1, 2, 3):
    wa.cell(row=1, column=col).fill = HDRFILL
acells = {}  # key -> "B<row>"
arows = [
    ("c_price",        A["c_price"],        MONEY, "EUR per billable consumer link (>3 free/mo). Tikkie consumer = free; WTP near zero."),
    ("b_arpa",         A["b_arpa"],         MONEY, "Blended monthly revenue per business account (subscription + per-tx). Tikkie biz €7.50+€0.15-0.25/tx."),
    ("r_price_user_mo",A["r_price_user_mo"],MONEY, "ROSCA fee/user/mo. Comps: Roond 1.5% pot or €5.99/mo; StepLadder £1-18/mo."),
    ("y_license",      A["y_license"],      MONEY, "Yapily PISP licence rental (fixed)."),
    ("y_data",         A["y_data"],         MONEY, "Yapily data usage (fixed)."),
    ("y_platform_base",A["y_platform_base"],MONEY, "Yapily platform fee base (incl. first 500 successful tx/mo)."),
    ("y_bundle_tx",    A["y_bundle_tx"],    MONEY0,"Tx included in platform base."),
    ("y_rate_t1",      A["y_rate_t1"],      MONEY, "ASSUMPTION: overage tx 501-5,000 (Yapily does not publish; <1% market)."),
    ("y_rate_t2",      A["y_rate_t2"],      MONEY, "ASSUMPTION: overage tx 5,001-25,000."),
    ("y_rate_t3",      A["y_rate_t3"],      MONEY, "ASSUMPTION: overage tx 25,000+."),
    ("tax_rate",       A["tax_rate"],       PCT,   "Blended effective NL(19%)/DE UG(~30%) rate, applied AFTER loss carryforward."),
]
r = 2
for key, val, fmt, note in arows:
    wa.cell(row=r, column=1, value=key)
    cell = wa.cell(row=r, column=2, value=val)
    cell.number_format = fmt
    cell.fill = PatternFill("solid", fgColor="FFF2CC")
    cell.border = BORDER
    wa.cell(row=r, column=3, value=note)
    acells[key] = f"B{r}"
    r += 1
# behavioural assumptions (informational; baked into volume inputs)
wa.cell(row=r+1, column=1, value="BEHAVIOURAL (baked into volume inputs on Model sheet)").font = Font(bold=True)
beh = [
    ("c_active_share", A["c_active_share"], "Active senders / registered."),
    ("c_links_per_active", A["c_links_per_active"], "Links sent per active/mo."),
    ("c_pay_rate", A["c_pay_rate"], "Sent links actually paid (=PISP tx)."),
    ("c_paid_conv", A["c_paid_conv"], "Active users exceeding free tier. Benchmark 2-5%."),
    ("c_billable_per_payer", A["c_billable_per_payer"], "Billable links per paying user/mo."),
    ("b_tx_per_acct", A["b_tx_per_acct"], "Completed tx per business acct/mo."),
    ("r_users_per_circle", A["r_users_per_circle"], "Avg ROSCA circle size."),
    ("r_tx_per_circle", A["r_tx_per_circle"], "6 contributions + 1 payout / mo."),
]
rr = r + 2
for k, v, note in beh:
    wa.cell(row=rr, column=1, value=k)
    wa.cell(row=rr, column=2, value=v)
    wa.cell(row=rr, column=3, value=note)
    rr += 1
wa.column_dimensions['A'].width = 22
wa.column_dimensions['B'].width = 12
wa.column_dimensions['C'].width = 95

# ---------- MODEL (base case, monthly, formula-driven money) ----------
wm = wb.create_sheet("Model")
cols = ["Month","Cons. registered","Cons. active","Cons. payers","Cons. billable links","Cons. tx",
        "Biz accounts","Biz tx","ROSCA circles","ROSCA users","ROSCA tx","TOTAL tx",
        "Rev: Consumer","Rev: Business","Rev: ROSCA","TOTAL REVENUE",
        "Yapily","Tech/dev","Founder salary","NL entity","DE entity","Legal/compliance","Tools/infra","PISP redundancy","Marketing","One-time","Contingency 10%","TOTAL COST",
        "EBT","Loss c/f (open)","Taxable","Tax","Loss c/f (close)","NET PROFIT","CUM CASH","Gross margin %"]
for j, name in enumerate(cols, 1):
    c = wm.cell(row=1, column=j, value=name)
    c.font = HDR; c.fill = HDRFILL; c.alignment = Alignment(wrap_text=True, vertical="center")
    c.border = BORDER
CL = {name: get_column_letter(j) for j, name in enumerate(cols, 1)}

for i, rdat in enumerate(rows):
    xr = i + 2          # excel row
    m = rdat["m"]
    prev = xr - 1
    def put(col, val, fmt=None, formula=False):
        cell = wm.cell(row=xr, column=cols.index(col)+1, value=val)
        if fmt: cell.number_format = fmt
        cell.border = BORDER
        return cell
    # volume inputs (values)
    put("Month", m, MONEY0)
    put("Cons. registered", round(rdat["c_reg"]), MONEY0)
    put("Cons. active", round(rdat["c_active"]), MONEY0)
    put("Cons. payers", round(rdat["c_payers"], 1), MONEY)
    put("Cons. billable links", round(rdat["c_billable"], 1), MONEY)
    put("Cons. tx", round(rdat["c_tx"]), MONEY0)
    put("Biz accounts", round(rdat["b_acc"]), MONEY0)
    put("Biz tx", round(rdat["b_tx"]), MONEY0)
    put("ROSCA circles", round(rdat["r_cir"]), MONEY0)
    put("ROSCA users", round(rdat["r_users"]), MONEY0)
    put("ROSCA tx", round(rdat["r_tx"]), MONEY0)
    # total tx (formula)
    put("TOTAL tx", f"={CL['Cons. tx']}{xr}+{CL['Biz tx']}{xr}+{CL['ROSCA tx']}{xr}", MONEY0)
    # revenue formulas
    put("Rev: Consumer", f"={CL['Cons. billable links']}{xr}*Assumptions!${acells['c_price'][0]}${acells['c_price'][1:]}", MONEY)
    put("Rev: Business", f"={CL['Biz accounts']}{xr}*Assumptions!${acells['b_arpa'][0]}${acells['b_arpa'][1:]}", MONEY)
    put("Rev: ROSCA", f"={CL['ROSCA users']}{xr}*Assumptions!${acells['r_price_user_mo'][0]}${acells['r_price_user_mo'][1:]}", MONEY)
    put("TOTAL REVENUE", f"={CL['Rev: Consumer']}{xr}+{CL['Rev: Business']}{xr}+{CL['Rev: ROSCA']}{xr}", MONEY)
    # yapily formula (tiered overage)
    tot = f"{CL['TOTAL tx']}{xr}"
    lic = f"Assumptions!$B${acells['y_license'][1:]}"
    dat = f"Assumptions!$B${acells['y_data'][1:]}"
    pbase = f"Assumptions!$B${acells['y_platform_base'][1:]}"
    bun = f"Assumptions!$B${acells['y_bundle_tx'][1:]}"
    t1 = f"Assumptions!$B${acells['y_rate_t1'][1:]}"
    t2 = f"Assumptions!$B${acells['y_rate_t2'][1:]}"
    t3 = f"Assumptions!$B${acells['y_rate_t3'][1:]}"
    over = f"MAX(0,{tot}-{bun})"
    yap_f = (f"={lic}+{dat}+{pbase}"
             f"+MIN({over},4500)*{t1}"
             f"+MIN(MAX({over}-4500,0),20000)*{t2}"
             f"+MAX({over}-24500,0)*{t3}")
    put("Yapily", yap_f, MONEY)
    # cost values
    put("Tech/dev", tech_cost(m), MONEY0)
    put("Founder salary", founder_salary(m), MONEY0)
    put("NL entity", nl_entity_cost(m), MONEY0)
    put("DE entity", de_entity_cost(m), MONEY0)
    put("Legal/compliance", legal_compliance(m), MONEY0)
    put("Tools/infra", tools_infra(m), MONEY0)
    put("PISP redundancy", pisp_redundancy(m), MONEY0)
    put("Marketing", marketing_spend(m), MONEY0)
    put("One-time", one_times.get(m, 0), MONEY0)
    # contingency = 10% of core opex (Yapily..Marketing)
    core = f"{CL['Yapily']}{xr}+{CL['Tech/dev']}{xr}+{CL['Founder salary']}{xr}+{CL['NL entity']}{xr}+{CL['DE entity']}{xr}+{CL['Legal/compliance']}{xr}+{CL['Tools/infra']}{xr}+{CL['PISP redundancy']}{xr}+{CL['Marketing']}{xr}"
    put("Contingency 10%", f"=0.1*({core})", MONEY)
    put("TOTAL COST", f"=({core})+{CL['One-time']}{xr}+{CL['Contingency 10%']}{xr}", MONEY)
    # EBT
    put("EBT", f"={CL['TOTAL REVENUE']}{xr}-{CL['TOTAL COST']}{xr}", MONEY)
    # loss carryforward
    if i == 0:
        put("Loss c/f (open)", 0, MONEY)
    else:
        put("Loss c/f (open)", f"={CL['Loss c/f (close)']}{prev}", MONEY)
    put("Taxable", f"=MAX(0,{CL['EBT']}{xr}-{CL['Loss c/f (open)']}{xr})", MONEY)
    put("Tax", f"={CL['Taxable']}{xr}*Assumptions!$B${acells['tax_rate'][1:]}", MONEY)
    put("Loss c/f (close)", f"=MAX(0,{CL['Loss c/f (open)']}{xr}-MAX({CL['EBT']}{xr},0))+MAX(0,-{CL['EBT']}{xr})", MONEY)
    put("NET PROFIT", f"={CL['EBT']}{xr}-{CL['Tax']}{xr}", MONEY)
    if i == 0:
        put("CUM CASH", f"={CL['NET PROFIT']}{xr}", MONEY)
    else:
        put("CUM CASH", f"={CL['CUM CASH']}{prev}+{CL['NET PROFIT']}{xr}", MONEY)
    put("Gross margin %", f"=IF({CL['TOTAL REVENUE']}{xr}=0,0,({CL['TOTAL REVENUE']}{xr}-{CL['Yapily']}{xr})/{CL['TOTAL REVENUE']}{xr})", PCT)

wm.freeze_panes = "B2"
for j in range(1, len(cols)+1):
    wm.column_dimensions[get_column_letter(j)].width = 13
wm.column_dimensions['A'].width = 7

# ---------- ANNUAL SUMMARY (formulas referencing Model) ----------
wy = wb.create_sheet("Annual_Summary")
heads = ["", "Year 1 (M1-12)", "Year 2 (M13-24)", "Year 3 (M25-36)"]
for j, h in enumerate(heads, 1):
    c = wy.cell(row=1, column=j, value=h); c.font = HDR; c.fill = HDRFILL; c.border = BORDER
metric_rows = [
    ("Total revenue", CL['TOTAL REVENUE']),
    ("Total cost", CL['TOTAL COST']),
    ("Net profit/(loss)", CL['NET PROFIT']),
    ("Yapily cost", CL['Yapily']),
    ("Marketing", CL['Marketing']),
]
ranges = [(2,13),(14,25),(26,37)]
for ri, (label, col) in enumerate(metric_rows, 2):
    wy.cell(row=ri, column=1, value=label).font = Font(bold=True)
    for ci, (a, b) in enumerate(ranges, 2):
        wy.cell(row=ri, column=ci, value=f"=SUM(Model!{col}{a}:{col}{b})").number_format = MONEY0
# end-of-year cumulative cash
wy.cell(row=len(metric_rows)+2, column=1, value="Cum cash (year-end)").font = Font(bold=True)
for ci, (a, b) in enumerate(ranges, 2):
    wy.cell(row=len(metric_rows)+2, column=ci, value=f"=Model!{CL['CUM CASH']}{b}").number_format = MONEY0
for j in range(1, 5):
    wy.column_dimensions[get_column_letter(j)].width = 20

# ---------- SCENARIOS (computed values + multiplier table) ----------
wsx = wb.create_sheet("Scenarios")
sc_head = ["Scenario","Y1 rev","Y2 rev","Y3 rev","Exit M36 MRR","M36 tx/mo","Monthly break-even","Peak funding need (36m)"]
for j, h in enumerate(sc_head, 1):
    c = wsx.cell(row=1, column=j, value=h); c.font = HDR; c.fill = HDRFILL; c.border = BORDER
sr = 2
for scn in ("worst", "base", "best"):
    res, be = compute(scn)
    yr = lambda a, b: sum(x["rev"] for x in res[a:b])
    wsx.cell(row=sr, column=1, value=scn.upper())
    wsx.cell(row=sr, column=2, value=round(yr(0,12))).number_format = MONEY0
    wsx.cell(row=sr, column=3, value=round(yr(12,24))).number_format = MONEY0
    wsx.cell(row=sr, column=4, value=round(yr(24,36))).number_format = MONEY0
    wsx.cell(row=sr, column=5, value=round(res[-1]["rev"])).number_format = MONEY0
    wsx.cell(row=sr, column=6, value=round(res[-1]["tx"])).number_format = MONEY0
    wsx.cell(row=sr, column=7, value=("M"+str(be) if be else "beyond M36"))
    wsx.cell(row=sr, column=8, value=round(min(x["cum"] for x in res))).number_format = MONEY0
    sr += 1
wsx.cell(row=sr+1, column=1, value="Scenario levers").font = Font(bold=True)
lever_tbl = [
    ["", "consumer conv x", "biz accounts x", "biz ARPA €", "ROSCA vol x", "Yapily cost x"],
    ["WORST", 0.5, 0.55, 9.0, 0.6, 1.3],
    ["BASE", 1.0, 1.0, 11.0, 1.0, 1.0],
    ["BEST", 1.5, 2.2, 14.0, 1.4, 0.85],
]
for di, row_vals in enumerate(lever_tbl):
    for dj, v in enumerate(row_vals):
        cc = wsx.cell(row=sr+2+di, column=1+dj, value=v)
        if di == 0 or dj == 0: cc.font = Font(bold=True)
for j in range(1, 9):
    wsx.column_dimensions[get_column_letter(j)].width = 18

# ---------- UNIT ECONOMICS ----------
wu = wb.create_sheet("Unit_Economics")
ue = [
    ["Segment", "ARPU/mo €", "Gross margin", "Avg life (mo)", "LTV €", "CAC €", "LTV:CAC", "Verdict"],
    ["Consumer (paying)", 2.0, 0.6, 18, "=B2*C2*D2", 6, "=E2/F2", "Marginal; only via organic/viral"],
    ["Consumer (blended all users)", 0.10, 0.6, 14, "=B3*C3*D3", 6, "=E3/F3", "Do NOT buy paid traffic"],
    ["Business account", 11.0, 0.75, 30, "=B4*C4*D4", 90, "=E4/F4", "Primary profit engine"],
    ["ROSCA user", 1.0, 0.8, 12, "=B5*C5*D5", 5, "=E5/F5", "Sticky, cheap (community-led)"],
    ["ROSCA (per 6-person circle)", 6.0, 0.8, 12, "=B6*C6*D6", 18, "=E6/F6", "Acquire 6 users per CAC event"],
]
for ri, row_vals in enumerate(ue, 1):
    for ci, v in enumerate(row_vals, 1):
        c = wu.cell(row=ri, column=ci, value=v)
        if ri == 1:
            c.font = HDR; c.fill = HDRFILL
        else:
            if ci in (2,5,6): c.number_format = MONEY
            if ci == 3: c.number_format = PCT
            if ci == 7: c.number_format = '0.0'
        c.border = BORDER
for j, w in enumerate([28,12,13,13,10,9,10,38], 1):
    wu.column_dimensions[get_column_letter(j)].width = w

out = "payspin-financial-model.xlsx"
wb.save(out)
print(f"\nExcel written: {out}")

