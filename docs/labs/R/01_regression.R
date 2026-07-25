# ==========================================================================
#  01 · 단순 · 다중 회귀분석  |  OLS Regression
#  질문: 여러 변인 중 무엇이 결과를 얼마나 설명하는가?
#  지표: B  β  R²/adjR²  F  sr²  VIF  DW   (+ p, CI, 1−β)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("01_regression.csv")

# ── 0. 기술통계 · 정규성(S/K) · 상관 ──────────────────────────────────────
vars <- c("PA_TOT","SC_TOT","PC_TOT","CM_TOT","LS_TOT","WE_TOT","JP_TOT")
sk(d[vars])                                   # |왜도|<2, |첨도|<7 확인
apaTables::apa.cor.table(d[vars], filename = "out/T1_correlations.doc")

# ── 1. 단순회귀 ───────────────────────────────────────────────────────────
m1 <- lm(JP_TOT ~ WE_TOT, data = d)
summary(m1)                                   # B, β는 아래에서, R², F

# ── 2. 다중회귀 ───────────────────────────────────────────────────────────
m2 <- lm(JP_TOT ~ PA_TOT + SC_TOT + PC_TOT + CM_TOT + WE_TOT +
                  factor(sex) + age + tenure_yr, data = d)
summary(m2)

# 비표준화 B + 95% CI  (실무 함의는 B로 서술)
cbind(B = coef(m2), confint(m2))

# 표준화 β  (변인 간 상대 비교는 β로 서술)
lm.beta <- function(m) {
  b <- coef(m)[-1]; sx <- sapply(model.frame(m)[-1], function(x)
    if (is.numeric(x)) sd(x, na.rm = TRUE) else sd(as.numeric(x), na.rm = TRUE))
  b * sx / sd(model.frame(m)[[1]], na.rm = TRUE)
}
round(lm.beta(m2), 3)

# ── 3. 고유 설명력 sr² (준편상관 제곱) ────────────────────────────────────
# 한 변인을 뺐을 때 줄어드는 R² = 그 변인만의 순수 기여
sr2 <- sapply(c("PA_TOT","SC_TOT","PC_TOT","CM_TOT","WE_TOT"), function(v) {
  red <- update(m2, paste(". ~ . -", v))
  summary(m2)$r.squared - summary(red)$r.squared
})
round(sr2, 4)

# ── 4. 효과크기 f² ────────────────────────────────────────────────────────
m0 <- lm(JP_TOT ~ factor(sex) + age + tenure_yr, data = d)   # 통제만
f2(m2, m0)                                    # .02 소 / .15 중 / .35 대

# ── 5. 회귀 가정 진단 ─────────────────────────────────────────────────────
car::vif(m2)                                  # VIF < 10 (엄격 < 5)
car::durbinWatsonTest(m2)                     # DW 1.5~2.5
performance::check_model(m2)                  # 잔차 정규성·등분산·영향치
shapiro.test(residuals(m2))
car::outlierTest(m2); influence.measures(m2)  # Cook's D

# ── 6. 검정력 사후 확인 (설계 단계에서는 사전 산출 권장) ──────────────────
# pwr::pwr.f2.test(u = 8, v = nrow(d)-9, f2 = f2(m2, m0), sig.level = .05)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ F 유의 · adjusted R² 함께 보고    □ B(95% CI)와 β 병기
# □ VIF < 10                          □ 잔차 정규성·독립성 진단 결과 명시
