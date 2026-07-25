# ==========================================================================
#  03 · 매개효과분석 (Baron & Kenny + 부트스트랩)  |  Mediation
#  질문: X는 왜 Y에 영향을 주는가? 그 통로는 무엇인가?
#  지표: a·b·c'  ab(간접효과)  Sobel Z  Bootstrap CI  β  R²
#  모형: SC(자기자비) → PC(긍정심리자본) → WE(직무열의)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("03_mediation.csv")

# ── 1. Baron & Kenny 4단계 (역사적 절차 — 지금은 보조로만) ───────────────
step1 <- lm(WE_TOT ~ SC_TOT + sex + age + tenure_yr, data = d)                 # c
step2 <- lm(PC_TOT ~ SC_TOT + sex + age + tenure_yr, data = d)                 # a
step3 <- lm(WE_TOT ~ SC_TOT + PC_TOT + sex + age + tenure_yr, data = d)        # b, c'
lapply(list(c=step1, a=step2, `b·c'`=step3), function(m) round(summary(m)$coef, 4))

# ── 2. Sobel 검정 (정규성 가정 → 보조 지표) ──────────────────────────────
a <- coef(step2)["SC_TOT"]; sa <- summary(step2)$coef["SC_TOT","Std. Error"]
b <- coef(step3)["PC_TOT"]; sb <- summary(step3)$coef["PC_TOT","Std. Error"]
z <- (a*b) / sqrt(b^2*sa^2 + a^2*sb^2)
c(ab = a*b, Sobel_Z = z, p = 2*(1-pnorm(abs(z))))

# ── 3. 부트스트랩 편향수정 CI (현재 표준) ─────────────────────────────────
set.seed(2026)
med <- mediation::mediate(step2, step3, treat = "SC_TOT", mediator = "PC_TOT",
                          boot = TRUE, boot.ci.type = "bca", sims = 5000)
summary(med)          # ACME(간접) / ADE(직접) / Total / Prop. Mediated

# ── 4. lavaan 경로모형 (동일 결과 · 표준화계수까지) ──────────────────────
mod <- '
  PC_TOT ~ a*SC_TOT + sex + age + tenure_yr
  WE_TOT ~ b*PC_TOT + cp*SC_TOT + sex + age + tenure_yr
  ab := a*b            # 간접효과
  total := cp + a*b    # 총효과
  prop := ab/total     # 매개비율
'
fit <- lavaan::sem(mod, data = d, se = "bootstrap", bootstrap = 5000)
lavaan::parameterEstimates(fit, boot.ci.type = "bca.simple", standardized = TRUE)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 부트스트랩 5,000회 편향수정 CI가 0을 포함하지 않을 것 — 이것이 판정 기준
# □ Sobel은 보조. 단독 근거로 쓰지 말 것
# □ '완전매개/부분매개' 이분법 대신 간접효과 크기와 CI로 서술
