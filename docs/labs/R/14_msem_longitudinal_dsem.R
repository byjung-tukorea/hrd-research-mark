# ==========================================================================
#  14 · MSEM · 종단 SEM · DSEM  |  Multilevel & Longitudinal SEM
#  질문: 측정오차 · 시간 · 위계를 한 모형에서 동시에 다루려면?
#  지표: 측정동일성(MI)  ICC  τ₀₀  γ  CFI  RMSEA  AIC/BIC
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
dw <- rd("14_msem_longitudinal.csv")    # 와이드 (SEM용)
dl <- rd("14b_longitudinal_LONG.csv")   # 롱 (성장모형·DSEM용)

# ══ A. 종단 측정동일성 — 모든 종단 분석의 전제 ═══════════════════════════
cfg <- '
  WE1 =~ l1*W1_WE_p1 + l2*W1_WE_p2 + l3*W1_WE_p3
  WE2 =~ m1*W2_WE_p1 + m2*W2_WE_p2 + m3*W2_WE_p3
  WE3 =~ n1*W3_WE_p1 + n2*W3_WE_p2 + n3*W3_WE_p3
  W1_WE_p1 ~~ W2_WE_p1 + W3_WE_p1
  W1_WE_p2 ~~ W2_WE_p2 + W3_WE_p2
  W1_WE_p3 ~~ W2_WE_p3 + W3_WE_p3
'
f_cfg <- lavaan::cfa(cfg, data = dw, missing = "fiml", estimator = "MLR")
met <- gsub("m1\\*|n1\\*", "l1*", gsub("m2\\*|n2\\*", "l2*",
       gsub("m3\\*|n3\\*", "l3*", cfg)))
f_met <- lavaan::cfa(met, data = dw, missing = "fiml", estimator = "MLR")
semTools::compareFit(f_cfg, f_met)      # ΔCFI ≤ .01, ΔRMSEA ≤ .015

# ══ B. 잠재성장모형 (Latent Growth Curve) ════════════════════════════════
lgm <- '
  i =~ 1*W1_WE_p1 + 1*W2_WE_p1 + 1*W3_WE_p1     # 절편(무선효과)
  s =~ 0*W1_WE_p1 + 1*W2_WE_p1 + 2*W3_WE_p1     # 기울기(무선효과)
  i ~~ s
  i ~ LS_TOT + sex                              # 조건부 성장모형
  s ~ LS_TOT + sex
'
f_lgm <- lavaan::growth(lgm, data = dw, missing = "fiml", estimator = "MLR")
lavaan::summary(f_lgm, standardized = TRUE, fit.measures = TRUE)
fit3(f_lgm)
# 무조건 → 조건부 순으로 AIC/BIC 비교
lavaan::fitMeasures(f_lgm, c("aic","bic"))

# ══ C. 병렬과정 성장모형 (직무열의 ↔ 이직의도 동반 변화) ════════════════
plgm <- '
  iWE =~ 1*W1_WE_p1 + 1*W2_WE_p1 + 1*W3_WE_p1
  sWE =~ 0*W1_WE_p1 + 1*W2_WE_p1 + 2*W3_WE_p1
  iTI =~ 1*W1_TI_p1 + 1*W2_TI_p1 + 1*W3_TI_p1
  sTI =~ 0*W1_TI_p1 + 1*W2_TI_p1 + 2*W3_TI_p1
  sTI ~ iWE + sWE
'
# f_plgm <- lavaan::growth(plgm, data = dw, missing = "fiml", estimator = "MLR")

# ══ D. MSEM — 다층 구조방정식 (개인 ⊂ 조직) ═════════════════════════════
msem <- '
  level: 1
    WE_w =~ W1_WE_p1 + W1_WE_p2 + W1_WE_p3
    TI_w =~ W1_TI_p1 + W1_TI_p2 + W1_TI_p3
    TI_w ~ WE_w
  level: 2
    WE_b =~ W1_WE_p1 + W1_WE_p2 + W1_WE_p3
    TI_b =~ W1_TI_p1 + W1_TI_p2 + W1_TI_p3
    TI_b ~ WE_b + LS_TOT
'
f_msem <- lavaan::sem(msem, data = dw, cluster = "org_id", estimator = "MLR")
lavaan::summary(f_msem, standardized = TRUE, fit.measures = TRUE)
# 수준별 ICC 먼저 확인
lavaan::lavInspect(f_msem, "icc")

# ══ E. DSEM 준비 — 롱폼 · 시점 내 변동 분해 ═════════════════════════════
# R에서는 근사만 가능. 본격 DSEM은 Mplus(TYPE=TWOLEVEL RANDOM) 또는 brms 권장
dl2 <- dl |> dplyr::group_by(rid) |>
  dplyr::mutate(WE_pm = mean(WE, na.rm = TRUE),      # 개인 평균(between)
                WE_cwc = WE - WE_pm,                 # 개인 내 편차(within)
                TI_lag = dplyr::lag(TI, 1)) |>       # 시차 변인
  dplyr::ungroup()

dsem_ap <- lmerTest::lmer(TI ~ TI_lag + WE_cwc + WE_pm + LS_TOT +
                            (1 + WE_cwc | rid), data = dl2, REML = FALSE)
summary(dsem_ap)         # 개인별 무선 자기회귀·교차지연의 근사
performance::icc(dsem_ap)

# brms 버전(베이지안, 개인별 무선 AR):
# brms::brm(TI ~ TI_lag + WE_cwc + WE_pm + (1 + TI_lag + WE_cwc | rid),
#           data = dl2, chains = 4, iter = 4000)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 수준별 분산 분해(ICC) → 측정동일성 → 성장모형 절편·기울기 무선효과 순
# □ 시간 코딩(0,1,2) 방식과 그 의미를 명시
# □ 결측은 FIML. MAR 가정의 타당성을 논의            □ AIC/BIC는 상대 비교만
# □ DSEM은 R 한계가 있어 Mplus·brms 사용을 밝히는 편이 정직
