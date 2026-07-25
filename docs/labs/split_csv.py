"""분석기법 14종별 CSV 분리 + 코드북 생성"""
import pandas as pd, numpy as np, os
D = "/home/claude/kit/data"
M = pd.read_pickle("/home/claude/kit/_master_raw.pkl")
C = pd.read_pickle("/home/claude/kit/_master_clean.pkl")
meta = pd.read_csv(f"{D}/00_codebook_items.csv")

def W(df, name):
    df.to_csv(f"{D}/{name}", index=False, encoding="utf-8-sig")
    print(f"  {name:44s} {df.shape[0]:>4d} × {df.shape[1]:>3d}")

DEMO = ["rid","org_id","sex","age","edu","marital","tenure_yr","career_yr",
        "n_prev_job","n_try_move","rank","firm_size","emp_type","job_fn","wage_10k"]
def it(con, fac=None):
    q = meta[meta.construct == con]
    if fac: q = q[q.facet == fac]
    return list(q.item)

print("── 마스터 ──")
W(M, "00_master_wide_RAW.csv")
W(C.drop(columns=["lpa_class_true"]), "00_master_wide_CLEAN.csv")

# ── 01 단순·다중 회귀 ───────────────────────────────────────────
W(C[DEMO + ["PA_TOT","SC_TOT","PC_TOT","CM_TOT","LS_TOT","WE_TOT","JP_TOT"]],
  "01_regression.csv")

# ── 02 위계적 회귀 : 통제 → 개인특성 → 조직맥락 ────────────────
W(C[DEMO + ["PA_TOT","SC_TOT","PC_TOT","LS_TOT","WE_TOT","JP_TOT"]],
  "02_hierarchical_regression.csv")

# ── 03 매개 (X=SC → M=PC → Y=WE) ───────────────────────────────
W(C[["rid","sex","age","tenure_yr","SC_TOT","PC_TOT","WE_TOT","JP_TOT"]],
  "03_mediation.csv")

# ── 04 조절 (X=SC, W=LS → Y=TI) ────────────────────────────────
W(C[["rid","org_id","sex","age","tenure_yr","SC_TOT","LS_TOT","TI_TOT","WE_TOT"]],
  "04_moderation.csv")

# ── 05 조절된 매개 / 매개된 조절 / 조절된 조절 ─────────────────
W(C[["rid","sex","age","tenure_yr","career_yr",
     "SC_TOT","PC_TOT","LS_TOT","PA_TOT","TI_TOT","WE_TOT"]],
  "05_conditional_process.csv")

# ── 06 이중(직렬) 매개 SC → PC → CM → JP ───────────────────────
W(C[["rid","sex","age","tenure_yr","SC_TOT","PC_TOT","CM_TOT","JP_TOT","PA_TOT"]],
  "06_serial_mediation.csv")

# ── 07 로지스틱 (Y = 12개월 내 이직 여부) ──────────────────────
lg = C[DEMO + ["SC_TOT","PC_TOT","WE_TOT","TI_TOT","LS_TOT","left_12m"]].copy()
W(lg.dropna(subset=["left_12m"]), "07_logistic.csv")

# ── 08 잠재프로파일 (자기자비 6하위요인) ───────────────────────
lpa = C[["rid","org_id","sex","age","edu","tenure_yr","rank","firm_size",
         "SK_m","SJ_m","CH_m","IS_m","MI_m","OI_m",
         "PC_TOT","WE_TOT","TI_TOT","JP_TOT","left_12m"]].copy()
lpa.columns = [c.replace("_m","_facet") if c.endswith("_m") else c for c in lpa.columns]
W(lpa, "08_latent_profile.csv")

# ── 09 생존분석 ────────────────────────────────────────────────
sv = C[["rid","org_id","sex","age","edu","tenure_yr","career_yr","n_prev_job",
        "rank","firm_size","emp_type","wage_10k",
        "SC_TOT","WE_TOT","TI_TOT","LS_TOT","time_months","event"]].copy()
W(sv.dropna(subset=["time_months"]), "09_survival.csv")

# ── 10 자기회귀교차지연 (3파 문항꾸러미, 와이드) ───────────────
wv = [c for c in C.columns if c.startswith(("W1_","W2_","W3_"))]
W(C[["rid","org_id","sex","age","tenure_yr"] + wv], "10_arcl_clpm.csv")

# ── 11 다층분석 (개인 + 조직 수준) ─────────────────────────────
hl = C[["rid","org_id","sex","age","tenure_yr","career_yr","rank",
        "SC_TOT","PC_TOT","WE_TOT","LS_TOT","TI_TOT","JP_TOT",
        "org_size","org_industry"]].copy()
agg = hl.groupby("org_id").agg(org_n=("rid","count"),
                               LS_org_mean=("LS_TOT","mean"),
                               LS_org_sd=("LS_TOT","std")).reset_index()
hl = hl.merge(agg, on="org_id", how="left")
W(hl, "11_multilevel_hlm.csv")
W(agg, "11b_level2_org.csv")

# ── 12 CB-SEM (문항 수준, 2차요인 3구인) ───────────────────────
cb = C[["rid","org_id","sex","age","tenure_yr"] +
       it("SC") + it("PC") + it("WE") + it("TI")]
W(cb, "12_cbsem_items.csv")

# ── 13 PLS-SEM (경로 중심, 반영적 2차요인) ─────────────────────
pl = C[["rid","sex","age","tenure_yr"] +
       it("PA") + it("SC") + it("PC") + it("CM") + it("JP")]
W(pl, "13_plssem_items.csv")

# ── 14 MSEM · 종단 SEM · DSEM ──────────────────────────────────
ms = C[["rid","org_id","sex","age","tenure_yr","LS_TOT","org_size"] + wv]
W(ms, "14_msem_longitudinal.csv")
# 롱폼(DSEM·성장모형용)
rows = []
for w in (1,2,3):
    r = C[["rid","org_id","sex","age","tenure_yr","LS_TOT"]].copy()
    r["wave"] = w; r["time"] = w - 1
    for nm in ("SC","WE","TI"):
        cols = [f"W{w}_{nm}_p{j}" for j in (1,2,3)]
        r[nm] = C[cols].mean(axis=1)
        for j in (1,2,3): r[f"{nm}_p{j}"] = C[f"W{w}_{nm}_p{j}"]
    rows.append(r)
W(pd.concat(rows).sort_values(["rid","wave"]), "14b_longitudinal_LONG.csv")

# ── 변수 코드북 ────────────────────────────────────────────────
CB = [
 ("rid","응답자 ID","문자","—"),
 ("org_id","조직(팀) ID · Level-2 군집","문자","46개 조직"),
 ("flag","불성실 응답 플래그","0/2/3/4","0=정상, 2=직선반응, 3=패턴응답, 4=시간미달"),
 ("flag_reason","불성실 사유","문자","—"),
 ("resp_sec","응답 소요시간(초)","연속","속도위반 탐지용"),
 ("sex","성별","1/2","1=남, 2=여"),
 ("age","연령(만)","연속","20~44"),
 ("edu","최종학력","1~5","1=고졸이하 … 5=박사"),
 ("marital","혼인상태","1~3","1=미혼, 2=기혼, 3=기타"),
 ("tenure_yr","현 직장 재직기간(년)","연속","우편포 skew≈1.2"),
 ("career_yr","총 경력기간(년)","연속","—"),
 ("n_prev_job","이직 횟수","계수","—"),
 ("n_try_move","이직 시도 횟수","계수","극단치 포함 · 결측 3%"),
 ("rank","직급","1~6","1=사원 … 6=임원"),
 ("firm_size","기업규모","1~3","1=중소, 2=중견, 3=대기업"),
 ("emp_type","고용형태","1/2","1=정규직, 2=비정규직"),
 ("job_fn","담당직무","1~10","—"),
 ("wage_10k","월평균 임금(만원)","연속","극단치 포함 · 결측 6%"),
 ("org_size","조직 규모(명)","연속","Level-2"),
 ("org_industry","조직 업종","1~5","Level-2"),
 ("SC_*","자기자비 문항 (2차요인 · 하위 6)","1~5","SK 자기친절 / SJ 자기비난R / CH 보편적인간성 / IS 고립R / MI 마음챙김 / OI 과잉동일시R"),
 ("PC_*","긍정심리자본 문항 (2차요인 · 하위 4)","1~5","EF 자기효능 / HO 희망 / RE 회복탄력 / OP 낙관"),
 ("CM_*","경력관리행동 문항 (2차요인 · 하위 4)","1~5","CE 경력탐색 / NW 네트워킹 / SP 자기제시 / MB 이동준비"),
 ("WE_*","직무열의 문항 (2차요인 · 하위 3)","1~5","VI 활력 / DE 헌신 / AB 몰두"),
 ("PA_*","주도적 성격 문항 (단일요인 8)","1~5","—"),
 ("LS_*","학습지원문화 문항 (Level-2 합산 대상 5)","1~5","r_wg · ICC(2) 산출용"),
 ("TI_*","이직의도 문항 (3)","1~5","—"),
 ("JP_*","직무성과 문항 (4)","1~5","—"),
 ("EX_*","정서적 소진 문항 (4)","1~5","의도적 저신뢰도 척도 (α≈.5대)"),
 ("*_m","하위요인 평균 (역채점 반영)","연속","—"),
 ("*_TOT","구인 총점 평균 (역채점 반영)","연속","—"),
 ("W{1,2,3}_{SC,WE,TI}_p{1,2,3}","3파 문항꾸러미","1~5","W2 이탈 12%, W3 이탈 22%"),
 ("left_12m","12개월 내 실제 이직 여부","0/1","로지스틱 종속"),
 ("time_months","이직까지 개월수","연속","생존분석"),
 ("event","사건 발생(1) / 중도절단(0)","0/1","생존분석"),
]
W(pd.DataFrame(CB, columns=["변수","설명","척도","비고"]), "00_codebook_variables.csv")
print("\n총 CSV:", len([f for f in os.listdir(D) if f.endswith('.csv')]))
