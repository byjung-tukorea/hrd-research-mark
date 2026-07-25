# -*- coding: utf-8 -*-
"""확장 트랙 E1용 네트워크·텍스트 데이터 생성
   마스터 데이터(433명 × 46조직)와 정합적으로 연결됩니다."""
import numpy as np, pandas as pd

RNG = np.random.default_rng(20260724)
D = "/home/claude/repo2/labs/data"
M = pd.read_csv(f"{D}/00_master_wide_CLEAN.csv")

# ── 1. 조언 네트워크 : 규모가 큰 상위 6개 조직만 전수조사 ────────────
sizes = M.org_id.value_counts()
targets = list(sizes[sizes >= 12].index[:6])
sub = M[M.org_id.isin(targets)].reset_index(drop=True)
print(f"네트워크 대상 조직 {len(targets)}개 · {len(sub)}명")

nodes, edges = [], []
for org in targets:
    g = sub[sub.org_id == org].reset_index(drop=True)
    n = len(g)
    ids = list(g.rid)
    # 노드 속성
    for i, r in g.iterrows():
        nodes.append(dict(rid=r.rid, org_id=org, sex=r.sex, age=r.age,
                          tenure_yr=r.tenure_yr, rank=r["rank"], job_fn=r.job_fn,
                          PA_TOT=round(r.PA_TOT,3), SC_TOT=round(r.SC_TOT,3),
                          WE_TOT=round(r.WE_TOT,3), JP_TOT=round(r.JP_TOT,3),
                          LS_TOT=round(r.LS_TOT,3)))
    # 엣지 생성 확률 : 동질성(직무·직급) + 주도성(보내는 쪽) + 성과(받는 쪽) + 호혜성
    A = np.zeros((n, n), int)
    pa = (g.PA_TOT - g.PA_TOT.mean()).values
    jp = (g.JP_TOT - g.JP_TOT.mean()).values
    ten = g.tenure_yr.values
    for i in range(n):
        for j in range(n):
            if i == j: continue
            lin = (-1.55
                   + 0.45*(g.job_fn[i] == g.job_fn[j])        # 동일 직무 (동질성)
                   + 0.30*(abs(g["rank"][i] - g["rank"][j]) <= 1)
                   + 0.42*pa[i]                                # 주도적일수록 많이 물음
                   + 0.55*jp[j]                                # 성과 높은 사람에게 물음
                   + 0.16*np.log1p(ten[j])                     # 고연차에게 물음
                   + 0.60*A[j, i])                             # 호혜성
            if RNG.random() < 1/(1+np.exp(-lin)):
                A[i, j] = 1
    # 전이성 보강 (친구의 친구)
    for _ in range(int(n*1.2)):
        i, k = RNG.integers(0, n, 2)
        if i == k: continue
        mids = np.where((A[i] == 1))[0]
        if len(mids) and A[i, k] == 0:
            m = RNG.choice(mids)
            if A[m, k] == 1 and RNG.random() < .45:
                A[i, k] = 1
    for i in range(n):
        for j in range(n):
            if A[i, j]:
                edges.append(dict(org_id=org, from_rid=ids[i], to_rid=ids[j],
                                  weight=int(RNG.integers(1, 4))))

ND = pd.DataFrame(nodes); ED = pd.DataFrame(edges)
dens = len(ED) / sum(len(sub[sub.org_id==o])*(len(sub[sub.org_id==o])-1) for o in targets)
print(f"엣지 {len(ED)}개 · 전체 밀도 {dens:.3f}")
ND.to_csv(f"{D}/E1a_network_nodes.csv", index=False, encoding="utf-8-sig")
ED.to_csv(f"{D}/E1b_network_edges.csv", index=False, encoding="utf-8-sig")

# ── 2. 인접행렬 (MR-QAP용) : 가장 큰 조직 1개 ────────────────────────
top = sizes.index[0]
g = sub[sub.org_id == top].reset_index(drop=True) if top in targets else \
    sub[sub.org_id == targets[0]].reset_index(drop=True)
top = g.org_id.iloc[0]; ids = list(g.rid); n = len(g)
adv = np.zeros((n, n), int)
e0 = ED[ED.org_id == top]
idx = {r: i for i, r in enumerate(ids)}
for _, r in e0.iterrows():
    adv[idx[r.from_rid], idx[r.to_rid]] = 1
# 협업 네트워크 : 조언 네트워크와 부분 중첩 + 독자 성분
collab = ((adv + adv.T) > 0).astype(int)
flip = RNG.random((n, n)) < .12
collab = np.where(flip, 1 - collab, collab)
np.fill_diagonal(collab, 0); collab = ((collab + collab.T) > 0).astype(int)
same_job  = (g.job_fn.values[:, None] == g.job_fn.values[None, :]).astype(int)
same_rank = (np.abs(g["rank"].values[:, None] - g["rank"].values[None, :]) <= 1).astype(int)
np.fill_diagonal(same_job, 0); np.fill_diagonal(same_rank, 0)
for nm, mat in [("advice", adv), ("collab", collab), ("samejob", same_job), ("samerank", same_rank)]:
    pd.DataFrame(mat, index=ids, columns=ids).to_csv(
        f"{D}/E1c_matrix_{nm}.csv", encoding="utf-8-sig")
print(f"인접행렬 4종 ({top}, n={n})")

# ── 3. 자유응답 텍스트 : 5개 잠재 토픽 구조를 심어 둠 ────────────────
TOPICS = {
 "경력·성장": ["경력", "성장", "승진", "미래", "비전", "전문성", "역량개발", "커리어",
              "자기계발", "직무전환", "경력경로", "장기적"],
 "교육·학습": ["교육", "학습", "연수", "과정", "강의", "실습", "온라인", "콘텐츠",
              "학습시간", "교육비", "자격증", "스터디"],
 "리더십·관계": ["상사", "리더", "팀장", "소통", "피드백", "신뢰", "동료", "협업",
                "관계", "분위기", "존중", "코칭"],
 "보상·처우": ["연봉", "보상", "복지", "임금", "인센티브", "처우", "평가", "공정",
              "승급", "수당", "형평성", "만족"],
 "업무량·소진": ["야근", "업무량", "과중", "번아웃", "휴식", "워라밸", "스트레스",
                "인력부족", "일정", "피로", "여유", "부담"],
}
TNAMES = list(TOPICS)
FRAMES = ["{}이(가) 가장 큰 문제라고 생각합니다.", "{} 부분에서 개선이 필요합니다.",
          "회사가 {}에 더 신경 써 주면 좋겠습니다.", "{} 때문에 고민이 많습니다.",
          "{}에 대한 지원이 부족합니다.", "{} 관련해서 만족스러운 편입니다.",
          "{} 측면은 잘 되어 있다고 봅니다.", "{} 문제가 반복되고 있습니다."]
COMMON = ["회사", "조직", "부서", "우리", "직원", "구성원", "현재", "요즘", "생각", "필요"]

rows = []
for _, r in M.iterrows():
    # 이직의도·직무열의에 따라 토픽 분포를 다르게 (STM 공변량 실습용)
    w = np.array([1.0, 1.0, 1.0, 1.0, 1.0])
    w[4] += 1.7 * max(0, r.TI_TOT - 3)          # 이직의도 높으면 소진 토픽
    w[3] += 1.2 * max(0, r.TI_TOT - 3)          # 보상 토픽
    w[0] += 1.3 * max(0, r.CM_TOT - 3)          # 경력관리행동 높으면 경력 토픽
    w[1] += 1.4 * max(0, r.LS_TOT - 3)          # 학습지원문화 높으면 교육 토픽
    w[2] += 1.1 * max(0, r.WE_TOT - 3)
    w = w / w.sum()
    k = RNG.choice([1, 1, 2, 2, 2, 3])           # 응답당 토픽 1~3개
    picks = RNG.choice(5, size=k, replace=False, p=w)
    sents = []
    for t in picks:
        words = list(RNG.choice(TOPICS[TNAMES[t]], size=RNG.integers(2, 5), replace=False))
        sents.append(RNG.choice(FRAMES).format(" ".join(words)))
    if RNG.random() < .45:
        sents.insert(0, f"{RNG.choice(COMMON)} 차원에서 볼 때,")
    txt = " ".join(sents)
    if RNG.random() < .07: txt = ""              # 무응답 7%
    elif RNG.random() < .05: txt = "없음"         # 무의미 응답 5%
    rows.append(dict(rid=r.rid, org_id=r.org_id, sex=r.sex, age=r.age,
                     tenure_yr=r.tenure_yr, TI_TOT=round(r.TI_TOT,3),
                     WE_TOT=round(r.WE_TOT,3), LS_TOT=round(r.LS_TOT,3),
                     CM_TOT=round(r.CM_TOT,3),
                     q_open="우리 회사의 인재개발에서 개선이 필요한 점은 무엇입니까?",
                     answer=txt, dominant_topic_true=TNAMES[picks[0]]))
TX = pd.DataFrame(rows)
TX.to_csv(f"{D}/E1d_text_openended.csv", index=False, encoding="utf-8-sig")
print(f"자유응답 {len(TX)}건 · 무응답 {(TX.answer.fillna('')=='').mean()*100:.1f}%")
print(TX.dominant_topic_true.value_counts().to_dict())
