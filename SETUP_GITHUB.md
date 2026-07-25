# GitHub 업로드 · 배포 안내

이 교재는 **로컬 파일로 완성**되어 있습니다. 아래대로 하면 본인 계정에서
웹 교재로 자동 배포됩니다.

---

## 1. GitHub에서 빈 저장소 만들기

1. <https://github.com/new> 접속
2. **Repository name**: `hrd-research-methods`
3. **Public** 선택 (GitHub Pages 무료 사용)
4. **README·.gitignore·license 체크하지 마세요** — 이미 포함되어 있습니다
5. **Create repository**

---

## 2. 로컬에서 푸시

압축을 푼 폴더에서 터미널을 열고:

```bash
cd hrd-research-methods

git init
git add .
git commit -m "HRD 연구방법론 특강 웹 교재 · 초판"

# 계정명을 본인 것으로 바꾸세요
git remote add origin https://github.com/<계정명>/hrd-research-methods.git
git branch -M main
git push -u origin main
```

작성자 정보가 없다면 먼저:

```bash
git config --global user.name "정보영"
git config --global user.email "byjung@tukorea.ac.kr"
```

---

## 3. GitHub Pages 켜기 ★ 가장 중요

1. 저장소 → **Settings** → 왼쪽 **Pages**
2. **Source**: `GitHub Actions` 선택 ← **꼭 이걸로**
3. 저장하면 `.github/workflows/deploy.yml`이 자동 실행됩니다
4. 상단 **Actions** 탭에서 초록 체크가 뜨면 완료
5. 다음 주소에서 열립니다

```
https://<계정명>.github.io/hrd-research-methods/
```

> **"Deploy from a branch"를 고르면 안 됩니다.** 이 교재는 MkDocs로 빌드해야
> 하므로 반드시 `GitHub Actions`여야 합니다. 워크플로가 mkdocs-material을 설치해
> 사이트를 만들고 배포합니다.

---

## 4. 주소·링크의 계정명 바꾸기

`mkdocs.yml`과 `README.md`에 계정명이 `byjung-tukorea`로 들어가 있습니다.
실제 계정이 다르면 일괄 치환하세요.

```bash
# macOS
sed -i '' 's/byjung-tukorea/<실제계정명>/g' mkdocs.yml README.md

# Linux
sed -i 's/byjung-tukorea/<실제계정명>/g' mkdocs.yml README.md
```

`mkdocs.yml`의 `site_url`과 `repo_url`이 맞아야 검색·편집 링크가 정상 작동합니다.

---

## 5. 이후 수정과 반영

```bash
# docs/ 안의 .md를 고친 뒤
git add .
git commit -m "M5 회귀 진단 보완"
git push
```

푸시할 때마다 Actions가 자동으로 다시 빌드·배포합니다. 1~2분이면 반영됩니다.

로컬에서 미리 보려면:

```bash
pip install mkdocs-material
mkdocs serve        # http://127.0.0.1:8000
```

---

## 6. 기존 교재 원본을 넣을 때

`.gitignore`가 `*.pdf *.pptx *.hwp *.hwpx`를 자동 제외합니다.
즉 원본을 폴더에 두어도 Git에는 올라가지 않습니다.

- 공개해도 되는 자료라면 `.gitignore`에서 해당 확장자 줄을 지우세요.
- **S3 학술총서**는 제3자 저작물, **S4 LG인화원 자료**는 위탁 산출물이므로
  공개 전 저작권·계약을 확인하세요. 자세한 원칙은 `docs/sources.md` 참조.

---

## 7. 저장소 설정 권장

**Settings → General → Features**
- Issues 켜기 (오류 제보용)

**About (첫 화면 오른쪽 톱니)**
- Description: `HRD 연구초심자를 위한 8시간 연구방법론 웹 교재`
- Website: Pages 주소
- Topics: `hrd` `research-methods` `statistics` `r` `sem` `multilevel` `mkdocs` `korean`

**Settings → Actions → General → Workflow permissions**
- 배포가 실패하면 `Read and write permissions`로 변경

---

## 문제 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| Actions 실패 (빨간 X) | 권한 부족 | Settings→Actions→Workflow permissions를 Read and write |
| Pages 404 | Source가 branch | Settings→Pages→Source를 GitHub Actions로 |
| 계보도가 안 뜸 | 경로 문제 | `docs/interactive/stat-genealogy.html`이 푸시됐는지 확인 |
| 검색이 한글을 못 찾음 | 인덱스 | 정상입니다. lunr 한국어 인덱스가 자동 포함됨 |
| 편집 링크가 404 | repo_url 불일치 | mkdocs.yml의 repo_url을 실제 저장소로 |
| 로컬 빌드 실패 | 패키지 없음 | `pip install mkdocs-material` |
