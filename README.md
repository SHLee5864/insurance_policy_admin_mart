# 📌 Insurance Policy Admin Mart — dbt Project

Ce projet dbt construit un **data mart analytique** dédié à la gestion des polices d'assurance.  
L'architecture suit une approche modulaire et scalable : **RAW → STAGING → INTERMEDIATE → MART**,  
avec un accent fort sur la qualité des données, la traçabilité et la logique métier.

---

## 🧱 Objectifs du projet

- Centraliser les données de polices, assurés, produits, garanties, primes et sinistres  
- Construire une base analytique fiable pour les KPI d'assurance (loss ratio, frequency, severity, couverture)  
- Mettre en place une architecture extensible vers des besoins avancés tels que **IFRS17**, la segmentation client ou l'analyse de portefeuille  
- Démontrer une modélisation en couches conforme aux bonnes pratiques dbt  

---

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|------------|
| Transformation | dbt Core |
| Base de données | DuckDB |
| Packages | dbt-utils 1.2.0 |
| Données sources | CSV seeds (générés via `generate.py`) |

---

## 🏗️ Architecture

```
🌱 RAW (SEEDS)
   ├─ policies.csv
   ├─ premiums.csv
   ├─ claims.csv
   ├─ insureds.csv
   ├─ coverages.csv
   ├─ products.csv
   └─ policy_status_history.csv
        │
        ▼
🔵 STAGING — Normalisation & Typage
   ├─ stg_policies
   ├─ stg_premiums
   ├─ stg_claims
   ├─ stg_insureds
   ├─ stg_coverages
   ├─ stg_products
   └─ stg_policy_status_history
        │
        ▼
🟣 INTERMEDIATE — Logique métier
   ├─ int_policy_status_history
   ├─ int_policy_latest
   ├─ int_policy_premiums
   ├─ int_policy_claims
   ├─ int_policy_coverages
   └─ int_policy_portfolio
        │
        ▼
🟠 MART — KPI analytiques & Dimensions
   ├─ mrt_policy_portfolio_summary
   ├─ mrt_policy_coverage_summary
   ├─ mrt_policy_status_timeline
   ├─ dim_coverage
   └─ dim_product
```

---

## 📂 Structure du projet

```
insurance_policy_admin_mart/
├── models/
│   ├── intermediate/
│   │   └── policy/
│   │       ├── int_policy_claims.sql / .yml
│   │       ├── int_policy_coverages.sql / .yml
│   │       ├── int_policy_latest.sql / .yml
│   │       ├── int_policy_portfolio.sql / .yml
│   │       ├── int_policy_premiums.sql / .yml
│   │       └── int_policy_status_history.sql / .yml
│   ├── marts/
│   │   ├── dim/
│   │   │   ├── dim_coverage.sql
│   │   │   ├── dim_product.sql
│   │   │   └── dimension.yml
│   │   └── policy/
│   │       ├── mrt_policy_portfolio_summary.sql / .yml
│   │       ├── mrt_policy_coverage_summary.sql / .yml
│   │       └── mrt_policy_status_timeline.sql / .yml
│   ├── sources/
│   │   └── source.yml
│   └── staging/
│       ├── claims/
│       ├── coverages/
│       │   ├── stg_coverages.sql / .yml
│       ├── insureds/
│       ├── policies/
│       │   ├── stg_policies.sql / .yml
│       │   ├── stg_policy_status_history.sql / .yml
│       ├── premiums/
│       └── products/
│           ├── stg_products.sql / .yml
├── seeds/
│   ├── claims.csv
│   ├── coverages.csv
│   ├── insureds.csv
│   ├── policies.csv
│   ├── policy_status_history.csv
│   ├── premiums.csv
│   └── products.csv
├── tests/
├── macros/
├── analyses/
├── snapshots/
├── generate.py
├── dbt_project.yml
├── packages.yml
└── README.md
```

---

## 🔹 Détail des couches

### RAW (Seeds)

Sources brutes sous forme de fichiers CSV, générés via `generate.py`.  
En production : connecteurs vers systèmes de gestion (policy admin, claims, billing).

### STAGING — Normalisation & Typage

Objectif : nettoyer, typer et standardiser les données brutes.

| Modèle | Grain |
|--------|-------|
| `stg_policies` | 1 ligne = 1 police |
| `stg_insureds` | 1 ligne = 1 assuré |
| `stg_premiums` | 1 ligne = 1 prime |
| `stg_claims` | 1 ligne = 1 sinistre |
| `stg_coverages` | 1 ligne = 1 garantie |
| `stg_products` | 1 ligne = 1 produit |
| `stg_policy_status_history` | 1 ligne = 1 changement de statut |

Actions réalisées : cast des dates, harmonisation des statuts, suppression des doublons, validation des clés primaires.

### INTERMEDIATE — Logique métier

| Modèle | Rôle | Grain | Décision de conception |
|--------|------|-------|----------------------|
| `int_policy_status_history` | Historique complet des statuts | 1 ligne = 1 période de statut (start → end) | `lead()` pour calculer `end_date` absent dans la source |
| `int_policy_latest` | Statut courant par police | 1 ligne = 1 police | Déduit depuis `int_policy_status_history` via `row_number()` |
| `int_policy_premiums` | Primes des contrats actifs | 1 ligne = 1 prime active | Filtré sur `policy_status = 'active'` — périmètre intentionnel |
| `int_policy_claims` | Sinistres des contrats actifs | 1 ligne = 1 sinistre actif | Même périmètre que `int_policy_premiums` |
| `int_policy_coverages` | Garanties par police | 1 ligne = 1 garantie par police | — |
| `int_policy_portfolio` | Jointure police–assuré + segmentation | 1 ligne = 1 police (vue enrichie) | Attributs statiques uniquement |

### MART — KPI analytiques & Dimensions

| Modèle | Contenu | Grain |
|--------|---------|-------|
| `mrt_policy_portfolio_summary` | Loss ratio, frequency, severity par produit/segment | 1 ligne = 1 segment / produit / période |
| `mrt_policy_coverage_summary` | Analyse des garanties par type | 1 ligne = 1 type de garantie / période |
| `mrt_policy_status_timeline` | Suivi des transitions de statut | 1 ligne = 1 transition de statut |
| `dim_coverage` | Dimension des garanties | 1 ligne = 1 garantie |
| `dim_product` | Dimension des produits | 1 ligne = 1 produit |

---

## 📊 Lineage (DAG)

```
🌱 RAW (seeds)
│
├─ stg_policies ─────────────────────┐
├─ stg_insureds ─────────────────────┤
├─ stg_premiums ──────────┐          │
├─ stg_claims ────────────┤          │
├─ stg_coverages ─────────┤          │
├─ stg_products           │          │
└─ stg_policy_status_history ──┐     │
                               │     │
                               ▼     │
              int_policy_status_history
                               │
                               ▼
                      int_policy_latest
                         │         │
          ┌──────────────┤         ├──────────────┐
          ▼              ▼         ▼              ▼
  int_policy_premiums  int_policy_claims  int_policy_portfolio
          │              │         │              │
          └──────────────┴─────────┘              │
                         │                        │
                         ▼                        ▼
          mrt_policy_portfolio_summary    int_policy_coverages
                                                  │
                                                  ▼
                                   mrt_policy_coverage_summary

  int_policy_status_history ──► mrt_policy_status_timeline

  stg_coverages ──► dim_coverage
  stg_products  ──► dim_product
```

---

## 📊 KPI disponibles

| KPI | Formule | Modèle source |
|-----|---------|---------------|
| Loss Ratio | Total sinistres / Total primes | `mrt_policy_portfolio_summary` |
| Frequency | Nb sinistres / Nb polices | `mrt_policy_portfolio_summary` |
| Severity | Montant moyen par sinistre | `mrt_policy_portfolio_summary` |
| Coverage Count | Nb garanties par police | `mrt_policy_coverage_summary` |

---

## 🧪 Qualité des données

### Tests automatiques dbt

- `unique` sur les clés primaires
- `not_null` sur les champs critiques
- `accepted_values` sur les statuts
- `relationships` entre les couches

### Tests personnalisés (macros)

- `expiry_date_after_effective_date`
- `updated_at_after_effective_date`

### Documentation YAML

Chaque modèle est documenté avec : description, grain, colonnes + tests, dépendances.

---

## 🗃️ Génération des données

Les données seed sont générées via `generate.py` :

- ~30–50 polices actives par mois sur la période 2023–2025
- Primes mensuelles pour chaque police active
- Sinistres calibrés pour un **loss ratio réaliste de 85–105%** par produit/année
- 10 produits d'assurance (vie, accident, santé, cancer, invalidité)
- Historique de statuts avec transitions active → cancelled
- Garanties multiples par police selon le produit

---

## ⚠️ Limites connues

- Données sources basées sur des fichiers CSV (seeds) — en production, connexion à un système source nécessaire
- `updated_at` typé en `date` dans les seeds — en production : `timestamp` pour les mises à jour intra-journalières
- Transitions de statut limitées à active/cancelled — extensible vers suspended, reinstated, expired

---

## 🚀 Exécution

### Prérequis

- Python 3.8+
- dbt Core avec adaptateur DuckDB
- Packages : `pip install dbt-duckdb`

### Configuration

Ajouter un profil dans `~/.dbt/profiles.yml` :

```yaml
insurance_policy_admin_mart:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 4
```

### Lancer le pipeline

```bash
# Installer les dépendances dbt
dbt deps

# Charger les seeds + exécuter les modèles + lancer les tests
dbt build

# Ou étape par étape :
dbt seed          # Charger les CSV
dbt run           # Exécuter les modèles
dbt test          # Lancer les tests
```

---

## 👤 Auteur

Projet réalisé par **Sukhee Lee**  
Insurance / Reinsurance Data & Analytics Specialist — en transition vers Analytics Engineering.