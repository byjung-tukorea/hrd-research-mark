# ==========================================================================
#  06 · 이중(직렬 다중) 매개효과분석  |  Serial Mediation
#  질문: X → M1 → M2 → Y 의 연쇄가 성립하는가?
#  지표: 특정 간접효과별 CI  경로 간 대비(contrast)  β  R²
#  모형: SC → PC → CM → JP  (PROCESS 모형 6)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("06_serial_mediation.csv")

mod <- '
  PC_TOT ~ a1*SC_TOT + sex + age + tenure_yr
  CM_TOT ~ a2*SC_TOT + d21*PC_TOT + sex + age + tenure_yr
  JP_TOT ~ cp*SC_TOT + b1*PC_TOT + b2*CM_TOT + sex + age + tenure_yr

  ind1  := a1*b1              # SC → PC → JP
  ind2  := a2*b2              # SC → CM → JP
  ind3  := a1*d21*b2          # SC → PC → CM → JP  (직렬)
  total_ind := ind1 + ind2 + ind3
  total := cp + total_ind

  # 경로 간 대비 — 어느 통로가 더 센지 통계적으로 비교
  c12 := ind1 - ind2
  c13 := ind1 - ind3
  c23 := ind2 - ind3
'
fit <- lavaan::sem(mod, data = d, se = "bootstrap", bootstrap = 5000,
                   missing = "fiml")
lavaan::summary(fit, standardized = TRUE, rsquare = TRUE)
lavaan::parameterEstimates(fit, boot.ci.type = "bca.simple") |>
  dplyr::filter(op == ":=")

semPlot::semPaths(fit, "std", edge.label.cex = .9, layout = "spring")

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 총간접효과 CI + 특정 간접효과 3개 CI를 모두 보고
# □ 대비 검정으로 통로 간 우열을 진술        □ 매개변인 투입 순서의 이론적 근거
