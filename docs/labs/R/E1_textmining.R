# ==========================================================================
#  E1-b · 텍스트마이닝  |  Keyword Network & Topic Modeling
#  질문: 자유응답에 어떤 잠재 주제가 있으며, 누가 어떤 주제를 말하는가?
#  지표: TF-IDF · 동시출현 네트워크 · LDA 토픽 · 일관성 · 토픽 비중
#  자료: 433명의 인재개발 개선점 자유응답
# ==========================================================================
source(if (file.exists("labs/R/00_setup.R")) "labs/R/00_setup.R" else "00_setup.R")
need <- c("tidytext","tm","topicmodels","ldatuning","igraph","ggraph","widyr","stm")
new <- need[!need %in% installed.packages()[,"Package"]]
if (length(new)) install.packages(new)
library(tidytext); library(dplyr); library(topicmodels)

d <- rd("E1d_text_openended.csv")

# ── 0. 무응답·무의미 응답 제거 ───────────────────────────────────────────
nrow(d)
d <- d |> filter(!is.na(answer), nchar(trimws(answer)) > 5,
                 !answer %in% c("없음","모름","무","-"))
nrow(d)                                   # 제외 인원을 반드시 보고

# ── 1. 전처리 ────────────────────────────────────────────────────────────
# 실제 한국어 자료는 형태소 분석이 필요합니다:
#   KoNLP::extractNoun() 또는 RcppMeCab::pos()  / Python은 KoNLPy
#   ※ 사용자 사전 등록이 결과를 크게 좌우합니다 (예: "워라밸", "역량개발")
# 본 실습 데이터는 명사 위주로 생성되어 공백 분리만으로 진행합니다.

stopwords_ko <- c("회사","조직","부서","우리","직원","구성원","현재","요즘",
                  "생각","필요","차원","측면","부분","관련","때문","가장",
                  "이가","것","수","점","등","및")

tok <- d |>
  select(rid, org_id, TI_TOT, WE_TOT, LS_TOT, answer) |>
  unnest_tokens(word, answer, token = "words") |>
  mutate(word = gsub("[[:punct:]]", "", word)) |>
  filter(nchar(word) >= 2, !word %in% stopwords_ko)

# 빈도
tok |> count(word, sort = TRUE) |> head(30)

# TF-IDF — 특정 집단에서 두드러지는 단어
tok |> mutate(grp = ifelse(TI_TOT > median(d$TI_TOT), "이직의도 높음", "낮음")) |>
  count(grp, word) |> bind_tf_idf(word, grp, n) |>
  arrange(desc(tf_idf)) |> group_by(grp) |> slice_head(n = 10) |> print(n = 20)

# ── 2. 키워드 동시출현 네트워크 ──────────────────────────────────────────
library(widyr); library(igraph); library(ggraph)
pairs <- tok |> group_by(word) |> filter(n() >= 15) |> ungroup() |>
  pairwise_count(word, rid, sort = TRUE, upper = FALSE)

set.seed(2026)
pairs |> filter(n >= 12) |>
  graph_from_data_frame() |>
  ggraph(layout = "fr") +
  geom_edge_link(aes(width = n), alpha = .35, colour = "#B34A83") +
  geom_node_point(size = 5, colour = "#161514") +
  geom_node_text(aes(label = name), repel = TRUE, size = 3.4) +
  theme_void()

# 중심성으로 핵심어 파악
kn <- pairs |> filter(n >= 10) |> graph_from_data_frame(directed = FALSE)
sort(igraph::degree(kn), decreasing = TRUE)[1:15]
sort(igraph::betweenness(kn), decreasing = TRUE)[1:10]   # 주제 간 다리 역할 단어

# ── 3. LDA 토픽 모델링 ───────────────────────────────────────────────────
dtm <- tok |> count(rid, word) |> cast_dtm(rid, word, n)
dtm <- tm::removeSparseTerms(dtm, 0.995)
dim(dtm)

# 토픽 수 탐색 — 일관성/혼란도 지표
library(ldatuning)
tune <- FindTopicsNumber(dtm, topics = 2:10,
          metrics = c("CaoJuan2009","Arun2010","Deveaud2014"),
          method = "Gibbs", control = list(seed = 2026), verbose = TRUE)
FindTopicsNumber_plot(tune)
# CaoJuan·Arun은 최소화, Deveaud는 최대화 지점을 봅니다.
# 통계 지표가 갈리면 해석가능성으로 결정 — 이 자료는 5개 토픽 구조입니다.

K <- 5
lda <- LDA(dtm, k = K, method = "Gibbs",
           control = list(seed = 2026, burnin = 1000, iter = 2000))

# 토픽별 대표 단어 (β)
tidy(lda, matrix = "beta") |> group_by(topic) |>
  slice_max(beta, n = 10) |> arrange(topic, -beta) |> print(n = 50)

# 문서별 토픽 비중 (γ)
gam <- tidy(lda, matrix = "gamma") |>
  rename(rid = document) |>
  group_by(rid) |> slice_max(gamma, n = 1) |> ungroup()
table(gam$topic)

# ── 4. 토픽과 외부 변인의 관계 ───────────────────────────────────────────
# "이직의도가 높은 사람은 어떤 주제를 말하는가"
dd <- d |> inner_join(gam, by = "rid")
aov1 <- aov(TI_TOT ~ factor(topic), data = dd); summary(aov1)
effectsize::eta_squared(aov1)
dd |> group_by(topic) |> summarise(n = n(), TI = mean(TI_TOT), WE = mean(WE_TOT))

# ── 5. STM — 공변량을 토픽 모델에 직접 넣는다 ────────────────────────────
# 사후 비교가 아니라 모형 안에서 "이직의도에 따라 토픽 비중이 다른가"를 추정
library(stm)
proc <- textProcessor(documents = d$answer, metadata = d,
                      language = "na", removestopwords = FALSE,
                      customstopwords = stopwords_ko, stem = FALSE)
out  <- prepDocuments(proc$documents, proc$vocab, proc$meta, lower.thresh = 5)

fit_stm <- stm(out$documents, out$vocab, K = 5,
               prevalence = ~ TI_TOT + WE_TOT + LS_TOT,
               data = out$meta, init.type = "Spectral", seed = 2026)
labelTopics(fit_stm, n = 10)
eff <- estimateEffect(1:5 ~ TI_TOT + WE_TOT, fit_stm, meta = out$meta)
summary(eff)
plot(eff, covariate = "TI_TOT", topics = 1:5, method = "difference",
     cov.value1 = 4.5, cov.value2 = 2.0)

# ── 토픽 명명 ────────────────────────────────────────────────────────────
# 알고리즘은 단어 묶음만 줍니다. 이름은 연구자가 붙이고 근거를 제시하세요.
#   ① 대표 단어 상위 10개 (β 기준)
#   ② 대표 문서 3건 (findThoughts(fit_stm, texts = ..., topics = k, n = 3))
#   ③ 복수 연구자가 독립 명명 후 일치도 보고

# ── 보고 체크리스트 ──────────────────────────────────────────────────────
# □ 형태소 분석기와 사용자 사전 · 불용어 목록을 부록에 제시
# □ 무응답·무의미 응답 제외 기준과 인원
# □ 토픽 수 결정 근거 (지표 + 해석가능성)
# □ 토픽별 대표 단어와 대표 문서
# □ 토픽 명명 절차와 연구자 간 일치도
# □ BERTopic 사용 시 임베딩 모델명·버전 (재현성)
