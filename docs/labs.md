# R 실습 키트

기법 16종 × 주석 달린 R 스크립트 × 예제 CSV. 슬라이드의 실습 코드가 모두 여기 있습니다.

## 실행

```r
setwd("~/hrd-research-methods")   # 저장소 루트
source("labs/R/00_setup.R")       # 패키지 자동 설치 + 데이터 경로 탐지
source("labs/R/11_multilevel_hlm.R")
```

`00_setup.R`은 `labs/data`, `data`, `../data` 순으로 데이터 폴더를 찾으므로
저장소 루트에서 실행하든 `labs/`에서 실행하든 동작합니다.

## 공통 함수

`00_setup.R`이 제공합니다.

| 함수 | 하는 일 |
|---|---|
| `rd("파일명.csv")` | 데이터 읽기 |
| `sk(d)` | 기술통계 + 왜도·첨도 |
| `rel(d)` | α와 ω를 나란히 |
| `harman(d)` | 공통방법편의 Harman 단일요인 검정 |
| `icc_set(y, grp)` | ICC(1), ICC(2), 평균 집단크기 |
| `f2(full, reduced)` | 효과크기 f² |
| `fit3(fit)` | 적합도 세트 (χ², CFI, TLI, RMSEA+CI, SRMR) |

## 파일 대응

### 본 과정

| # | 기법 | R | 데이터 | 심어둔 참값 |
|---|---|---|---|---|
| 01 | 다중회귀 | `01_regression.R` | `01_regression.csv` | R²≈.34 |
| 02 | 위계적회귀 | `02_hierarchical_regression.R` | `02_*.csv` | ΔR² .086/.214 |
| 03 | 매개 | `03_mediation.R` | `03_mediation.csv` | ab=.334 |
| 04 | 조절 | `04_moderation.R` | `04_moderation.csv` | b=.51, ΔR²=.037 |
| 05 | 조절된매개 | `05_conditional_process.R` | `05_*.csv` | **IMM=−.207** |
| 06 | 직렬매개 | `06_serial_mediation.R` | `06_*.csv` | ind₃=.136 |
| 07 | 로지스틱 | `07_logistic.R` | `07_logistic.csv` | AUC=.76 |
| 08 | LPA/LCA | `08_latent_profile.R` | `08_*.csv` | **4계층** Entropy .79 |
| 09 | 생존분석 | `09_survival.R` | `09_survival.csv` | HR .51/1.65 |
| 10 | ARCL/CLPM | `10_arcl_clpm.R` | `10_*.csv` | 비대칭 CL |
| 11 | 다층 HLM | `11_multilevel_hlm.R` | `11_*.csv` + `11b_*.csv` | ICC .10~.24 |
| 12 | CB-SEM | `12_cbsem.R` | `12_cbsem_items.csv` | 요인내/요인간 r=2.18 |
| 13 | PLS-SEM | `13_plssem.R` | `13_plssem_items.csv` | two-stage 2차요인 |
| 14 | MSEM·종단 | `14_msem_longitudinal_dsem.R` | `14_*.csv` + `14b_*.csv` | 롱폼 1,299행 |

### 확장 트랙 E1

| 기법 | R | 데이터 |
|---|---|---|
| 네트워크·MR-QAP | `E1_network.R` | `E1a_nodes` · `E1b_edges` · `E1c_matrix_*` |
| 텍스트마이닝·LDA·STM | `E1_textmining.R` | `E1d_text_openended.csv` |

## 데이터 재생성·변형

```bash
cd labs
pip install pandas numpy
python3 gen_master.py        # 시드 20260724 · 마스터 468명
python3 split_csv.py         # 기법별 CSV 분할
python3 gen_network_text.py  # 네트워크·텍스트 (마스터와 정합)
```

효과 크기를 바꾸려면 `gen_master.py`의 **4. 잠재변인 구조방정식** 블록의 계수만
수정하면 됩니다. 예: 매개효과를 키우려면 `PC_t = .52*SC_t`의 계수를 올립니다.

## 변수 규칙

- **문항** `구인_하위요인_번호` — 예: `SC_SK_01`
- **역문항** 끝에 `R` — 예: `SC_SJ_01R`. 응답 원점수 그대로 저장되어 있으므로
  분석 전 `d[rev] <- 6 - d[rev]`로 역채점합니다.
- **하위요인 평균** `하위요인_m` · **구인 총점** `구인_TOT` (둘 다 역채점 반영됨)
- **종단** `W{1,2,3}_{SC,WE,TI}_p{1,2,3}`

전체 목록은 `labs/data/00_codebook_variables.csv`와 `00_codebook_items.csv`에 있습니다.

!!! note "심화 실습"
    Mplus 문법(HLM·XWITH·BCH·R3STEP), RSiena, BERTopic·STM의 상세 절차는 [교재 연계 지도](sources.md)의 심화 경로 대응표를 참조하십시오.
