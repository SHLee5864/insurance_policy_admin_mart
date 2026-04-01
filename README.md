📌 Insurance Policy Admin Mart — Projet dbt

Ce projet dbt construit un data mart analytique dédié à la gestion des polices d’assurance.  
L’architecture suit une approche modulaire et scalable : **RAW → STAGING → INTERMEDIATE → MART**,  
avec un accent fort sur la qualité des données, la traçabilité et la logique métier.

---

🧱 Objectifs du projet

- Centraliser les données de polices, assurés, garanties, primes et sinistres  
- Construire une base analytique fiable pour les KPI d’assurance  
  (loss ratio, frequency, severity, couverture)  
- Mettre en place une architecture extensible vers des besoins avancés  
  tels que **IFRS17**, la segmentation client ou l’analyse de portefeuille  
- Démontrer une modélisation en couches conforme aux bonnes pratiques dbt

---

🏗️ Architecture

🌱 RAW (SEEDS)
   ├─ policies.csv
   ├─ premiums.csv
   ├─ claims.csv
   ├─ insureds.csv
   ├─ coverages.csv
   └─ policy_status_history.csv
        │
        ▼
🔵 STAGING — Normalisation & Typage
   ├─ stg_policies
   ├─ stg_premiums
   ├─ stg_claims
   ├─ stg_insureds
   ├─ stg_coverages
   └─ stg_policy_status_history
        │
        ▼
🟣 INTERMEDIATE — Logique métier
   ├─ int_policy_status_history
   ├─ int_policy_latest
   ├─ int_policy_premiums
   ├─ int_policy_claims
   ├─ int_policy_coverages
   ├─ int_policy_portfolio
   └─ int_policy_portfolio_enriched
        │
        ▼
🟠 MART — KPI analytiques
   ├─ mrt_policy_portfolio_summary
   ├─ mrt_policy_coverage_summary
   └─ mrt_policy_status_timeline

🔹 RAW  
Sources brutes (CSV seeds dans ce projet).  
En production : connecteurs vers systèmes de gestion (policy admin, claims, billing).

🔹 STAGING — Normalisation & typage  
Objectif : nettoyer, typer et standardiser les données.

Modèles principaux :
- `stg_policies`
- `stg_premiums`
- `stg_claims`
- `stg_insureds`
- `stg_coverages`
- `stg_policy_status_history`

Actions :
- cast des dates  
- harmonisation des statuts  
- suppression des doublons  
- validation des clés primaires

🔹 INTERMEDIATE — Logique métier

| Modèle | Rôle | Décision de conception |
|--------|------|----------------------|
| int_policy_latest | Statut courant par police | Référence stg directement — indépendant de int_policy_status_history pour minimiser les dépendances |
| int_policy_status_history | Historique complet des statuts | lead() pour calculer end_date absent dans la source |
| int_policy_premiums | Primes des contrats actifs | Filtré sur policy_status = 'active' — périmètre intentionnel |
| int_policy_claims | Sinistres des contrats actifs | Même périmètre que int_policy_premiums |
| int_policy_coverages | Garanties par police | — |
| int_policy_portfolio | Jointure police–assuré + segmentation | Attributs statiques uniquement |
| int_policy_portfolio_enriched | Enrichissement avec agrégats | Primes / sinistres / garanties ajoutés ici pour réutilisation dans mart |

🔹 MART — KPI analytiques

| Modèle | Statut | Contenu |
|--------|--------|---------|
| mrt_policy_portfolio_summary | 🔧 En développement | Loss ratio, frequency, severity par produit/segment |
| mrt_policy_coverage_summary | 🔧 En développement | Analyse des garanties |
| mrt_policy_status_timeline | 🔧 En développement | Suivi des transitions de statut |

---

🌱 RAW
│
├─ stg_policies
├─ stg_insureds
├─ stg_premiums
├─ stg_claims
├─ stg_coverages
└─ stg_policy_status_history
        │
        ▼
🟣 INTERMEDIATE
│
├─ int_policy_status_history ← stg_policy_status_history
├─ int_policy_latest ← int_policy_status_history
├─ int_policy_premiums ← stg_premiums + int_policy_latest
├─ int_policy_claims ← stg_claims + int_policy_latest
├─ int_policy_coverages ← stg_coverages
├─ int_policy_portfolio ← stg_policies + stg_insureds
└─ int_policy_portfolio_enriched
        ← int_policy_portfolio + premiums + claims + coverages
        │
        ▼
🟠 MART
│
├─ mrt_policy_portfolio_summary ← enriched
├─ mrt_policy_coverage_summary ← coverages
└─ mrt_policy_status_timeline ← status_history

---

📏 Grain des modèles

La définition du grain est essentielle pour garantir la cohérence analytique et la qualité des données.  
Chaque modèle du projet respecte un grain clair et documenté :

🔹 STAGING
| Modèle | Grain |
|--------|--------|
| stg_policies | 1 ligne = 1 police |
| stg_insureds | 1 ligne = 1 assuré |
| stg_premiums | 1 ligne = 1 prime |
| stg_claims | 1 ligne = 1 sinistre |
| stg_coverages | 1 ligne = 1 garantie |
| stg_policy_status_history | 1 ligne = 1 changement de statut |

🔹 INTERMEDIATE
| Modèle | Grain |
|--------|--------|
| int_policy_status_history | 1 ligne = 1 période de statut (start_date → end_date) |
| int_policy_latest | 1 ligne = 1 police (statut courant) |
| int_policy_premiums | 1 ligne = 1 prime active |
| int_policy_claims | 1 ligne = 1 sinistre actif |
| int_policy_coverages | 1 ligne = 1 garantie par police |
| int_policy_portfolio | 1 ligne = 1 police (vue enrichie assuré) |
| int_policy_portfolio_enriched | 1 ligne = 1 police (avec agrégats) |

🔹 MART
| Modèle | Grain |
|--------|--------|
| mrt_policy_portfolio_summary | 1 ligne = 1 segment / produit / période |
| mrt_policy_coverage_summary | 1 ligne = 1 type de garantie / période |
| mrt_policy_status_timeline | 1 ligne = 1 transition de statut |

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

La qualité des données est assurée via une stratégie de tests complète :

✔ Tests automatiques dbt
- `unique` sur les clés primaires  
- `not_null` sur les champs critiques  
- `accepted_values` sur les statuts  
- `relationships` entre les couches (lorsque supporté)

✔ Tests personnalisés (macros)
- `expiry_date_after_effective_date`  
- `updated_at_after_effective_date`  

✔ Documentation YAML
Chaque modèle est documenté avec :
- description  
- grain  
- colonnes + tests  
- dépendances  

---

🧑 INSUREDS
   • insured_id (PK)
   • name
   • birth_date
        │ 1:N
        ▼
📄 POLICIES
   • policy_id (PK)
   • insured_id (FK)
   • product_id (FK)
   • effective_date
   • expiry_date
   • status
        │ 1:N
        ▼
💰 PREMIUMS
   • premium_id (PK)
   • policy_id (FK)
   • premium_amount
   • premium_date

        │ 1:N
        ▼
⚠️ CLAIMS
   • claim_id (PK)
   • policy_id (FK)
   • claim_amount
   • claim_date

        │ 1:N
        ▼
📊 POLICY_STATUS_HISTORY
   • policy_id (FK)
   • status
   • start_date
   • end_date (calculated)

---

⚠️ Limites connues

- Données sources basées sur des fichiers CSV (seeds)  
  → en production, une connexion à un système source serait nécessaire  
- `updated_at` typé en `date` dans les seeds  
  → en production : `timestamp` pour gérer les mises à jour intra-journalières  
- Modèles MART encore en développement (structure prête, logique à compléter)

---

🚀 Exécution

Pour exécuter l’ensemble du pipeline :

```bash
dbt build

---

👤 Auteur
Projet réalisé par Seokhee,
Insurance/Reinsurance Data & Analytics Specialist — en transition vers Analytics Engineering.