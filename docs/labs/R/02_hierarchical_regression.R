# ==========================================================================
#  02 · 위계적 회귀분석  |  Hierarchical Regression
#  질문: 통제변인을 걷어내고도 내 변인이 추가로 설명하는가?
#  지표: ΔR²  F change  sr²  β  R²  f²
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("02_hierarchical_regression.csv")

# ── 투입 순서의 이론적 근거를 반드시 서술할 것 ────────────────────────────
# 1단계 인구·고용 통제 → 2단계 개인 성향 → 3단계 심리적 자원 → 4단계 조직 맥락
s1 <- lm(WE_TOT ~ factor(sex) + age + tenure_yr + factor(rank), data = d)
s2 <- update(s1, . ~ . + PA_TOT)
s3 <- update(s2, . ~ . + SC_TOT + PC_TOT)
s4 <- update(s3, . ~ . + LS_TOT)

# ── 단계별 R² · ΔR² · F change ────────────────────────────────────────────
steps <- list(`1단계 통제`=s1, `2단계 성향`=s2, `3단계 자원`=s3, `4단계 맥락`=s4)
tab <- data.frame(
  R2     = sapply(steps, function(m) summary(m)$r.squared),
  adjR2  = sapply(steps, function(m) summary(m)$adj.r.squared))
tab$dR2 <- c(NA, diff(tab$R2))
round(tab, 4)

anova(s1, s2, s3, s4)          # F change 검정 — 위계적 회귀의 핵심 증거

# ── 단계별 표준화계수 ─────────────────────────────────────────────────────
lapply(steps, function(m) round(coef(summary(m))[, c("Estimate","Pr(>|t|)")], 3))

# ── 최종모형 효과크기 f² · 진단 ───────────────────────────────────────────
f2(s4, s1); car::vif(s4)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 각 단계 R², ΔR², F change, df를 한 표에 정리
# □ ΔR²와 sr²는 수치가 같으므로 둘 중 하나만 보고
# □ 투입 순서의 이론적 정당화를 본문에 명시
