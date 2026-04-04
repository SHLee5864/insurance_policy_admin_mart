# 📌 Insurance Policy Admin Mart — dbt Project

This dbt project builds an **analytical data mart** for insurance policy administration.  
The architecture follows a modular and scalable approach: **RAW → STAGING → INTERMEDIATE → MART**,  
with strong emphasis on data quality, traceability, and actuarial business logic.

> **Part 1 of a 3-project series** building toward a full IFRS 17 actuarial data platform.  
> → **Medium:** [Insurance Claims Loss Development — LDF & Ultimate Loss](https://github.com/SHLee5864/insurance-claims-loss-development-dbt)  
> → **Large:** IFRS 17 Analytics Platform on Azure *(in progress)*

---

## 🎯 Why This Project Exists

Insurance companies need a reliable analytical foundation before they can answer the hard questions — how much will we ultimately pay on open claims? Are our premiums adequate? What does our portfolio look like by product and segment?

This project answers the first layer of those questions: **structuring the policy portfolio and computing static KPIs** (loss ratio, frequency, severity) that form the input to actuarial reserving workflows.

In an IFRS 17 context, this corresponds to the **portfolio grouping and cohort structure** required before any BEL or CSM calculation can begin.

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

## 🔹 Layer Details

### RAW (Seeds)

Raw source data as CSV files, generated via `generate.py`.  
In production: connectors to policy admin, claims, and billing systems (Guidewire, Duck Creek, SAP FS-CD).

### STAGING — Standardization & Typing

Purpose: clean, normalize, and type the raw data. No business logic at this layer.

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
| `int_policy_premiums` | Premiums for active contracts | 1 row = 1 active premium | Filtered on `policy_status = 'active'` — intentional actuarial scope |
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

## 📊 Available KPIs

| KPI | Formula | Source Model |
|-----|---------|-------------|
| Loss Ratio | Total claims / Total premiums | `mrt_policy_portfolio_summary` |
| Frequency | Nb claims / Nb policies | `mrt_policy_portfolio_summary` |
| Severity | Average amount per claim | `mrt_policy_portfolio_summary` |
| Coverage Count | Nb coverages per policy | `mrt_policy_coverage_summary` |

---

## 🔗 Connection to IFRS 17

This project lays the analytical groundwork for IFRS 17 workflows:

| This project | IFRS 17 relevance |
|---|---|
| `mrt_policy_portfolio_summary` | Portfolio grouping and earned premium by cohort (§17) |
| `mrt_policy_status_timeline` | Contract boundary testing — tracking transitions in/out of scope |
| Loss Ratio by product/AY | Input to Best Estimate Liability (BEL) calibration |
| Coverage structure | Basis for coverage unit identification (CSM amortization) |

The **Medium project** extends this foundation toward loss development triangles, LDF calculation, and Ultimate Loss estimation — the core inputs to BEL for claims (IFRS 17 §40–42).

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

Each model is documented with: description, grain, column-level tests, and lineage.

---

## 🧱 What I Simplified vs. Real World

| This project | Production reality |
|---|---|
| CSV seeds | Policy admin systems (Guidewire, SAP FS-CD) |
| `updated_at` typed as `date` | `timestamp` for intra-day audit trail |
| active/cancelled status only | Full lifecycle: suspended, reinstated, expired, lapsed |
| Static loss ratio | Actuarially credible estimates require development triangles → see Medium project |
| No cohort-level BEL | IFRS 17 requires grouping by issue year, profitability, and product |

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

## ⚙️ How to Run

```bash
# Install dbt dependencies
dbt deps

# Load seeds + run models + run tests
dbt build

# Or step by step:
dbt seed     # Load CSVs
dbt run      # Run models
dbt test     # Run tests
```

`profiles.yml` (`~/.dbt/profiles.yml`):

```yaml
insurance_policy_admin_mart:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 4
```

---

## 👤 Author

**Sukhee Lee** — Actuarial Data Analyst | IFRS 17 · dbt · Databricks  
Combining actuarial domain expertise with modern data engineering practices  
to build reproducible, audit-ready analytical pipelines for insurance reserving.
