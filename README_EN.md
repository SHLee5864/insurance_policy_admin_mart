📌 Insurance Policy Admin Mart — dbt Project
This dbt project builds an analytical data mart for insurance policy administration.
The architecture follows a modular and scalable approach: RAW → STAGING → INTERMEDIATE → MART,
with strong emphasis on data quality, traceability, and actuarial business logic.

Part 1 of a 3-project series building toward a full IFRS 17 actuarial data platform.
→ Medium: Insurance Claims Loss Development — LDF & Ultimate Loss
→ Large: IFRS 17 Analytics Platform on Azure (in progress)


🎯 Why This Project Exists
Insurance companies need a reliable analytical foundation before they can answer the hard questions — how much will we ultimately pay on open claims? Are our premiums adequate? What does our portfolio look like by product and segment?
This project answers the first layer of those questions: structuring the policy portfolio and computing static KPIs (loss ratio, frequency, severity) that form the input to actuarial reserving workflows.
In an IFRS 17 context, this corresponds to the portfolio grouping and cohort structure required before any BEL or CSM calculation can begin.

🛠️ Tech Stack
ComponentTechnologyTransformationdbt CoreDatabaseDuckDBPackagesdbt-utils 1.2.0Source DataCSV seeds (generated via generate.py)

🏗️ Architecture
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

🔹 Layer Details
RAW (Seeds)
Raw source data as CSV files, generated via generate.py.
In production: connectors to policy admin, claims, and billing systems (Guidewire, Duck Creek, SAP FS-CD).
STAGING — Standardization & Typing
Purpose: clean, normalize, and type the raw data. No business logic at this layer.
ModelGrainstg_policies1 row = 1 policystg_insureds1 row = 1 insuredstg_premiums1 row = 1 premiumstg_claims1 row = 1 claimstg_coverages1 row = 1 coveragestg_products1 row = 1 productstg_policy_status_history1 row = 1 status change
Key actions: date casting, status harmonization, deduplication, primary key validation.
INTERMEDIATE — Business Logic
ModelPurposeGrainDesign Decisionint_policy_status_historyFull status history1 row = 1 status period (start → end)lead() to compute end_date absent from sourceint_policy_latestCurrent status per policy1 row = 1 policyReferences stg_policy_status_history directly — independent from int_policy_status_history to minimize dependenciesint_policy_premiumsPremiums for active contracts1 row = 1 active premiumFiltered on policy_status = 'active' — intentional actuarial scopeint_policy_claimsClaims for active contracts1 row = 1 active claimSame scope as int_policy_premiumsint_policy_coveragesCoverages per policy1 row = 1 coverage per policy—int_policy_portfolioPolicy–insured join + segmentation1 row = 1 policy (enriched view)Static attributes only
MART — Analytical KPIs & Dimensions
ModelContentGrainmrt_policy_portfolio_summaryLoss ratio, frequency, severity by product/segment1 row = 1 segment / product / periodmrt_policy_coverage_summaryCoverage analysis by type1 row = 1 coverage type / periodmrt_policy_status_timelineStatus transition tracking1 row = 1 status transitiondim_coverageCoverage dimension1 row = 1 coveragedim_productProduct dimension1 row = 1 product

📊 Available KPIs
KPIFormulaSource ModelLoss RatioTotal claims / Total premiumsmrt_policy_portfolio_summaryFrequencyNb claims / Nb policiesmrt_policy_portfolio_summarySeverityAverage amount per claimmrt_policy_portfolio_summaryCoverage CountNb coverages per policymrt_policy_coverage_summary

🔗 Connection to IFRS 17
This project lays the analytical groundwork for IFRS 17 workflows:
This projectIFRS 17 relevancemrt_policy_portfolio_summaryPortfolio grouping and earned premium by cohort (§17)mrt_policy_status_timelineContract boundary testing — tracking transitions in/out of scopeLoss Ratio by product/AYInput to Best Estimate Liability (BEL) calibrationCoverage structureBasis for coverage unit identification (CSM amortization)
The Medium project extends this foundation toward loss development triangles, LDF calculation, and Ultimate Loss estimation — the core inputs to BEL for claims (IFRS 17 §40–42).

🧪 Data Quality
Built-in dbt Tests

unique on primary keys
not_null on critical fields
accepted_values on status fields
relationships across layers

Custom Tests (Macros)

expiry_date_after_effective_date
updated_at_after_effective_date

YAML Documentation
Each model is documented with: description, grain, column-level tests, and lineage.

🧱 What I Simplified vs. Real World
This projectProduction realityCSV seedsPolicy admin systems (Guidewire, SAP FS-CD)updated_at typed as datetimestamp for intra-day audit trailactive/cancelled status onlyFull lifecycle: suspended, reinstated, expired, lapsedStatic loss ratioActuarially credible estimates require development triangles → see Medium projectNo cohort-level BELIFRS 17 requires grouping by issue year, profitability, and product

🗃️ Data Generation
Seed data is generated via generate.py:

~30–50 active policies per month over 2023–2025
Monthly premiums for each active policy
Claims calibrated for a realistic loss ratio of 85–105% per product/year
10 insurance products (life, accident, health, cancer, disability)
Status history with active → cancelled transitions
Multiple coverages per policy depending on product type


⚙️ How to Run
bash# Install dbt dependencies
dbt deps

# Load seeds + run models + run tests
dbt build

# Or step by step:
dbt seed     # Load CSVs
dbt run      # Run models
dbt test     # Run tests
profiles.yml (~/.dbt/profiles.yml):
yamlinsurance_policy_admin_mart:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 4

👤 Author
Sukhee Lee — Actuarial Data Analyst | IFRS 17 · dbt · Databricks
Combining actuarial domain expertise with modern data engineering practices
to build reproducible, audit-ready analytical pipelines for insurance reserving.
