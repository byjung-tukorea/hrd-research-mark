# ==========================================================================
#  00_setup.R — 패키지 설치 · 공통 함수
#  통계지표 계보도 실습 키트 / R 4.3+
# ==========================================================================

pkgs <- c(
  "tidyverse","psych","car","lavaan","semTools","semPlot",   # 기본·SEM
  "lme4","lmerTest","performance","multilevel","nlme",       # 다층
  "mediation","interactions",                                # 매개·조절
  "survival","survminer",                                    # 생존
  "tidyLPA","mclust","poLCA",                                # 잠재프로파일
  "seminr",                                                  # PLS-SEM
  "pROC","ResourceSelection",                                # 로지스틱
  "apaTables","broom","broom.mixed","effectsize"             # 보고
)
new <- pkgs[!pkgs %in% installed.packages()[,"Package"]]
if (length(new)) install.packages(new, dependencies = TRUE)
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 데이터 경로 자동 탐지 ─────────────────────────────────────────────────
# 저장소 루트에서 실행하든 labs/ 에서 실행하든 동작합니다.
DATA <- local({
  cand <- c("labs/data", "data", "../data", "../labs/data")
  hit  <- cand[file.exists(file.path(cand, "00_master_wide_CLEAN.csv"))]
  if (!length(hit)) stop("데이터 폴더를 찾지 못했습니다. 작업 디렉터리를 저장소 루트로 설정하세요.")
  hit[1]
})
rd <- function(f) readr::read_csv(file.path(DATA, f), show_col_types = FALSE)
cat("데이터 경로:", DATA, "\n")

# ── 공통 진단 함수 ────────────────────────────────────────────────────────
# 왜도·첨도 (S/K)
sk <- function(d) psych::describe(d)[, c("n","mean","sd","skew","kurtosis")]

# 신뢰도 α와 ω를 나란히
rel <- function(d, keys = NULL) {
  a <- psych::alpha(d, keys = keys, check.keys = FALSE)$total$raw_alpha
  o <- tryCatch(psych::omega(d, nfactors = 1, plot = FALSE)$omega.tot, error = function(e) NA)
  c(alpha = round(a, 3), omega = round(o, 3))
}

# 공통방법편의 : Harman 단일요인 검정 (설명분산 < 50%)
harman <- function(d) {
  fa <- psych::principal(na.omit(d), nfactors = 1)
  cat("Harman 단일요인 설명분산:", round(fa$values[1] / ncol(d) * 100, 2), "%\n")
}

# 급내상관 ICC(1) / ICC(2) / r_wg
icc_set <- function(y, grp, k_items = NULL, A = 5) {
  m  <- lme4::lmer(y ~ 1 + (1 | grp))
  vc <- as.data.frame(lme4::VarCorr(m))
  t00 <- vc$vcov[1]; s2 <- vc$vcov[2]
  n  <- mean(table(grp))
  c(ICC1 = t00 / (t00 + s2), ICC2 = (n * t00) / (n * t00 + s2), n_bar = n)
}

# 효과크기 f²
f2 <- function(full, reduced) {
  r2f <- summary(full)$r.squared; r2r <- summary(reduced)$r.squared
  (r2f - r2r) / (1 - r2f)
}

# 적합도 3종 세트만 뽑기
fit3 <- function(fit) lavaan::fitMeasures(
  fit, c("chisq","df","pvalue","cfi","tli","rmsea","rmsea.ci.upper","srmr"))

if (!dir.exists("out")) dir.create("out")   # 결과물 저장 폴더
cat("setup 완료 — rd('01_regression.csv') 형태로 데이터를 불러오세요.\n")
