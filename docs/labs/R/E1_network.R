# ==========================================================================
#  E1-a · 네트워크 분석  |  Social Network Analysis
#  질문: 누가 누구에게 조언을 구하며, 그 위치가 성과와 관련되는가?
#  지표: 밀도 · 연결/매개/근접/아이겐벡터 중심성 · 호혜성 · 전이성 · MR-QAP
#  자료: 6개 조직 86명의 조언 네트워크 (전수조사)
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
if (!requireNamespace("igraph", quietly = TRUE)) install.packages(c("igraph","sna","network"))
library(igraph)

nodes <- rd("E1a_network_nodes.csv")
edges <- rd("E1b_network_edges.csv")

# ── 1. 그래프 생성 (조직별로 분리 — 조직 간 연결은 없음) ─────────────────
g_all <- igraph::graph_from_data_frame(
  d = edges[, c("from_rid","to_rid","weight")],
  vertices = nodes, directed = TRUE)

# ── 2. 전역 구조 지표 ────────────────────────────────────────────────────
orgs <- unique(nodes$org_id)
글로벌 <- do.call(rbind, lapply(orgs, function(o) {
  sg <- igraph::induced_subgraph(g_all, which(igraph::V(g_all)$org_id == o))
  data.frame(org_id = o,
    n           = igraph::gorder(sg),
    edges       = igraph::gsize(sg),
    density     = igraph::edge_density(sg),          # 밀도
    reciprocity = igraph::reciprocity(sg),           # 호혜성
    transitivity= igraph::transitivity(sg, type="global"),  # 전이성(군집계수)
    diameter    = igraph::diameter(sg),
    centralization = igraph::centr_degree(sg, mode="in")$centralization)
}))
print(글로벌)

# ── 3. 개인 수준 중심성 ──────────────────────────────────────────────────
V(g_all)$indeg    <- igraph::degree(g_all, mode = "in")     # 받는 조언 요청
V(g_all)$outdeg   <- igraph::degree(g_all, mode = "out")    # 보내는 조언 요청
V(g_all)$between  <- igraph::betweenness(g_all, directed = TRUE)
V(g_all)$close    <- igraph::closeness(g_all, mode = "all")
V(g_all)$eigen    <- igraph::eigen_centrality(g_all, directed = TRUE)$vector

cen <- igraph::as_data_frame(g_all, what = "vertices")
psych::describe(cen[, c("indeg","outdeg","between","eigen")])

# ── 4. 중심성과 개인 특성의 관계 ─────────────────────────────────────────
# 가설: 조언을 '받는' 사람(내향중심성)이 성과가 높고,
#       주도적 성격일수록 조언을 '보낸다'(외향중심성)
round(cor(cen[, c("indeg","outdeg","between","eigen",
                  "PA_TOT","SC_TOT","WE_TOT","JP_TOT")], use = "pairwise"), 3)

m1 <- lm(JP_TOT ~ indeg + outdeg + tenure_yr + factor(sex), data = cen)
summary(m1)
# 주의: 네트워크 지표를 독립변인으로 쓰는 회귀는 관측치 독립성 가정을 완전히
#       만족하지 못합니다. 조직을 군집으로 한 로버스트 표준오차나 다층모형 권장.
m2 <- lmerTest::lmer(JP_TOT ~ scale(indeg) + scale(outdeg) + tenure_yr + (1|org_id),
                     data = cen)
summary(m2)

# ── 5. 시각화 ────────────────────────────────────────────────────────────
o1 <- orgs[1]
sg <- igraph::induced_subgraph(g_all, which(V(g_all)$org_id == o1))
set.seed(2026)
plot(sg,
     layout = igraph::layout_with_fr(sg),
     vertex.size = 6 + 1.6*igraph::degree(sg, mode = "in"),
     vertex.color = ifelse(V(sg)$JP_TOT > median(V(sg)$JP_TOT), "#B34A83", "#EBC2D6"),
     vertex.label = NA,
     edge.arrow.size = .25, edge.color = "#C9C5BE",
     main = paste0(o1, " 조언 네트워크 (크기=내향중심성, 색=성과 중앙값 이상)"))

# ── 6. MR-QAP : 네트워크 간 관계를 검정한다 ─────────────────────────────
# 질문: 조언 관계는 협업 관계·동일 직무·직급 근접성으로 설명되는가?
library(sna)
adv <- as.matrix(read.csv(file.path(DATA,"E1c_matrix_advice.csv"),   row.names=1, check.names=FALSE))
col <- as.matrix(read.csv(file.path(DATA,"E1c_matrix_collab.csv"),   row.names=1, check.names=FALSE))
sj  <- as.matrix(read.csv(file.path(DATA,"E1c_matrix_samejob.csv"),  row.names=1, check.names=FALSE))
sr  <- as.matrix(read.csv(file.path(DATA,"E1c_matrix_samerank.csv"), row.names=1, check.names=FALSE))

n <- nrow(adv)
X <- array(dim = c(3, n, n)); X[1,,] <- col; X[2,,] <- sj; X[3,,] <- sr

set.seed(2026)
qap <- sna::netlm(adv, X, reps = 5000, nullhyp = "qapspp")
qap$names <- c("intercept","협업네트워크","동일직무","직급근접")
summary(qap)

# ── 해석 주의 ────────────────────────────────────────────────────────────
# □ QAP의 R²는 일반 회귀와 같은 의미가 아닙니다 (관측치 N²). 계수 방향·유의성 중심.
# □ 순열 검정 방식(qapspp / qapy / qapallx)을 명시하세요.
# □ 네트워크는 전수조사가 원칙 — 표본추출하면 구조가 왜곡됩니다.
# □ 응답률이 80% 미만이면 중심성 추정이 불안정해집니다. 응답률을 반드시 보고.

# ── 보고 체크리스트 ──────────────────────────────────────────────────────
# □ 네트워크 경계 정의(누구를 포함했나)와 응답률
# □ 관계 문항의 문구와 상한(예: "최대 5명까지")
# □ 밀도·호혜성·전이성·중심화 등 전역 지표
# □ 어떤 중심성을 왜 썼는지 (매개중심성과 연결중심성은 다른 개념)
# □ QAP 순열 횟수와 방식
# □ 결측 노드(무응답자) 처리 방식
