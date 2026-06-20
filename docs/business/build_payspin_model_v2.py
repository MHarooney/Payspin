"""
Payspin financial model v2 -- VOLUME-DRIVEN, with corrected Yapily pricing.

Corrections vs v1 (per founder):
  * Yapily: EUR 1,100/mo fixed (license 500 + data 300 + platform 300) INCLUDES
    up to 3,000 successful transactions/month. ABOVE 3,000 tx/mo: EUR 0.30 per tx.
    License + data remain fixed regardless of volume.
  * Drive the model from TRANSACTION TARGETS: ~100k tx in Y1, ~200k in Y2,
    ~350k in Y3 (Y3 = ASSUMPTION; founder gave Y1/Y2).

Produces two configurations to answer "is this realistic / how to achieve it":
  CONFIG A "as-targeted"  : current pricing + EUR 0.30 Yapily (the trap).
  CONFIG B "viable"       : Yapily renegotiated to EUR 0.10/tx at volume,
                            business repriced to EUR 0.40/tx effective,
                            free-consumer share capped lower, ROSCA on Phase-3
                            (near-zero marginal cost) from M18.
"""
import math
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

N = 36
MONEY = '#,##0.00'; MONEY0 = '#,##0'; PCT = '0.0%'

# ---- monthly transaction ramp, scaled to hit annual targets ----
def shape(m):
    return 1.0 / (1.0 + math.exp(-0.16 * (m - 22)))   # smooth S-curve 0..1

raw = [shape(m) for m in range(1, N + 1)]
targets = {1: 100_000, 2: 200_000, 3: 350_000}
monthly_tx = [0.0] * N
for y, (a, b) in enumerate([(0, 12), (12, 24), (24, 36)], 1):
    s = sum(raw[a:b])
    factor = targets[y] / s
    for i in range(a, b):
        monthly_tx[i] = raw[i] * factor

# ---- transaction MIX shares by year (ASSUMPTION), interpolated monthly ----
mix_by_year = {
    # consumer_free, consumer_billable, business, rosca
    1: (0.62, 0.03, 0.23, 0.12),
    2: (0.55, 0.035, 0.28, 0.135),
    3: (0.50, 0.04, 0.32, 0.14),
}
def mix_for_month(m):
    y = 1 if m <= 12 else 2 if m <= 24 else 3
    return mix_by_year[y]

# ---- pricing / yield ----
P = {
    "c_bill_price": 0.50,      # EUR per billable consumer link
    "rosca_user_mo": 1.50,     # EUR/user/month
    "rosca_tx_per_user_mo": 7.0 / 6.0,  # 7 tx per 6-person circle / month
}

# ---- cost stack (reuse v1 staffing plan; marketing scaled UP for volume push) ----
def tech(m):   return 300 if m<=6 else 1500 if m<=12 else 4000 if m<=18 else 8000 if m<=24 else 9000
def fnd(m):    return 0 if m<=12 else 1500 if m<=24 else 3000
def nlent(m):  return 450
def deent(m):  return 300 if m>=7 else 0
def legal(m):  return 150
def tools(m):  return 300 if m<=6 else 600 if m<=18 else 1000
def redun(m):  return 350 if m>=13 else 0
def mkt(m):    return 2000 if m<=3 else 5000 if m<=6 else 10000 if m<=12 else 18000 if m<=24 else 25000
one_times = {1: 1200+3000, 7: 1000, 9: 3000}

def yapily(tx, rate=0.30, included=3000):
    return 1100 + rate * max(0.0, tx - included)

def run(config="A"):
    if config == "A":
        yap_rate = 0.30
        biz_yield = 0.22          # blended per-tx under "beat-Tikkie" pricing
        free_cap = None
        phase3_from = None
        phase3_rosca_rate = None
    else:  # B viable
        yap_rate = 0.10           # renegotiated at volume
        biz_yield = 0.40          # repriced: per-tx + subscription, yield > cost
        free_cap = 0.40           # cap free-consumer share of mix
        phase3_from = 18          # ROSCA moves off PISP rail
        phase3_rosca_rate = 0.02

    out = []
    cum = 0.0
    for i in range(N):
        m = i + 1
        tx = monthly_tx[i]
        cf, cb, bz, rs = mix_for_month(m)
        if free_cap is not None and cf > free_cap:
            # reallocate excess free-consumer share to business (monetised)
            excess = cf - free_cap; cf = free_cap; bz += excess
        tx_cf = tx * cf
        tx_cb = tx * cb
        tx_bz = tx * bz
        tx_rs = tx * rs

        rev_cf = 0.0
        rev_cb = tx_cb * P["c_bill_price"]
        rev_bz = tx_bz * biz_yield
        rosca_users = tx_rs / P["rosca_tx_per_user_mo"]
        rev_rs = rosca_users * P["rosca_user_mo"]
        revenue = rev_cf + rev_cb + rev_bz + rev_rs

        # Yapily: ROSCA tx move to Phase-3 rate from phase3_from (config B)
        if config == "B" and phase3_from and m >= phase3_from:
            pisp_tx = tx - tx_rs
            yap = yapily(pisp_tx, rate=yap_rate) + phase3_rosca_rate * tx_rs
        else:
            yap = yapily(tx, rate=yap_rate)

        core = (yap + tech(m) + fnd(m) + nlent(m) + deent(m) + legal(m) +
                tools(m) + redun(m) + mkt(m))
        cost = core * 1.10 + one_times.get(m, 0)
        ebt = revenue - cost
        cum += ebt
        gm = (revenue - yap) / revenue if revenue else 0
        out.append(dict(m=m, tx=tx, rev=revenue, rev_bz=rev_bz, rev_rs=rev_rs, rev_cb=rev_cb,
                        yap=yap, cost=cost, ebt=ebt, cum=cum, gm=gm,
                        tx_cf=tx_cf, tx_cb=tx_cb, tx_bz=tx_bz, tx_rs=tx_rs, rosca_users=rosca_users))
    return out

results = {}
for cfg in ("A", "B"):
    r = run(cfg)
    results[cfg] = r
    yr = lambda f, a, b: sum(x[f] for x in r[a:b])
    print(f"\n===== CONFIG {cfg} {'(as-targeted, EUR0.30 rail)' if cfg=='A' else '(viable: renegotiated rail + repriced + Phase-3)'} =====")
    for y, (a, b) in enumerate([(0,12),(12,24),(24,36)], 1):
        print(f" Y{y}: tx {yr('tx',a,b):,.0f} | revenue EUR {yr('rev',a,b):,.0f} | Yapily EUR {yr('yap',a,b):,.0f} "
              f"| gross margin {(yr('rev',a,b)-yr('yap',a,b))/max(yr('rev',a,b),1)*100:5.1f}% | net EUR {yr('ebt',a,b):,.0f}")
    print(f" Exit-M36 MRR EUR {r[-1]['rev']:,.0f} | M36 tx {r[-1]['tx']:,.0f} | M36 Yapily EUR {r[-1]['yap']:,.0f}")
    print(f" 3y revenue EUR {yr('rev',0,36):,.0f} | 3y Yapily EUR {yr('yap',0,36):,.0f} | peak cum cash EUR {min(x['cum'] for x in r):,.0f}")

# ============================== EXCEL ==============================
HDR = Font(bold=True, color="FFFFFF"); HDRFILL = PatternFill("solid", fgColor="1F3864")
YEL = PatternFill("solid", fgColor="FFF2CC"); thin = Side(style="thin", color="BBBBBB")
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)
wb = Workbook()

# README
ws = wb.active; ws.title = "README"
lines = [
 ("PAYSPIN FINANCIAL MODEL v2 - VOLUME-DRIVEN, CORRECTED YAPILY PRICING", 15),
 ("", 0),
 ("Yapily: EUR 1,100/mo fixed (license 500 + data 300 + platform 300) incl. up to 3,000 tx/mo;", 0),
 ("EUR 0.30 per transaction above 3,000/mo. License + data stay fixed at any volume.", 0),
 ("Driven by founder transaction targets: ~100k tx (Y1), ~200k (Y2), ~350k (Y3, assumption).", 0),
 ("", 0),
 ("CONFIG A = your targets on the EUR 0.30 rail. Gross margin is NEGATIVE: the rail costs more", 0),
 ("than total revenue. Growing volume loses money faster. <-- the key warning.", 0),
 ("CONFIG B = the fix: Yapily renegotiated to EUR 0.10/tx at volume, business repriced to", 0),
 ("EUR 0.40/tx yield, free-consumer share capped at 40%, ROSCA moved to Phase-3 (near-zero) from M18.", 0),
 ("", 0),
 ("Edit the yellow Assumptions cells to flex rail rate, business yield, prices, Phase-3 rate.", 0),
 ("Money columns on the Config sheets are LIVE FORMULAS; tx volumes & mix are inputs.", 0),
]
for i,(t,sz) in enumerate(lines,1):
    c = ws.cell(row=i, column=1, value=t)
    if sz: c.font = Font(bold=True, size=sz, color="1F3864")
ws.column_dimensions['A'].width = 110

# Assumptions
wa = wb.create_sheet("Assumptions")
for j,h in enumerate(["Assumption","Value","Note"],1):
    c=wa.cell(row=1,column=j,value=h); c.font=HDR; c.fill=HDRFILL
arows = [
 ("yapily_included", 3000, MONEY0, "Tx included in EUR 1,100/mo fixed bundle"),
 ("yapily_rate_A",   0.30, MONEY,  "Per-tx cost above bundle (current deal)"),
 ("yapily_rate_B",   0.10, MONEY,  "Renegotiated per-tx at volume (target)"),
 ("c_bill_price",    0.50, MONEY,  "EUR per billable consumer link"),
 ("biz_yield_A",     0.22, MONEY,  "Business revenue/tx, 'beat-Tikkie' pricing"),
 ("biz_yield_B",     0.40, MONEY,  "Business revenue/tx repriced (sub + per-tx)"),
 ("rosca_user_mo",   1.50, MONEY,  "ROSCA fee per user / month"),
 ("rosca_tx_per_user",1.1667,MONEY,"ROSCA tx per user / month (7 per 6-person circle)"),
 ("phase3_rosca_rate",0.02,MONEY,  "Marginal cost/tx for ROSCA on Phase-3 rail"),
]
acell = {}
for i,(k,v,fmt,note) in enumerate(arows, 2):
    wa.cell(row=i,column=1,value=k)
    c=wa.cell(row=i,column=2,value=v); c.number_format=fmt; c.fill=YEL; c.border=BORDER
    wa.cell(row=i,column=3,value=note); acell[k]=f"B{i}"
wa.column_dimensions['A'].width=20; wa.column_dimensions['B'].width=10; wa.column_dimensions['C'].width=60

def config_sheet(name, data, cfg):
    s = wb.create_sheet(name)
    cols=["Month","Total tx","tx Consumer-free","tx Consumer-billable","tx Business","tx ROSCA",
          "ROSCA users","Rev Consumer","Rev Business","Rev ROSCA","TOTAL REVENUE","Yapily",
          "Other opex","Contingency 10%","One-time","TOTAL COST","EBT","CUM CASH","Gross margin %"]
    for j,h in enumerate(cols,1):
        c=s.cell(row=1,column=j,value=h); c.font=HDR; c.fill=HDRFILL; c.alignment=Alignment(wrap_text=True); c.border=BORDER
    L={h:get_column_letter(j) for j,h in enumerate(cols,1)}
    rate = acell['yapily_rate_A'] if cfg=="A" else acell['yapily_rate_B']
    yld  = acell['biz_yield_A'] if cfg=="A" else acell['biz_yield_B']
    for i,d in enumerate(data):
        xr=i+2; m=d['m']; prev=xr-1
        def put(col,val,fmt=None):
            c=s.cell(row=xr,column=cols.index(col)+1,value=val)
            if fmt:c.number_format=fmt
            c.border=BORDER; return c
        put("Month",m,MONEY0)
        put("Total tx",round(d['tx']),MONEY0)
        put("tx Consumer-free",round(d['tx_cf']),MONEY0)
        put("tx Consumer-billable",round(d['tx_cb']),MONEY0)
        put("tx Business",round(d['tx_bz']),MONEY0)
        put("tx ROSCA",round(d['tx_rs']),MONEY0)
        put("ROSCA users",f"={L['tx ROSCA']}{xr}/Assumptions!${acell['rosca_tx_per_user'][0]}${acell['rosca_tx_per_user'][1:]}",MONEY0)
        put("Rev Consumer",f"={L['tx Consumer-billable']}{xr}*Assumptions!$B${acell['c_bill_price'][1:]}",MONEY)
        put("Rev Business",f"={L['tx Business']}{xr}*Assumptions!$B${yld[1:]}",MONEY)
        put("Rev ROSCA",f"={L['ROSCA users']}{xr}*Assumptions!$B${acell['rosca_user_mo'][1:]}",MONEY)
        put("TOTAL REVENUE",f"={L['Rev Consumer']}{xr}+{L['Rev Business']}{xr}+{L['Rev ROSCA']}{xr}",MONEY)
        inc=f"Assumptions!$B${acell['yapily_included'][1:]}"; rt=f"Assumptions!$B${rate[1:]}"
        if cfg=="B" and m>=18:
            p3=f"Assumptions!$B${acell['phase3_rosca_rate'][1:]}"
            yf=f"=1100+{rt}*MAX(0,({L['Total tx']}{xr}-{L['tx ROSCA']}{xr})-{inc})+{p3}*{L['tx ROSCA']}{xr}"
        else:
            yf=f"=1100+{rt}*MAX(0,{L['Total tx']}{xr}-{inc})"
        put("Yapily",yf,MONEY)
        put("Other opex",round(tech(m)+fnd(m)+nlent(m)+deent(m)+legal(m)+tools(m)+redun(m)+mkt(m)),MONEY0)
        put("Contingency 10%",f"=0.1*({L['Yapily']}{xr}+{L['Other opex']}{xr})",MONEY)
        put("One-time",one_times.get(m,0),MONEY0)
        put("TOTAL COST",f"={L['Yapily']}{xr}+{L['Other opex']}{xr}+{L['Contingency 10%']}{xr}+{L['One-time']}{xr}",MONEY)
        put("EBT",f"={L['TOTAL REVENUE']}{xr}-{L['TOTAL COST']}{xr}",MONEY)
        put("CUM CASH",(f"={L['EBT']}{xr}" if i==0 else f"={L['CUM CASH']}{prev}+{L['EBT']}{xr}"),MONEY)
        put("Gross margin %",f"=IF({L['TOTAL REVENUE']}{xr}=0,0,({L['TOTAL REVENUE']}{xr}-{L['Yapily']}{xr})/{L['TOTAL REVENUE']}{xr})",PCT)
    s.freeze_panes="B2"
    for j in range(1,len(cols)+1): s.column_dimensions[get_column_letter(j)].width=13
    s.column_dimensions['A'].width=7

config_sheet("Config_A_targets", results["A"], "A")
config_sheet("Config_B_viable", results["B"], "B")

# Comparison
wc = wb.create_sheet("Comparison")
wc.cell(row=1,column=1,value="Metric (3-year)").font=Font(bold=True)
wc.cell(row=1,column=2,value="Config A (EUR0.30 rail)").font=Font(bold=True)
wc.cell(row=1,column=3,value="Config B (viable)").font=Font(bold=True)
def tot(r,f): return sum(x[f] for x in r)
rows_cmp=[("Transactions",tot(results['A'],'tx'),tot(results['B'],'tx')),
 ("Revenue",tot(results['A'],'rev'),tot(results['B'],'rev')),
 ("Yapily cost",tot(results['A'],'yap'),tot(results['B'],'yap')),
 ("Gross profit (rev - Yapily)",tot(results['A'],'rev')-tot(results['A'],'yap'),tot(results['B'],'rev')-tot(results['B'],'yap')),
 ("Net (EBT)",tot(results['A'],'ebt'),tot(results['B'],'ebt')),
 ("Peak cash need",min(x['cum'] for x in results['A']),min(x['cum'] for x in results['B']))]
for i,(lab,a,b) in enumerate(rows_cmp,2):
    wc.cell(row=i,column=1,value=lab)
    wc.cell(row=i,column=2,value=round(a)).number_format=MONEY0
    wc.cell(row=i,column=3,value=round(b)).number_format=MONEY0
for j,w in enumerate([28,22,22],1): wc.column_dimensions[get_column_letter(j)].width=w

wb.save("payspin-financial-model-v2.xlsx")
print("\nExcel written: payspin-financial-model-v2.xlsx")
