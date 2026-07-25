# 통계지표 계보도

58개 통계지표를 **무엇을 하려는 도구인가**로 묶은 인터랙티브 벤다이어그램입니다.
배지를 누르면 뜻·수식·쓰는 순간·심사 포인트가 열립니다.

<div class="genealogy-frame">
  <iframe data-genealogy title="통계지표 계보도" loading="lazy"></iframe>
</div>

<a class="md-button md-button--primary" data-genealogy-link target="_blank">전체 화면으로 열기 →</a>

<script>
(function(){
  // 페이지 depth에 무관하게 site root 기준 절대경로로 iframe·링크 연결
  var base = document.querySelector('link[rel="canonical"]');
  var root = "";
  var el = document.querySelector('[data-genealogy]');
  var lk = document.querySelector('[data-genealogy-link]');
  var url = (window.location.pathname.replace(/genealogy\/.*$/, '')) + "interactive/stat-genealogy.html";
  if(el) el.src = url;
  if(lk) lk.href = url;
})();
</script>

---

## 다섯 개의 원

| 원 | 묻는 것 | 대표 지표 |
|---|---|---|
| 관계·연관 | 얼마나 같이 움직이나 | r · ρ · τ · 편상관 · Cramér's V |
| 차이·비교 | 집단이 정말 다른가 | t · F · χ² · Cohen's d · η² |
| 예측·설명 | 무엇이 무엇을 만드나 | B · β · R² · ΔR² · OR · HR |
| 측정·구조 | 제대로 재고 있나 | α · ω · λ · AVE · CFI · RMSEA |
| 위계·다층 | 어느 층의 이야기인가 | ICC · τ₀₀ · τ₁₁ · γ · r_wg |

정중앙에는 **일반선형모형(GLM)** 이 있습니다. 상관·t검정·ANOVA·회귀는 모두
`Y = Xβ + ε` 하나에서 갈라져 나온 변형입니다.

자세한 해설은 [M3 · 통계지표 계보도](m3.md)에서 다룹니다.
