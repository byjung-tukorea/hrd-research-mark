# ==========================================================================
#  12 · 구조방정식 CB-SEM  |  Covariance-Based SEM
#  질문: 측정오차를 걷어낸 개념들 사이의 관계 구조는?
#  지표: λ  AVE  CR  HTMT  CFI/TLI  RMSEA  SRMR  γ(CR≥1.96)
#  구조: 자기자비(2차, 6하위) → 긍정심리자본(2차, 4하위) → 직무열의(2차, 3하위) → 이직의도
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("12_cbsem_items.csv")

# ── 0. 역문항 역채점 (R로 끝나는 문항) ───────────────────────────────────
rev <- grep("R$", names(d), value = TRUE)
d[rev] <- 6 - d[rev]

# ── 1. 정규성 · 공통방법편의 ─────────────────────────────────────────────
items <- grep("^(SC|PC|WE|TI)_", names(d), value = TRUE)
sk(d[items])                                   # |왜도|<2, |첨도|<7 → ML 정당화
harman(d[items])                               # 단일요인 설명분산 < 50%

# ── 2. 1차 확인적 요인분석 (측정모형) ────────────────────────────────────
cfa1 <- '
  SK =~ SC_SK_01 + SC_SK_02 + SC_SK_03 + SC_SK_04
  SJ =~ SC_SJ_01R + SC_SJ_02R + SC_SJ_03R + SC_SJ_04R
  CH =~ SC_CH_01 + SC_CH_02 + SC_CH_03 + SC_CH_04
  IS =~ SC_IS_01R + SC_IS_02R + SC_IS_03R + SC_IS_04R
  MI =~ SC_MI_01 + SC_MI_02 + SC_MI_03 + SC_MI_04
  OI =~ SC_OI_01R + SC_OI_02R + SC_OI_03R + SC_OI_04R
  EF =~ PC_EF_01 + PC_EF_02 + PC_EF_03 + PC_EF_04 + PC_EF_05
  HO =~ PC_HO_01 + PC_HO_02 + PC_HO_03 + PC_HO_04 + PC_HO_05
  RE =~ PC_RE_01 + PC_RE_02 + PC_RE_03 + PC_RE_04 + PC_RE_05R
  OP =~ PC_OP_01 + PC_OP_02 + PC_OP_03 + PC_OP_04 + PC_OP_05
  VI =~ WE_VI_01 + WE_VI_02 + WE_VI_03 + WE_VI_04
  DE =~ WE_DE_01 + WE_DE_02 + WE_DE_03 + WE_DE_04
  AB =~ WE_AB_01 + WE_AB_02 + WE_AB_03 + WE_AB_04
  TI =~ TI_TI_01 + TI_TI_02 + TI_TI_03
'
f1 <- lavaan::cfa(cfa1, data = d, estimator = "MLR", missing = "fiml")
fit3(f1)                                       # χ²/df ≤ 3, CFI ≥ .90, RMSEA ≤ .08
lavaan::standardizedSolution(f1) |> dplyr::filter(op == "=~") |>
  dplyr::filter(est.std < .50)                 # λ < .50 문항 점검
lavaan::modindices(f1, sort = TRUE, maximum.number = 15)  # 이론적 근거 없이 수정 금지

# ── 3. 타당도 : AVE · CR · HTMT ──────────────────────────────────────────
semTools::reliability(f1)                      # alpha, omega, AVE
semTools::AVE(f1)                              # ≥ .50
semTools::htmt(cfa1, data = d)                 # < .85 (Fornell–Larcker보다 선호)
# Fornell–Larcker : √AVE > 구인 간 상관
sqrt(semTools::AVE(f1))
lavaan::lavInspect(f1, "cor.lv") |> round(2)

# ── 4. 2차 요인모형 (핵심) ───────────────────────────────────────────────
cfa2 <- paste(cfa1, '
  SC =~ SK + SJ + CH + IS + MI + OI      # 2차요인
  PC =~ EF + HO + RE + OP
  WE =~ VI + DE + AB
')
f2nd <- lavaan::cfa(cfa2, data = d, estimator = "MLR", missing = "fiml")
fit3(f2nd)
lavaan::lavTestLRT(f1, f2nd)                   # 1차 vs 2차 모형 비교 (Target coefficient)
c(TargetCoef = lavaan::fitMeasures(f1,"chisq") / lavaan::fitMeasures(f2nd,"chisq"))  # ≥ .90

# ── 5. 구조모형 (2단계 접근 — 측정모형 확보 후) ──────────────────────────
struct <- paste(cfa2, '
  PC ~ a*SC
  WE ~ b*PC + c*SC
  TI ~ d*WE + e*PC
  ind_SC_TI := a*b*d
')
fs <- lavaan::sem(struct, data = d, estimator = "MLR", missing = "fiml",
                  se = "bootstrap", bootstrap = 2000)
lavaan::summary(fs, standardized = TRUE, fit.measures = TRUE, rsquare = TRUE)
fit3(fs)
semPlot::semPaths(fs, "std", whatLabels = "std", layout = "tree2", edge.label.cex = .8)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 2단계 접근 — 측정모형 적합 확보 후 구조모형    □ χ²/df ≤ 3
# □ CFI/TLI ≥ .90, RMSEA ≤ .08 (90% CI 상한 포함), SRMR ≤ .08 — 세트로 보고
# □ λ ≥ .50, AVE ≥ .50, CR ≥ .70, HTMT < .85
# □ 2차요인 정당화는 Target coefficient(≥ .90)로
# □ MI로 오차상관을 추가할 때는 반드시 이론적 근거를 서술
