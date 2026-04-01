📌 Insurance Policy Admin Mart — Projet dbt

This dbt project builds an analytical data mart for insurance policy administration.  
The architecture follows a modular and scalable approach: **RAW → STAGING → INTERMEDIATE → MART**,  
with strong emphasis on data quality, business logic consistency, and clear lineage.

---

🧱 Objectifs du projet

- Centralize data related to policies, insureds, coverages, premiums, and claims  
- Provide a reliable analytical foundation for key insurance KPIs  
  (loss ratio, frequency, severity, coverage metrics)  
- Prepare an extensible architecture for advanced use cases such as **IFRS17**  
- Demonstrate layered data modeling aligned with dbt best practices

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
Raw source data (CSV seeds in this project).  
In production: connectors to policy admin, claims, and billing systems.

🔹 STAGING — Standardization & Typing  
Purpose: clean, normalize, and type the raw data.

Main models:
- `stg_policies`
- `stg_premiums`
- `stg_claims`
- `stg_insureds`
- `stg_coverages`
- `stg_policy_status_history`

Key actions:
- cast des dates  
- harmonisation des statuts  
- suppression des doublons  
- validation des clés primaires

🔹 INTERMEDIATE — Business Logic Layer

| Model | Purpose | Design Decision |
|--------|------|----------------------|
| int_policy_latest | Statut courant par police | Référence stg directement — indépendant de int_policy_status_history pour minimiser les dépendances |
| int_policy_status_history | Historique complet des statuts | lead() pour calculer end_date absent dans la source |
| int_policy_premiums | Primes des contrats actifs | Filtré sur policy_status = 'active' — périmètre intentionnel |
| int_policy_claims | Sinistres des contrats actifs | Même périmètre que int_policy_premiums |
| int_policy_coverages | Garanties par police | — |
| int_policy_portfolio | Jointure police–assuré + segmentation | Attributs statiques uniquement |
| int_policy_portfolio_enriched | Enrichissement avec agrégats | Primes / sinistres / garanties ajoutés ici pour réutilisation dans mart |

🔹 MART — Analytical KPIs

| Model | Status | Content |
|--------|--------|---------|
| mrt_policy_portfolio_summary | 🔧 En développement | Loss ratio, frequency, severity par produit/segment |
| mrt_policy_coverage_summary | 🔧 En développement | Analyse des garanties |
| mrt_policy_status_timeline | 🔧 En développement | Suivi des transitions de statut |

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

📏 Model Grain

Defining the grain is essential to ensure analytical consistency and reliable aggregations.  
Each model in the project follows a clearly defined grain:

🔹 STAGING
| Model | Grain |
|--------|--------|
| stg_policies | 1 row = 1 policy |
| stg_insureds | 1 row = 1 insured |
| stg_premiums | 1 row = 1 premium |
| stg_claims | 1 row = 1 claim |
| stg_coverages | 1 row = 1 coverage |
| stg_policy_status_history | 1 row = 1 status change |

🔹 INTERMEDIATE
| Model | Grain |
|--------|--------|
| int_policy_status_history | 1 row = 1 status period (start_date → end_date) |
| int_policy_latest | 1 row = 1 policy (current status) |
| int_policy_premiums | 1 row = 1 active premium |
| int_policy_claims | 1 row = 1 active claim |
| int_policy_coverages | 1 row = 1 coverage per policy |
| int_policy_portfolio | 1 row = 1 policy (joined with insured) |
| int_policy_portfolio_enriched | 1 row = 1 policy (with aggregates) |

🔹 MART
| Model | Grain |
|--------|--------|
| mrt_policy_portfolio_summary | 1 row = 1 segment / product / period |
| mrt_policy_coverage_summary | 1 row = 1 coverage type / period |
| mrt_policy_status_timeline | 1 row = 1 status transition |


---

📊 Available KPIs

| KPI | Formula | Source Model |
|-----|---------|---------------|
| Loss Ratio | Claims / Premium | mrt_policy_portfolio_summary |
| Frequency | Nb sinistres / Nb polices | mrt_policy_portfolio_summary |
| Severity | Montant moyen / sinistre | mrt_policy_portfolio_summary |
| Coverage Count | Nb garanties / police | mrt_policy_coverage_summary |

---

🧪 Data Quality Strategy

La qualité des données est assurée via une stratégie de tests complète :

✔ Built-in dbt tests
- `unique` on primary keys  
- `not_null` on critical fields  
- `accepted_values` on status fields  
- `relationships` across layers (when supported)

✔ Custom tests (macros)
- `expiry_date_after_effective_date`  
- `updated_at_after_effective_date`  

✔ YAML Documentation
Each model includes:
- description  
- grain  
- column-level documentation  
- associated tests  
- lineage  

---

⚠️ Known Limitations

- Source data is based on CSV seeds  
  → in production, a real source system connection would be required  
- `updated_at` is typed as `date` in seeds  
  → in production, this should be a `timestamp` to handle intra-day updates  
- MART models are partially implemented (structure ready, logic to be completed)

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

🚀 Exécution

Run the full pipeline:

```bash
dbt build

---

👤 Author
Project created by Seokhee,
Insurance/Reinsurance Data & Analytics Specialist transitioning into Analytics Engineering.