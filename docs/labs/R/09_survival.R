# ==========================================================================
#  09 · 생존분석  |  Survival Analysis / Cox
#  질문: 사건이 일어나는가가 아니라 '언제' 일어나는가?
#  지표: Kaplan–Meier  Log-rank  HR(95% CI)  비례위험 가정(Schoenfeld)
#  종속: time_months(이직까지 개월) + event(1=이직, 0=중도절단)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("09_survival.csv")
S <- survival::Surv(d$time_months, d$event)

# ── 1. Kaplan–Meier 생존곡선 ─────────────────────────────────────────────
km <- survival::survfit(S ~ 1, data = d); summary(km, times = c(6,12,18,24))
d$LS_grp <- ifelse(d$LS_TOT >= median(d$LS_TOT, na.rm = TRUE), "높음", "낮음")
km2 <- survival::survfit(S ~ LS_grp, data = d)
survminer::ggsurvplot(km2, data = d, pval = TRUE, risk.table = TRUE,
                      conf.int = TRUE, xlab = "개월", ylab = "재직 생존확률")

# ── 2. Log-rank : 곡선 전체가 다른가 (교차하면 검정력 저하) ──────────────
survival::survdiff(S ~ LS_grp, data = d)

# ── 3. Cox 비례위험모형 ──────────────────────────────────────────────────
cox <- survival::coxph(S ~ sex + age + tenure_yr + n_prev_job + firm_size +
                         SC_TOT + WE_TOT + TI_TOT + LS_TOT, data = d)
summary(cox)                                  # exp(coef) = HR, 95% CI
broom::tidy(cox, exponentiate = TRUE, conf.int = TRUE)

# ── 4. 비례위험 가정 진단 (Cox 해석의 전제) ──────────────────────────────
zph <- survival::cox.zph(cox); zph              # p > .05 여야 충족
survminer::ggcoxzph(zph)
# 위배 시 : 시간의존 공변량 tt() 또는 층화 Cox strata()
# cox2 <- coxph(S ~ ... + strata(firm_size), data = d)

# ── 5. 모형 적합·영향치 ──────────────────────────────────────────────────
AIC(cox); survival::concordance(cox)            # C-index (AUC의 생존판)
survminer::ggcoxdiagnostics(cox, type = "dfbeta")

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ KM 곡선 + Log-rank + Cox HR을 한 세트로       □ 중도절단 비율 명시
# □ 비례위험 가정 검정 결과 필수 보고             □ HR과 OR을 혼용하지 말 것
