# ==========================================================================
#  10 · 자기회귀교차지연분석  |  ARCL / CLPM / RI-CLPM
#  질문: X가 Y보다 앞서는가, Y가 X보다 앞서는가?
#  지표: 자기회귀계수(AR)  교차지연계수(CL)  측정동일성(MI)  CFI  RMSEA
#  자료: 3파 문항꾸러미 (W1~W3 × SC/WE/TI × p1~p3), 이탈 12%/22%
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("10_arcl_clpm.csv")

# ── 0. 결측 진단 : 패널 이탈은 FIML로 처리 (목록별 삭제 금지) ────────────
colMeans(is.na(dplyr::select(d, dplyr::starts_with("W"))))

# ── 1. 측정동일성 (이것 없이 계수 비교는 무의미) ─────────────────────────
cfa_cfg <- '
  WE1 =~ W1_WE_p1 + W1_WE_p2 + W1_WE_p3
  WE2 =~ W2_WE_p1 + W2_WE_p2 + W2_WE_p3
  WE3 =~ W3_WE_p1 + W3_WE_p2 + W3_WE_p3
  W1_WE_p1 ~~ W2_WE_p1 + W3_WE_p1     # 동일문항 오차 상관 허용
  W1_WE_p2 ~~ W2_WE_p2 + W3_WE_p2
  W1_WE_p3 ~~ W2_WE_p3 + W3_WE_p3
'
f_cfg <- lavaan::cfa(cfa_cfg, data = d, missing = "fiml")                    # 형태
f_met <- lavaan::cfa(cfa_cfg, data = d, missing = "fiml", group.equal = "loadings")
semTools::compareFit(f_cfg, f_met)   # ΔCFI ≤ .01, ΔRMSEA ≤ .015 여야 통과
fit3(f_cfg)

# ── 2. 전통적 CLPM (잠재변인 버전) ───────────────────────────────────────
clpm <- '
  WE1 =~ W1_WE_p1 + W1_WE_p2 + W1_WE_p3
  WE2 =~ W2_WE_p1 + W2_WE_p2 + W2_WE_p3
  TI1 =~ W1_TI_p1 + W1_TI_p2 + W1_TI_p3
  TI2 =~ W2_TI_p1 + W2_TI_p2 + W2_TI_p3

  WE2 ~ ar_we*WE1 + cl_ti*TI1      # 자기회귀 + 교차지연
  TI2 ~ ar_ti*TI1 + cl_we*WE1
  WE1 ~~ TI1
  WE2 ~~ TI2
'
f_clpm <- lavaan::sem(clpm, data = d, missing = "fiml", estimator = "MLR")
lavaan::summary(f_clpm, standardized = TRUE, fit.measures = TRUE)
fit3(f_clpm)

# 두 방향 교차지연을 동일하게 제약 → 비대칭성 검정
clpm_eq <- gsub("cl_ti\\*", "cleq*", gsub("cl_we\\*", "cleq*", clpm))
f_eq <- lavaan::sem(clpm_eq, data = d, missing = "fiml", estimator = "MLR")
lavaan::lavTestLRT(f_clpm, f_eq)     # 유의하면 두 방향의 크기가 다름

# ── 3. RI-CLPM : 개인 내 변동과 개인 간 안정성을 분리 (권장) ─────────────
riclpm <- '
  # 무선절편(개인 간 안정 성분)
  RI_WE =~ 1*WEo1 + 1*WEo2 + 1*WEo3
  RI_TI =~ 1*TIo1 + 1*TIo2 + 1*TIo3
  WEo1 =~ 1*W1_WE_p1; WEo2 =~ 1*W2_WE_p1; WEo3 =~ 1*W3_WE_p1
  TIo1 =~ 1*W1_TI_p1; TIo2 =~ 1*W2_TI_p1; TIo3 =~ 1*W3_TI_p1
  # 개인 내 편차 성분의 교차지연
  WEo2 ~ WEo1 + TIo1
  TIo2 ~ TIo1 + WEo1
  WEo3 ~ WEo2 + TIo2
  TIo3 ~ TIo2 + WEo2
  RI_WE ~~ RI_TI
'
# f_ri <- lavaan::sem(riclpm, data = d, missing = "fiml", estimator = "MLR")

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 측정동일성 확보 후에만 계수 비교      □ 양방향 교차지연 동시 추정·보고
# □ 자기회귀 경로를 통제해야 인과 주장 성립
# □ 이탈은 FIML     □ CLPM만 쓰면 최근 심사에서 RI-CLPM 검토 여부를 묻습니다
