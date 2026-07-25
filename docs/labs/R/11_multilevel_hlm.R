# ==========================================================================
#  11 · 다층분석  |  Multilevel Modeling (HLM)
#  질문: 이 관계는 개인의 이야기인가, 조직의 이야기인가?
#  지표: ICC(1)/ICC(2)  r_wg  τ₀₀  τ₁₁  γ  교차수준 상호작용  LRT(Δ−2LL)
#  구조: 개인 433명 ⊂ 조직 46개
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("11_multilevel_hlm.csv")

# ── 0. 합산 정당화 : r_wg · ICC(1) · ICC(2) ──────────────────────────────
# 개인 응답(LS_TOT)을 조직 수준 변인으로 올려도 되는지
rw <- multilevel::rwg(d$LS_TOT, d$org_id, ranvar = 2)   # 5점척도 균등분포 분산
mean(rw$rwg, na.rm = TRUE)                              # ≥ .70 권장
multilevel::ICC1(aov(LS_TOT ~ factor(org_id), data = d))
multilevel::ICC2(aov(LS_TOT ~ factor(org_id), data = d))# ≥ .70 권장

# ── 1. 무조건모형 (Null) : ICC로 다층 진입 정당화 ────────────────────────
m0 <- lmerTest::lmer(TI_TOT ~ 1 + (1 | org_id), data = d, REML = TRUE)
summary(m0)
performance::icc(m0)                       # ICC ≥ .05~.10 이면 HLM 정당
as.data.frame(lme4::VarCorr(m0))           # τ₀₀ 와 σ²

# ── 2. 중심화 : 방식에 따라 γ의 의미가 완전히 달라짐 ─────────────────────
d <- d |> dplyr::group_by(org_id) |>
  dplyr::mutate(SC_cwc = SC_TOT - mean(SC_TOT, na.rm = TRUE)) |>   # 집단평균중심화
  dplyr::ungroup() |>
  dplyr::mutate(LS_gmc = LS_org_mean - mean(LS_org_mean, na.rm = TRUE),  # 전체평균중심화
                WE_cwc = WE_TOT - ave(WE_TOT, org_id, FUN = function(x) mean(x, na.rm=TRUE)))

# ── 3. 무선계수모형 : 기울기도 집단마다 다른가 (τ₁₁) ─────────────────────
m1 <- lmerTest::lmer(TI_TOT ~ SC_cwc + WE_cwc + (1 | org_id), data = d, REML = TRUE)
m2 <- lmerTest::lmer(TI_TOT ~ SC_cwc + WE_cwc + (1 + SC_cwc | org_id), data = d, REML = TRUE)
anova(m1, m2, refit = FALSE)               # ★ REML LRT — 무선효과 비교
as.data.frame(lme4::VarCorr(m2))           # τ₀₀, τ₁₁, 공분산

# ── 4. 절편·기울기 모형 : 조직 변인 투입 + 교차수준 상호작용 ─────────────
m3 <- lmerTest::lmer(TI_TOT ~ SC_cwc + WE_cwc + LS_gmc + scale(org_size) +
                       SC_cwc:LS_gmc + (1 + SC_cwc | org_id),
                     data = d, REML = FALSE)   # ★ 고정효과 비교는 ML
summary(m3)                                    # γ₀₀ γ₁₀ γ₀₁ γ₁₁
confint(m3, method = "Wald")
performance::r2_nakagawa(m3)                   # 주변 R² / 조건부 R²

# 고정효과 비교는 ML 추정치로
m2ml <- update(m2, REML = FALSE); anova(m2ml, m3)

# ── 5. 교차수준 상호작용이 유의하면 단순기울기 도표 필수 ─────────────────
interactions::interact_plot(m3, pred = SC_cwc, modx = LS_gmc, interval = TRUE)

# ── 6. 진단 ──────────────────────────────────────────────────────────────
performance::check_model(m3)
lattice::qqmath(lme4::ranef(m2, condVar = TRUE))

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ ICC ≥ .05 로 진입 정당화 → 무조건 → 무선계수 → 절편·기울기 순서 서술
# □ 중심화 방식(집단평균 vs 전체평균)과 그 이유를 반드시 명시
# □ 무선효과 비교는 REML, 고정효과 비교는 ML — 섞지 말 것
# □ τ₀₀·τ₁₁는 '유의하게 0이 아닌가'가 판정 기준 (크기가 아님)
# □ 조직당 평균 사례수와 조직 수(46)를 보고 — 표본이 작으면 추정 불안정
