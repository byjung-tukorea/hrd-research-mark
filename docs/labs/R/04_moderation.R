# ==========================================================================
#  04 · 조절효과분석 (단순 조절)  |  Moderation
#  질문: 그 효과는 누구에게, 어떤 조건에서 더 강한가?
#  지표: ΔR²  β(상호작용)  단순기울기  Johnson–Neyman  VIF  f²
#  모형: SC × LS(학습지원문화) → TI(이직의도)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
d <- rd("04_moderation.csv")

# ── 1. 평균중심화 (상호작용항 VIF 급등 방지) ──────────────────────────────
d <- d |> dplyr::mutate(SC_c = scale(SC_TOT, scale = FALSE)[,1],
                        LS_c = scale(LS_TOT, scale = FALSE)[,1])

# ── 2. 위계적 투입 : 통제 → 주효과 → 상호작용 ────────────────────────────
h1 <- lm(TI_TOT ~ sex + age + tenure_yr, data = d)
h2 <- update(h1, . ~ . + SC_c + LS_c)
h3 <- update(h2, . ~ . + SC_c:LS_c)

anova(h1, h2, h3)                              # 3단계 ΔR² = 조절효과의 핵심 증거
c(dR2 = summary(h3)$r.squared - summary(h2)$r.squared)
round(summary(h3)$coef, 4)
car::vif(h3)                                   # 중심화 후 재확인
f2(h3, h2)

# ── 3. 단순기울기 (±1SD) ─────────────────────────────────────────────────
interactions::sim_slopes(h3, pred = SC_c, modx = LS_c, modx.values = "plus-minus")
interactions::interact_plot(h3, pred = SC_c, modx = LS_c,
                            interval = TRUE, plot.points = TRUE,
                            x.label = "자기자비(중심화)", y.label = "이직의도",
                            legend.main = "학습지원문화")

# ── 4. Johnson–Neyman 구간 (±1SD보다 정보량 많음) ────────────────────────
interactions::johnson_neyman(h3, pred = SC_c, modx = LS_c)

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 평균중심화 여부와 이유를 명시     □ 상호작용항 β 유의 + ΔR² 함께
# □ 단순기울기 도표 필수              □ 가능하면 J-N 유의영역까지
