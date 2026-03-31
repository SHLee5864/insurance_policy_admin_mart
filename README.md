📌 Insurance Policy Admin Mart — Projet dbt

Ce projet dbt construit un data mart analytique pour la gestion 
des polices d'assurance, en s'appuyant sur une architecture 
modulaire RAW → STAGING → INTERMEDIATE → MART.

---

🧱 Objectifs

- Centraliser les données de polices, primes, sinistres, 
  assurés et garanties
- Fournir une base fiable pour les KPI d'assurance 
  (loss ratio, frequency, severity)
- Préparer une architecture extensible vers IFRS17

---

🏗️ Architecture

RAW → STAGING → INTERMEDIATE → MART

**STAGING** — Normalisation, typage, nettoyage
- stg_policies / stg_premiums / stg_claims
- stg_insureds / stg_coverages / stg_policy_status_history

**INTERMEDIATE** — Logique métier

| Modèle | Rôle | Décision de conception |
|--------|------|----------------------|
| int_policy_latest | Statut courant par police | Référence stg directement — indépendant de int_policy_status_history pour minimiser les dépendances |
| int_policy_status_history | Historique complet des statuts | lead() pour calculer end_date absent dans la source |
| int_policy_premiums | Primes des contrats actifs | Filtré sur policy_status = 'active' — périmètre intentionnel |
| int_policy_claims | Sinistres des contrats actifs | Même périmètre que int_policy_premiums |
| int_policy_coverages | Garanties par police | — |
| int_policy_portfolio | Jointure police–assuré + segmentation | Attributs statiques uniquement |
| int_policy_portfolio_enriched | Enrichissement avec agrégats | Primes / sinistres / garanties ajoutés ici pour réutilisation dans mart |

**MART** — KPI analytiques

| Modèle | Statut | Contenu |
|--------|--------|---------|
| mrt_policy_portfolio_summary | 🔧 En développement | Loss ratio, frequency, severity par produit/segment |
| mrt_policy_coverage_summary | 🔧 En développement | Analyse des garanties |
| mrt_policy_status_timeline | 🔧 En développement | Suivi des transitions de statut |

---

📊 KPI disponibles

| KPI | Formule | Modèle source |
|-----|---------|---------------|
| Loss Ratio | Claims / Premium | mrt_policy_portfolio_summary |
| Frequency | Nb sinistres / Nb polices | mrt_policy_portfolio_summary |
| Severity | Montant moyen / sinistre | mrt_policy_portfolio_summary |
| Coverage Count | Nb garanties / police | mrt_policy_coverage_summary |

---

🧪 Qualité des données

- Tests not_null / unique sur tous les modèles
- Tests de relation entre couches
- Documentation YAML complète

---

⚠️ Limites connues

- Données sources : fichiers CSV (seed) — pas de connexion 
  à un système source réel
- updated_at en type date : en production, ce serait un 
  timestamp (élimine les doublons intra-journaliers)
- mrt_policy_status_timeline : en cours de développement

---

🚀 Exécution

dbt build

---

🇬🇧 English version

**Insurance Policy Admin Mart (dbt)**

A dbt project building an analytical data mart for insurance 
policy management.

**Architecture**: RAW → STAGING → INTERMEDIATE → MART

**Key design decisions**
- `int_policy_latest` references staging directly to avoid 
  dependency on `int_policy_status_history` — two models, 
  two distinct purposes
- Premium and claim models intentionally filter on 
  `active` status — scope is current portfolio analysis
- `int_policy_portfolio_enriched` separates static attributes 
  (portfolio) from aggregated metrics (enriched) for mart reuse

**KPIs**: Loss ratio · Frequency · Severity · Coverage count

**Known limitations**
- Seed CSV data (no live source connection)
- `updated_at` is date type — production would use timestamp
- `mrt_policy_status_timeline` in progress

dbt build

---

🇰🇷 한국어

**보험 Policy Admin Mart (dbt)**

보험 계약 데이터를 기반으로 분석용 데이터 마트를 구축하는 
dbt 프로젝트.

**핵심 설계 결정**
- `int_policy_latest`는 stg 직접 참조 — `int_policy_status_history`와 
  의존성을 의도적으로 분리
- 보험료/청구 모델은 `active` 계약만 필터링 — 현재 포트폴리오 
  분석이 목적
- `enriched` 레이어에서 집계 지표 분리 — mart 재사용성 확보

**KPI**: 손해율 · 빈도 · 심도 · 담보 개수

**한계점**
- seed CSV 데이터 (실제 소스 연결 없음)
- `updated_at` date 타입 — 실무에서는 timestamp
- `mrt_policy_status_timeline` 개발 예정

dbt build