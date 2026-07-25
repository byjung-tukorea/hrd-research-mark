# ==========================================================================
#  07 · 로지스틱 회귀분석  |  Logistic Regression
#  질문: '그렇다 / 아니다'가 갈리는 확률을 무엇이 바꾸는가?
#  지표: OR(95% CI)  Wald  Nagelkerke R²  Hosmer–Lemeshow  AUC  분류정확도
#  종속: left_12m (12개월 내 실제 이직 여부)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("07_logistic.csv") |> dplyr::mutate(across(c(sex, firm_size), factor))

m0 <- glm(left_12m ~ sex + age + tenure_yr, family = binomial, data = d)
m1 <- glm(left_12m ~ sex + age + tenure_yr + n_prev_job + firm_size +
            SC_TOT + PC_TOT + WE_TOT + TI_TOT + LS_TOT,
          family = binomial, data = d)
summary(m1)                                   # B, S.E., Wald(z²), p

# ── 승산비 OR + 95% CI  (CI가 1을 포함하면 비유의) ────────────────────────
round(exp(cbind(OR = coef(m1), confint(m1))), 3)

# ── Wald 통계량 ───────────────────────────────────────────────────────────
round((coef(summary(m1))[,"z value"])^2, 3)

# ── 유사 결정계수 (선형회귀 R²와 같은 의미 아님 — 각주 필수) ─────────────
n <- nobs(m1); L0 <- logLik(m0); L1 <- logLik(m1)
cox <- 1 - exp((2/n)*(L0 - L1)); nag <- cox / (1 - exp((2/n)*L0))
c(CoxSnell = as.numeric(cox), Nagelkerke = as.numeric(nag))

# ── 우도비 검정 (모형 전체 유의성) ────────────────────────────────────────
anova(m0, m1, test = "LRT")

# ── Hosmer–Lemeshow : p > .05 여야 적합 (역방향 해석 주의) ───────────────
ResourceSelection::hoslem.test(m1$y, fitted(m1), g = 10)

# ── 판별력 : ROC · AUC (.70 수용 / .80 양호 / .90 우수) ──────────────────
roc <- pROC::roc(m1$y, fitted(m1)); pROC::auc(roc); pROC::ci.auc(roc)
plot(roc, print.auc = TRUE)

# ── 분류정확도 · 민감도 · 특이도 ─────────────────────────────────────────
pred <- ifelse(fitted(m1) > .5, 1, 0)
tab <- table(예측 = pred, 실제 = m1$y); tab
c(정확도 = sum(diag(tab))/sum(tab),
  민감도 = tab["1","1"]/sum(tab[,"1"]),
  특이도 = tab["0","0"]/sum(tab[,"0"]))

# ── 다중공선성 ────────────────────────────────────────────────────────────
car::vif(m1)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ OR의 95% CI가 1 미포함     □ H-L은 p > .05 여야 적합
# □ AUC + 분류정확도 동반      □ Nagelkerke R²는 유사 R²임을 각주
# □ 위험비(RR)와 승산비(OR)를 혼용하지 말 것
