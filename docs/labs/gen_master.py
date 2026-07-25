"""
==========================================================================
 통계지표 계보도 · 실습 데이터 생성기
 Empirical parameters extracted from three real Korean survey datasets:
   (1) KIRD_learning_340 (SPSS)  : k=101 items, M=3.005, SD=.843, skew=-.41
   (2) 이재은님_B조사_Raw (N=359) : M=3.230, SD=.911, skew=-.12, kurt=-.21
                                    IRV<.50 = 8.6%, bad-sample 29/388 = 7.5%
                                    임금 skew=5.63, 이직시도 skew=5.47
   (3) 측정도구 구인표            : 자기자비 26 / 긍정심리자본 24 /
                                    경력관리행동 20 / 주도적성격 10 문항
==========================================================================
"""
import numpy as np, pandas as pd

RNG = np.random.default_rng(20260724)
N_RAW = 468          # 수집 표본
N_ORG = 46           # 조직(팀) 수  → 다층분석용
LIK_MIN, LIK_MAX = 1, 5

# ─────────────────────────────────────────────────────────────────
# 0. 측정모형 청사진 : (구인, 2차요인 여부, {하위요인: (문항수, 역문항 idx)})
# ─────────────────────────────────────────────────────────────────
BLUEPRINT = {
    "SC": {  # 자기자비 — 2차요인 6개 하위요인
        "label": "자기자비", "second_order": True,
        "facets": {"SK": (4, [], False), "SJ": (4, [], True), "CH": (4, [], False),
                   "IS": (4, [], True), "MI": (4, [], False), "OI": (4, [], True)},
        "facet_load": {"SK":.82, "SJ":-.71, "CH":.78, "IS":-.68, "MI":.80, "OI":-.66},
    },
    "PC": {  # 긍정심리자본 — 2차요인 4개 하위요인
        "label": "긍정심리자본", "second_order": True,
        "facets": {"EF": (5, [], False), "HO": (5, [], False),
                   "RE": (5, [4], False), "OP": (5, [], False)},
        "facet_load": {"EF":.84, "HO":.86, "RE":.79, "OP":.75},
    },
    "CM": {  # 경력관리행동 — 2차요인 4개 하위요인
        "label": "경력관리행동", "second_order": True,
        "facets": {"CE": (4, [], False), "NW": (4, [], False),
                   "SP": (4, [], False), "MB": (4, [], False)},
        "facet_load": {"CE":.77, "NW":.72, "SP":.69, "MB":.74},
    },
    "WE": {  # 직무열의 — 2차요인 3개 하위요인
        "label": "직무열의", "second_order": True,
        "facets": {"VI": (4, [], False), "DE": (4, [], False), "AB": (4, [], False)},
        "facet_load": {"VI":.85, "DE":.88, "AB":.81},
    },
    "PA": {  # 주도적 성격 — 단일요인 8문항
        "label": "주도적성격", "second_order": False,
        "facets": {"PA": (8, [5], False)}, "facet_load": {"PA":1.0},
    },
    "LS": {  # 학습지원문화 — Level-2 합산 대상 (팀 단위 공유 지각)
        "label": "학습지원문화", "second_order": False,
        "facets": {"LS": (5, [], False)}, "facet_load": {"LS":1.0},
    },
    "TI": {  # 이직의도 — 3문항 단일
        "label": "이직의도", "second_order": False,
        "facets": {"TI": (3, [], False)}, "facet_load": {"TI":1.0}, "hi_lam": True,
    },
    "JP": {  # 직무성과 — 4문항 단일
        "label": "직무성과", "second_order": False,
        "facets": {"JP": (4, [], False)}, "facet_load": {"JP":1.0}, "hi_lam": True,
    },
    "EX": {  # 정서적소진 — 4문항, α를 일부러 낮게 (실측 α=.536 사례 모사)
        "label": "정서적소진", "second_order": False,
        "facets": {"EX": (4, [], False)}, "facet_load": {"EX":1.0}, "weak": True,
    },
}

# ─────────────────────────────────────────────────────────────────
# 1. 조직(Level-2) 생성
# ─────────────────────────────────────────────────────────────────
org_id  = np.sort(RNG.integers(0, N_ORG, N_RAW))
org_ids = np.arange(N_ORG)
org_size = RNG.integers(80, 3000, N_ORG)                 # 조직 규모(명)
org_ind  = RNG.choice([1,2,3,4,5], N_ORG, p=[.34,.18,.14,.22,.12])
# 조직 수준 잠재 특성 : 학습지원문화(공유 지각) — ICC ≈ .12 목표
org_ls_true = RNG.normal(0, 1, N_ORG)
# 조직 수준 무선효과 : 절편(τ00), 기울기(τ11)
u0 = RNG.normal(0, .36, N_ORG)     # 이직의도 절편 분산
u1 = RNG.normal(0, .16, N_ORG)     # 자기자비→이직의도 기울기 분산
u1 += -.46 * org_ls_true      # 교차수준 상호작용 γ11의 씨앗           # 교차수준 상호작용의 씨앗 (γ11)

# ─────────────────────────────────────────────────────────────────
# 2. 잠재프로파일(LPA) 4계층 : 자기자비 6하위요인 프로파일
#    C1 자기수용형 / C2 자기비판형 / C3 양가형 / C4 무관심형
# ─────────────────────────────────────────────────────────────────
CLASS_P = [.31, .27, .28, .14]
PROFILE = {   # (SK, SJ, CH, IS, MI, OI) 표준화 평균  ※SJ/IS/OI는 역채점 전 원점수 기준
    0: (+0.95, -0.85, +0.72, -0.78, +0.88, -0.70),
    1: (-0.72, +1.05, -0.55, +0.98, -0.62, +1.02),
    2: (+0.55, +0.62, +0.18, +0.45, +0.30, +0.58),   # 양가형(둘 다 높음)
    3: (-0.55, -0.35, -0.62, -0.30, -0.70, -0.42),
}
cls = RNG.choice(4, N_RAW, p=CLASS_P)

# ─────────────────────────────────────────────────────────────────
# 3. 인구·고용 특성 (실측 분포 모사)
# ─────────────────────────────────────────────────────────────────
sex   = RNG.choice([1,2], N_RAW, p=[.496,.504])                    # 실측 178:181
age   = np.clip(RNG.normal(31.0, 4.6, N_RAW), 20, 44).round()      # 실측 M31.0 SD4.6
edu   = RNG.choice([1,2,3,4,5], N_RAW, p=[.072,.178,.646,.081,.023])
mar   = RNG.choice([1,2,3], N_RAW, p=[.716,.281,.003])
tenure= np.round(RNG.gamma(1.6, 2.3, N_RAW), 1)                    # skew≈1.5
career= np.round(tenure + RNG.gamma(1.9, 1.4, N_RAW), 1)           # skew≈0.7
n_job = RNG.poisson(1.55, N_RAW)                                   # 이직횟수
rank  = RNG.choice([1,2,3,4,5,6], N_RAW, p=[.507,.306,.134,.036,.011,.006])
firm  = RNG.choice([1,2,3], N_RAW, p=[.646,.164,.190])
emp   = RNG.choice([1,2], N_RAW, p=[.889,.111])
job   = RNG.choice(np.arange(1,11), N_RAW,
                   p=[.106,.039,.084,.162,.109,.078,.106,.028,.103,.185])
# 임금 : 로그정규 + 극단 이상치 (실측 skew 5.63, max 2000)
wage  = np.round(np.exp(RNG.normal(np.log(245), .38, N_RAW)))
wage[RNG.choice(N_RAW, 6, replace=False)] *= RNG.uniform(3.5, 9.0, 6)
wage  = np.clip(np.round(wage), 25, 2400)
# 응답 소요시간(초) : 로그정규, 불성실자는 뒤에서 별도 단축
resp_sec = np.round(np.exp(RNG.normal(np.log(880), .42, N_RAW)))

# ─────────────────────────────────────────────────────────────────
# 4. 잠재변인 구조방정식 (참값 True Model)
#    LS(조직) ─┐
#    PA ───────┼→ SC ──→ PC ──→ CM ──→ WE ──→ TI / JP
#              └────────────────(조절)──────────┘
# ─────────────────────────────────────────────────────────────────
PA_t = RNG.normal(0, 1, N_RAW)
LS_i = .52*org_ls_true[org_id] + RNG.normal(0, .98, N_RAW)   # 개인 지각(ICC≈.12)

# 자기자비 2차요인 : 프로파일 + 주도성 + 조직문화
prof = np.array([PROFILE[c] for c in cls])                   # (N,6)
SC_t = .38*PA_t + .22*LS_i + prof.mean(axis=1)*0.55 + RNG.normal(0, .62, N_RAW)
PC_t = .52*SC_t + .28*PA_t + .18*LS_i + RNG.normal(0, .70, N_RAW)   # 매개 M1
CM_t = .41*PC_t + .19*SC_t + .24*PA_t + RNG.normal(0, .72, N_RAW)   # 매개 M2 (직렬)
WE_t = .44*PC_t + .21*CM_t + .16*LS_i + RNG.normal(0, .69, N_RAW)

# 이직의도 : 다층 + 조절 + 조절된매개
mod   = LS_i                                                  # 조절변인
b_sc  = -.46 + u1[org_id] + .62*PA_t  # 개인수준 조절 (SC × PA) — 순수 L1
#      교차수준 조절은 u1 안의 org_ls_true가 담당 (γ11)                            # 무선기울기 + 교차수준
TI_t  = ( u0[org_id] + b_sc*SC_t - .29*WE_t + .21*(career/10)
          - .26*PC_t*mod + RNG.normal(0, .62, N_RAW) )
JP_t  = .38*WE_t + .26*CM_t + .17*PA_t + RNG.normal(0, .76, N_RAW)
EX_t  = -.31*PC_t + .24*TI_t + RNG.normal(0, .88, N_RAW)

TRUE = {"SC":SC_t, "PC":PC_t, "CM":CM_t, "WE":WE_t, "PA":PA_t,
        "LS":LS_i, "TI":TI_t, "JP":JP_t, "EX":EX_t}

# ─────────────────────────────────────────────────────────────────
# 5. 문항 응답 생성 : 2차요인 → 하위요인 → 문항, 5점 리커트 이산화
#    실측 목표 : 문항 M≈3.0~3.3, SD≈.78~1.11, skew -.46~+.21
# ─────────────────────────────────────────────────────────────────
def to_likert(z, item_mean, item_sd):
    """연속 잠재점수를 5점 리커트로. 문항별 난이도(평균)와 변별(SD) 반영."""
    x = item_mean + item_sd * z
    return np.clip(np.rint(x), LIK_MIN, LIK_MAX)

items, item_meta = {}, []
for con, spec in BLUEPRINT.items():
    t = TRUE[con]
    for fi, (fac, (k, rev_idx, neg_keyed)) in enumerate(spec["facets"].items()):
        fl = spec["facet_load"][fac]
        f_t = fl*t + np.sqrt(max(1-fl**2, .05))*RNG.normal(0, 1, N_RAW)
        if con == "SC":
            f_t = 0.80*f_t + 0.52*prof[:, fi]
        for j in range(k):
            if spec.get("weak"):      lam = RNG.uniform(.40, .62)
            elif spec.get("hi_lam"):  lam = RNG.uniform(.74, .90)
            elif con == "SC":         lam = RNG.uniform(.68, .90)
            else:                     lam = RNG.uniform(.62, .86)
            sgn = -1.0 if j in rev_idx else 1.0          # 요인 내 역문항
            z   = sgn*lam*f_t + np.sqrt(1-lam**2)*RNG.normal(0, 1, N_RAW)
            im  = RNG.uniform(2.92, 3.42)
            isd = RNG.uniform(.86, 1.05)
            name = f"{con}_{fac}_{j+1:02d}"
            score_rev = neg_keyed ^ (j in rev_idx)        # 채점 시 역채점 대상
            if score_rev: name += "R"
            items[name] = to_likert(z, im, isd)
            item_meta.append({"item": name, "construct": con,
                              "construct_kr": spec["label"], "facet": fac,
                              "reverse_scored": int(score_rev),
                              "second_order": int(spec["second_order"])})

D = pd.DataFrame(items)

# ─────────────────────────────────────────────────────────────────
# 6. 불성실 응답 주입 (실측 : 388건 중 29건 = 7.5% 제외)
#    유형 A 직선반응 / 유형 B 지그재그 / 유형 C 속도위반
# ─────────────────────────────────────────────────────────────────
item_cols = list(D.columns)
n_bad = 35
bad_idx = RNG.choice(N_RAW, n_bad, replace=False)
bad_type = RNG.choice(["A","B","C"], n_bad, p=[.60,.20,.20])
flag = np.zeros(N_RAW, int); reason = np.array([""]*N_RAW, dtype=object)

for i, bt in zip(bad_idx, bad_type):
    if bt == "A":                                   # 직선반응(straightlining)
        v = RNG.choice([3,3,4,2,5])
        seg = RNG.integers(int(len(item_cols)*.55), len(item_cols))
        D.loc[i, item_cols[:seg]] = v
        resp_sec[i] = RNG.integers(150, 330)
        flag[i], reason[i] = 2, "직선반응"
    elif bt == "B":                                 # 지그재그 패턴
        pat = np.tile([1,5,1,5,2,4], len(item_cols)//6 + 1)[:len(item_cols)]
        D.loc[i, item_cols] = pat
        resp_sec[i] = RNG.integers(200, 420)
        flag[i], reason[i] = 3, "패턴응답"
    else:                                           # 속도위반 + 무작위
        D.loc[i, item_cols] = RNG.integers(1, 6, len(item_cols))
        resp_sec[i] = RNG.integers(95, 210)
        flag[i], reason[i] = 4, "응답시간미달"

# 6-b. 경미한 저변량 응답자 (플래그 미달, 실측 IRV<.50 = 8.6% 재현)
mild = RNG.choice(np.setdiff1d(np.arange(N_RAW), bad_idx), 42, replace=False)
for i in mild:
    row = D.loc[i, item_cols].astype(float)
    ctr = np.rint(row.mean())
    w   = RNG.uniform(.72, .90)
    D.loc[i, item_cols] = np.clip(np.rint(ctr*w + row*(1-w)), 1, 5)

# ─────────────────────────────────────────────────────────────────
# 7. 결측 주입
#    - 리커트 블록 : 온라인 강제응답이라 매우 낮음 (0.4%)
#    - 자기기입 연속형(임금·이직시도) : 3~6%
#    - 종단 T2/T3 : 단위 무응답(패널 이탈) 13% / 24%
# ─────────────────────────────────────────────────────────────────
mask = RNG.random(D.shape) < .004
D = D.mask(mask)

try_move = RNG.poisson(1.25, N_RAW).astype(float)               # 이직시도 횟수
try_move[RNG.choice(N_RAW, 12, replace=False)] += RNG.integers(8, 26, 12)  # 극단치
wage_f = wage.astype(float)
wage_f[RNG.random(N_RAW) < .058] = np.nan
try_move[RNG.random(N_RAW) < .031] = np.nan

# ─────────────────────────────────────────────────────────────────
# 8. 종단 3파 (자기자비·직무열의·이직의도) — ARCL / Longitudinal SEM
#    자기회귀 β≈.55~.62, 교차지연 비대칭 (WE→TI 가 TI→WE 보다 강함)
# ─────────────────────────────────────────────────────────────────
def wave_next(x, y, ar, cl, s=.62):
    return ar*x + cl*y + RNG.normal(0, s, N_RAW)

SC1, WE1, TI1 = SC_t, WE_t, TI_t
SC2 = wave_next(SC1, WE1, .58, .14)
WE2 = wave_next(WE1, SC1, .61, .19)
TI2 = wave_next(TI1, WE1, .55, -.23)
SC3 = wave_next(SC2, WE2, .56, .12)
WE3 = wave_next(WE2, SC2, .59, .17)
TI3 = wave_next(TI2, WE2, .57, -.21)

def parcel(z, k=3, base=3.15):
    """잠재점수 → 문항꾸러미 3개(5점 리커트)"""
    out = {}
    for j in range(k):
        lam = RNG.uniform(.70, .84)
        out[j] = np.clip(np.rint(base + RNG.uniform(.88,1.0) *
                 (lam*z + np.sqrt(1-lam**2)*RNG.normal(0,1,N_RAW))), 1, 5)
    return out

# ─────────────────────────────────────────────────────────────────
# 9. 이분형 결과 & 생존자료
# ─────────────────────────────────────────────────────────────────
lin   = -1.15 + .78*TI_t - .42*WE_t + .23*(n_job/2) - .19*(tenure/5) + .16*(mod<0)
p_lv  = 1/(1+np.exp(-lin))
left  = RNG.binomial(1, p_lv)                       # 12개월 내 실제 이직 여부

haz   = np.exp(.62*TI_t - .35*WE_t + .28*PA_t*0 + .19*(n_job/2))
t_evt = RNG.exponential(26/haz)                     # 이직까지 개월
t_cen = RNG.uniform(9, 36, N_RAW)                   # 관찰중단
time_m = np.minimum(t_evt, t_cen).round(1)
event  = (t_evt <= t_cen).astype(int)

# ─────────────────────────────────────────────────────────────────
# 10. 마스터 조립
# ─────────────────────────────────────────────────────────────────
M = pd.DataFrame({
    "rid": [f"R{i+1:04d}" for i in range(N_RAW)],
    "org_id": [f"ORG{o+1:02d}" for o in org_id],
    "flag": flag, "flag_reason": reason, "resp_sec": resp_sec.astype(int),
    "sex": sex, "age": age.astype(int), "edu": edu, "marital": mar,
    "tenure_yr": tenure, "career_yr": career, "n_prev_job": n_job,
    "n_try_move": try_move, "rank": rank, "firm_size": firm,
    "emp_type": emp, "job_fn": job, "wage_10k": wage_f,
    "org_size": org_size[org_id], "org_industry": org_ind[org_id],
    "lpa_class_true": cls + 1,
})
M = pd.concat([M, D], axis=1)

# 종단 문항꾸러미
for wv, (sc, we, ti) in enumerate([(SC1,WE1,TI1),(SC2,WE2,TI2),(SC3,WE3,TI3)], 1):
    for nm, z in [("SC",sc), ("WE",we), ("TI",ti)]:
        for j, v in parcel(z).items():
            M[f"W{wv}_{nm}_p{j+1}"] = v

# 패널 이탈(단위 무응답)
drop2 = RNG.random(N_RAW) < .13
drop3 = drop2 | (RNG.random(N_RAW) < .13)
M.loc[drop2, [c for c in M.columns if c.startswith("W2_")]] = np.nan
M.loc[drop3, [c for c in M.columns if c.startswith("W3_")]] = np.nan

M["left_12m"] = left
M["time_months"] = time_m
M["event"] = event
M.loc[M.flag > 0, ["left_12m","time_months","event"]] = np.nan   # 불성실자는 추적 제외

# ─────────────────────────────────────────────────────────────────
# 11. 척도점수(역채점 반영) 계산 → clean 표본에만
# ─────────────────────────────────────────────────────────────────
def score(df, prefix):
    cols = [c for c in df.columns if c.startswith(prefix + "_")]
    tmp = df[cols].copy()
    for c in cols:
        if c.endswith("R"):
            tmp[c] = (LIK_MAX + LIK_MIN) - tmp[c]   # 역채점
    return tmp.mean(axis=1, skipna=True)

CLEAN = M[M.flag == 0].reset_index(drop=True).copy()
for con, spec in BLUEPRINT.items():
    for fac in spec["facets"]:
        CLEAN[f"{fac}_m"] = score(CLEAN, f"{con}_{fac}")
    CLEAN[f"{con}_TOT"] = score(CLEAN, con)

meta = pd.DataFrame(item_meta)
print(f"RAW N={len(M)}  CLEAN N={len(CLEAN)}  flagged={int((M.flag>0).sum())} "
      f"({(M.flag>0).mean()*100:.1f}%)  items={len(item_cols)}  orgs={N_ORG}")
M.to_pickle("/home/claude/kit/_master_raw.pkl")
CLEAN.to_pickle("/home/claude/kit/_master_clean.pkl")
meta.to_csv("/home/claude/kit/data/00_codebook_items.csv", index=False, encoding="utf-8-sig")
