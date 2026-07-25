# ==========================================================================
#  08 · 잠재프로파일 · 잠재계층분석  |  LPA / LCA
#  질문: 사람들은 몇 개의 질적으로 다른 유형으로 나뉘는가?
#  지표: AIC/BIC/aBIC  Entropy  LMR·BLRT  최소집단비율  해석가능성
#  지표변인: 자기자비 6개 하위요인 (SK SJ CH IS MI OI)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("08_latent_profile.csv")
ind <- d |> dplyr::select(SK_facet, SJ_facet, CH_facet, IS_facet, MI_facet, OI_facet)

# ── 1. 계층 수를 1→6까지 늘려가며 비교 ───────────────────────────────────
fits <- tidyLPA::estimate_profiles(scale(ind), n_profiles = 1:6,
                                   variances = "equal", covariances = "zero")
tidyLPA::get_fit(fits)      # AIC BIC SABIC Entropy BLRT_p prob_min n_min

# 대안 : mclust로 분산·공분산 구조까지 자유롭게 탐색
mc <- mclust::Mclust(scale(ind), G = 1:6); summary(mc); plot(mc, what = "BIC")

# ── 2. 최종 해 선택 후 프로파일 기술 ─────────────────────────────────────
best <- tidyLPA::estimate_profiles(scale(ind), n_profiles = 4,
                                   variances = "equal", covariances = "zero")
tidyLPA::get_estimates(best)
plot_profiles(best, add_line = TRUE)

d$class <- tidyLPA::get_data(best)$Class
round(prop.table(table(d$class)), 3)          # 최소집단 5% 이상인지 확인

# ── 3. 계층별 외부 변인 차이 (3-step 대안 : BCH·ML 권장) ─────────────────
aov1 <- aov(WE_TOT ~ factor(class), data = d); summary(aov1)
effectsize::eta_squared(aov1)                 # η² .01/.06/.14
TukeyHSD(aov1)
chisq.test(table(d$class, d$left_12m))        # 계층 × 이직 여부
DescTools::CramerV(table(d$class, d$left_12m))

# ── 4. 범주형 지표라면 LCA (poLCA) ───────────────────────────────────────
# f <- cbind(item1, item2, item3) ~ 1
# poLCA::poLCA(f, data = dcat, nclass = 3, nrep = 20)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ BIC·aBIC 최저    □ Entropy ≥ .80    □ LMR·BLRT 유의
# □ 최소집단 5% 이상 □ 이론적 해석가능성 — 통계만으로 계층 수를 정하지 말 것
# □ 계층명은 프로파일 형태에 근거해 명명하고 근거를 서술
