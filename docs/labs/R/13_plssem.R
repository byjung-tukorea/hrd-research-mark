# ==========================================================================
#  13 · 구조방정식 PLS-SEM  |  Partial Least Squares
#  질문: 표본이 작고 예측이 목적일 때의 구조 검증은?
#  지표: 외부적재(λ)  AVE  rhoC  HTMT  R²  f²  Q²  VIF  부트스트랩 t
#  구조: 주도적성격 → 자기자비 → 긍정심리자본 → 경력관리행동 → 직무성과
#        (반영적 2차요인은 반복지표 접근 repeated indicators)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
library(seminr)
d <- as.data.frame(rd("13_plssem_items.csv"))
rev <- grep("R$", names(d), value = TRUE); d[rev] <- 6 - d[rev]

g <- function(p) grep(paste0("^", p), names(d), value = TRUE)

# ── 1. 측정모형 : 1차 하위요인 + 2차요인(반복지표) ───────────────────────
mm <- constructs(
  reflective("PA", g("PA_PA")),
  reflective("SK", g("SC_SK")), reflective("SJ", g("SC_SJ")),
  reflective("CH", g("SC_CH")), reflective("IS", g("SC_IS")),
  reflective("MI", g("SC_MI")), reflective("OI", g("SC_OI")),
  reflective("EF", g("PC_EF")), reflective("HO", g("PC_HO")),
  reflective("RE", g("PC_RE")), reflective("OP", g("PC_OP")),
  reflective("CE", g("CM_CE")), reflective("NW", g("CM_NW")),
  reflective("SP", g("CM_SP")), reflective("MB", g("CM_MB")),
  reflective("JP", g("JP_JP")),
  higher_composite("SC", c("SK","SJ","CH","IS","MI","OI"),
                   method = two_stage, weights = mode_A),
  higher_composite("PC", c("EF","HO","RE","OP"), method = two_stage, weights = mode_A),
  higher_composite("CM", c("CE","NW","SP","MB"), method = two_stage, weights = mode_A)
)

# ── 2. 구조모형 ──────────────────────────────────────────────────────────
sm <- relationships(
  paths(from = "PA", to = c("SC","PC","CM")),
  paths(from = "SC", to = c("PC","CM")),
  paths(from = "PC", to = c("CM","JP")),
  paths(from = "CM", to = "JP")
)

est <- estimate_pls(data = d, measurement_model = mm, structural_model = sm,
                    missing = mean_replacement, missing_value = NA)
s <- summary(est)

# ── 3. 측정모형 평가 ─────────────────────────────────────────────────────
s$loadings                 # 외부적재 ≥ .70 (탐색 .60)
s$reliability              # alphaC, rhoC ≥ .70, AVE ≥ .50, rhoA
s$validity$htmt            # HTMT < .85
s$validity$fl_criteria     # Fornell–Larcker

# ── 4. 구조모형 평가 ─────────────────────────────────────────────────────
s$vif_antecedents          # 내부 VIF < 5 (PLS는 기준이 더 엄격)
s$paths                    # 경로계수 · R²
s$fSquare                  # f² .02/.15/.35

# ── 5. 유의성 : 부트스트랩 (PLS는 분포가정이 없어 필수) ──────────────────
bt <- bootstrap_model(seminr_model = est, nboot = 5000, cores = 2)
summary(bt, alpha = .05)   # t값 > 1.96, 95% CI가 0 미포함

# ── 6. 예측력 Q² : Blindfolding / PLSpredict ─────────────────────────────
pp <- predict_pls(model = est, technique = predict_DA, noFolds = 10, reps = 10)
summary(pp)                # Q²predict > 0 이면 예측력 있음, RMSE를 LM과 비교

# ── 7. 적합도 (PLS에서는 SRMR이 사실상 유일) ─────────────────────────────
s$descriptives; s$it_criteria
# SRMR ≤ .08

# ── 보고 체크리스트 ───────────────────────────────────────────────────────
# □ 왜 CB-SEM이 아니라 PLS인지(표본·예측목적·형성적 구인) 정당화 필수
# □ 외부적재 ≥ .70 · AVE ≥ .50 · rhoC ≥ .70 · HTMT < .85
# □ R²는 표본 내 설명, Q²는 표본 밖 예측 — 둘 다 보고
# □ 경로 유의성은 반드시 부트스트랩 5,000회
