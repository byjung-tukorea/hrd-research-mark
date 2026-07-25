# ==========================================================================
#  05 · 조절된 매개 · 매개된 조절 · 조절된 조절  |  Conditional Process
#  질문: 통로 자체가 조건에 따라 열리고 닫히는가?
#  지표: Index of Moderated Mediation(IMM)  조건부 간접효과  J-N  CI
#  모형: SC → PC → TI,  PC→TI 경로를 LS가 조절 (PROCESS 모형 14)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("05_conditional_process.csv") |>
  dplyr::mutate(SC_c = scale(SC_TOT, scale=FALSE)[,1],
                PC_c = scale(PC_TOT, scale=FALSE)[,1],
                LS_c = scale(LS_TOT, scale=FALSE)[,1],
                PA_c = scale(PA_TOT, scale=FALSE)[,1])

# ── A. 조절된 매개 (Moderated Mediation, PROCESS 14) ─────────────────────
mod14 <- '
  PC_c ~ a1*SC_c + sex + age + tenure_yr
  TI_TOT ~ b1*PC_c + b2*LS_c + b3*PC_c:LS_c + cp*SC_c + sex + age + tenure_yr

  # 조건부 간접효과 : 조절변인 ±1SD 지점
  LSlo := -1*sd(d$LS_c); LShi := 1*sd(d$LS_c)
  ind_lo  := a1*(b1 + b3*(-0.9))
  ind_mean:= a1*b1
  ind_hi  := a1*(b1 + b3*( 0.9))
  IMM     := a1*b3            # ★ 조절된 매개 지수 — 이것이 결론
'
f14 <- lavaan::sem(mod14, data = d, se = "bootstrap", bootstrap = 5000)
lavaan::parameterEstimates(f14, boot.ci.type = "bca.simple")

# ── B. 매개된 조절 (Mediated Moderation) ─────────────────────────────────
# X×W의 상호작용 효과가 M을 거쳐 Y로 전달되는 구조
modB <- '
  PC_c   ~ a1*SC_c + a2*LS_c + a3*SC_c:LS_c
  TI_TOT ~ b*PC_c + c1*SC_c + c2*LS_c + c3*SC_c:LS_c + sex + age
  medmod := a3*b              # 상호작용의 간접 전달분
'
fB <- lavaan::sem(modB, data = d, se = "bootstrap", bootstrap = 5000)
lavaan::parameterEstimates(fB, boot.ci.type = "bca.simple")

# ── C. 조절된 조절 = 3원 상호작용 (Three-way) ────────────────────────────
# 하위 2원 상호작용항을 모두 투입해야 3원항 해석이 성립
t1 <- lm(TI_TOT ~ SC_c*LS_c*PA_c + sex + age + tenure_yr, data = d)
round(summary(t1)$coef, 4)
anova(lm(TI_TOT ~ (SC_c+LS_c+PA_c)^2 + sex + age + tenure_yr, data=d), t1)  # ΔR²
interactions::sim_slopes(t1, pred = SC_c, modx = LS_c, mod2 = PA_c)
interactions::interact_plot(t1, pred = SC_c, modx = LS_c, mod2 = PA_c)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 조건부 간접효과 나열만으로 부족 — IMM의 CI가 0 미포함이어야 결론
# □ 3원 상호작용은 하위 2원항을 모두 투입          □ 모든 예측변인 중심화
# □ PROCESS(SPSS) 모형번호를 명시하면 재현성이 올라감
