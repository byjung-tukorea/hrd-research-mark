<div align="center">

# 산업인력개발학(HRD ) 연구초심자를 위한 연구방법론 특강

**MkDocs Material로 빌드되는 웹 교재** · 8시간 과정 · 14개 모듈 71주제 · R 실습 17종 · 예제 데이터 26개 · 인터랙티브 통계지표 계보도

한국공학대학교 산업인력개발학 · 정보영

**[📖 교재 사이트 열기](https://byjung-tukorea.github.io/hrd-research-methods/)**

</div>

---

## 이것은 무엇인가

마크다운으로 작성된 연구방법론 교재입니다. GitHub에 올리면 **GitHub Actions가
자동으로 웹사이트로 빌드**합니다 — 왼쪽 목차, 상단 탭, 전문 검색, 페이지 넘김,
다크모드, 모바일 대응이 모두 됩니다.

`docs/` 안의 `.md` 파일을 고치고 푸시하기만 하면 사이트가 다시 배포됩니다.

## 구성

```
hrd-research-methods/
├─ mkdocs.yml              사이트 설정 (테마·목차·확장)
├─ docs/
│   ├─ index.md            홈
│   ├─ m0.md ~ m9.md       본 과정 10개 모듈
│   ├─ e1.md ~ e4.md       확장 트랙 4개
│   ├─ genealogy.md        통계지표 계보도 (인터랙티브 임베드)
│   ├─ labs.md             R 실습 안내
│   ├─ handouts/           유인물 6종 (워크시트·체크리스트·용어사전·심사질문·치트시트)
│   ├─ sources.md          교재 연계 지도
│   ├─ interactive/        계보도 HTML (정적 임베드)
│   ├─ labs/               R 스크립트 17개 + 예제 CSV 26개 + 생성기
│   └─ stylesheets/        커스텀 CSS (콘크리트 브루탈리즘 팔레트)
├─ .github/workflows/      자동 배포 워크플로
├─ requirements.txt        mkdocs-material
├─ LICENSE                 코드 MIT
└─ LICENSE-CONTENT         강의자료 CC BY-NC-SA 4.0
```

## 커리큘럼

**본 과정 (8시간)** — M0 통계 문해 · M1 패러다임과 설계 · M2 측정 ·
M3 계보도 · M4 자료의 품질 · M5 관계·차이·예측 · M6 매개·조절 ·
M7 SEM과 다층 · M8 유형·종단·시간 · M9 의사결정과 쓰기

**확장 트랙** — E1 네트워크·텍스트마이닝 · E2 AI 활용·자료관리 ·
E3 질적·혼합연구 · E4 지식통합·응용연구

## 로컬에서 미리보기

```bash
pip install mkdocs-material
mkdocs serve       # http://127.0.0.1:8000 에서 실시간 미리보기
```

내용을 고치면 브라우저가 자동으로 새로고침됩니다.

## GitHub에 올리고 배포하기

[**SETUP_GITHUB.md**](SETUP_GITHUB.md)에 단계별 명령이 있습니다. 요약하면:

1. GitHub에서 빈 저장소 `hrd-research-methods` 생성 (Public)
2. `git init && git add . && git commit && git push`
3. Settings → Pages → Source를 **GitHub Actions**로
4. 1~2분 후 `https://<계정>.github.io/hrd-research-methods/` 에서 열림

## 기존 교재와의 연계

이 강의는 네 개의 기존 자료를 읽고 그 위에 설계되었습니다.
각 페이지의 **읽기 · 심화 경로** 상자가 해당 자료로 이어집니다.

| 코드 | 자료 | 역할 |
|---|---|---|
| S1 | 멘토링 통합교재 (정보영) | 심화 학습 경로 |
| S2 | 박사과정생 양적연구방법론 (정보영) | 심화 학습 경로 |
| S3 | HRD 총서 6 (김태성 외, 2024, 박영스토리) | 쪽수를 명시한 읽기 과제 |
| S4 | LG인화원 HR Analytics 통계기본역량 | 3단 분해 프레임의 원출처 |

전체 매핑은 [`docs/sources.md`](docs/sources.md) 참조. `docs/*.md`의 본문은 전부
강의자가 작성한 독립 콘텐츠이며, S3의 문장·표·그림이나 S4의 슬라이드는 옮기지 않았습니다.

## 라이선스

| 대상 | 라이선스 |
|---|---|
| 강의자료 (`docs/*.md`, 유인물, 계보도) | [CC BY-NC-SA 4.0](LICENSE-CONTENT) |
| 코드·데이터 생성기 (`docs/labs/`) | [MIT](LICENSE) |

**정보영** · 한국공학대학교 산업인력개발학 · byjung@tukorea.ac.kr
