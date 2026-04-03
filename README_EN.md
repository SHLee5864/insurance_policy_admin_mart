# 📌 Insurance Policy Admin Mart — dbt Project

This dbt project builds an **analytical data mart** for insurance policy administration.  
The architecture follows a modular and scalable approach: **RAW → STAGING → INTERMEDIATE → MART**,  
with strong emphasis on data quality, traceability, and business logic consistency.

---

## 🧱 Project Goals

- Centralize data across policies, insureds, products, coverages, premiums, and claims  
- Provide a reliable analytical foundation for key insurance KPIs (loss ratio, frequency, severity, coverage metrics)  
- Build an extensible architecture for advanced use cases such as **IFRS17**, client segmentation, and portfolio analysis  
- Demonstrate layered data modeling aligned with dbt best practices  

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Transformation | dbt Core |
| Database | DuckDB |
| Packages | dbt-utils 1.2.0 |
| Source Data | CSV seeds (generated via `generate.py`) |

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
🔵 STAGING — Standardization & Typing
   ├─ stg_policies
   ├─ stg_premiums
   ├─ stg_claims
   ├─ stg_insureds
   ├─ stg_coverages
   ├─ stg_products
   └─ stg_policy_status_history
        │
        ▼
🟣 INTERMEDIATE — Business Logic
   ├─ int_policy_status_history
   ├─ int_policy_latest
   ├─ int_policy_premiums
   ├─ int_policy_claims
   ├─ int_policy_coverages
   └─ int_policy_portfolio
        │
        ▼
🟠 MART — Analytical KPIs & Dimensions
   ├─ mrt_policy_portfolio_summary
   ├─ mrt_policy_coverage_summary
   ├─ mrt_policy_status_timeline
   ├─ dim_coverage
   └─ dim_product
```

---

## 📂 Project Structure

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

## 🔹 Layer Details

### RAW (Seeds)

Raw source data as CSV files, generated via `generate.py`.  
In production: connectors to policy admin, claims, and billing systems.

### STAGING — Standardization & Typing

Purpose: clean, normalize, and type the raw data.

| Model | Grain |
|-------|-------|
| `stg_policies` | 1 row = 1 policy |
| `stg_insureds` | 1 row = 1 insured |
| `stg_premiums` | 1 row = 1 premium |
| `stg_claims` | 1 row = 1 claim |
| `stg_coverages` | 1 row = 1 coverage |
| `stg_products` | 1 row = 1 product |
| `stg_policy_status_history` | 1 row = 1 status change |

Key actions: date casting, status harmonization, deduplication, primary key validation.

### INTERMEDIATE — Business Logic

| Model | Purpose | Grain | Design Decision |
|-------|---------|-------|-----------------|
| `int_policy_status_history` | Full status history | 1 row = 1 status period (start → end) | `lead()` to compute `end_date` absent from source |
| `int_policy_latest` | Current status per policy | 1 row = 1 policy | References `stg_policy_status_history` directly — independent from `int_policy_status_history` to minimize dependencies |
| `int_policy_premiums` | Premiums for active contracts | 1 row = 1 active premium | Filtered on `policy_status = 'active'` — intentional scope |
| `int_policy_claims` | Claims for active contracts | 1 row = 1 active claim | Same scope as `int_policy_premiums` |
| `int_policy_coverages` | Coverages per policy | 1 row = 1 coverage per policy | — |
| `int_policy_portfolio` | Policy–insured join + segmentation | 1 row = 1 policy (enriched view) | Static attributes only |

### MART — Analytical KPIs & Dimensions

| Model | Content | Grain |
|-------|---------|-------|
| `mrt_policy_portfolio_summary` | Loss ratio, frequency, severity by product/segment | 1 row = 1 segment / product / period |
| `mrt_policy_coverage_summary` | Coverage analysis by type | 1 row = 1 coverage type / period |
| `mrt_policy_status_timeline` | Status transition tracking | 1 row = 1 status transition |
| `dim_coverage` | Coverage dimension | 1 row = 1 coverage |
| `dim_product` | Product dimension | 1 row = 1 product |

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
└─ stg_policy_status_history ──┬─────┤
                               │     │
                    ┌──────────┘     │
                    │                │
                    ▼                │
   int_policy_status_history         │
          │                          │
          ▼                          │
   mrt_policy_status_timeline        │
                                     │
   stg_policy_status_history ────────┤
                    │                │
                    ▼                │
             int_policy_latest       │
                    │                │
         ┌─────────┼────────┐       │
         ▼         ▼        ▼       ▼
  int_policy   int_policy   int_policy
  _premiums    _claims      _portfolio
         │         │              │
         └────┬────┘              │
              ▼                   ▼
  mrt_policy_portfolio    int_policy_coverages
  _summary                        │
                                  ▼
                       mrt_policy_coverage
                       _summary

  stg_coverages ──► dim_coverage
  stg_products  ──► dim_product
```

---

## 📊 Available KPIs

| KPI | Formula | Source Model |
|-----|---------|-------------|
| Loss Ratio | Total claims / Total premiums | `mrt_policy_portfolio_summary` |
| Frequency | Nb claims / Nb policies | `mrt_policy_portfolio_summary` |
| Severity | Average amount per claim | `mrt_policy_portfolio_summary` |
| Coverage Count | Nb coverages per policy | `mrt_policy_coverage_summary` |

---

## 🧪 Data Quality

### Built-in dbt Tests

- `unique` on primary keys
- `not_null` on critical fields
- `accepted_values` on status fields
- `relationships` across layers

### Custom Tests (Macros)

- `expiry_date_after_effective_date`
- `updated_at_after_effective_date`

### YAML Documentation

Each model is documented with: description, grain, column-level documentation, associated tests, and lineage.

---

## 🗃️ Data Generation

Seed data is generated via `generate.py`:

- ~30–50 active policies per month over 2023–2025
- Monthly premiums for each active policy
- Claims calibrated for a **realistic loss ratio of 85–105%** per product/year
- 10 insurance products (life, accident, health, cancer, disability)
- Status history with active → cancelled transitions
- Multiple coverages per policy depending on product type

---

## ⚠️ Known Limitations

- Source data is based on CSV seeds — in production, a real source system connection would be required
- `updated_at` is typed as `date` in seeds — in production: `timestamp` for intra-day updates
- Status transitions limited to active/cancelled — extensible to suspended, reinstated, expired

---

## 🚀 How to Run

### Prerequisites

- Python 3.8+
- dbt Core with DuckDB adapter
- Install: `pip install dbt-duckdb`

### Configuration

Add a profile in `~/.dbt/profiles.yml`:

```yaml
insurance_policy_admin_mart:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 4
```

### Run the Pipeline

```bash
# Install dbt dependencies
dbt deps

# Load seeds + run models + run tests
dbt build

# Or step by step:
dbt seed          # Load CSVs
dbt run           # Run models
dbt test          # Run tests
```

---

## 👤 Author

Project by **Sukhee Lee**  
Insurance / Reinsurance Data & Analytics Specialist — transitioning into Analytics Engineering.