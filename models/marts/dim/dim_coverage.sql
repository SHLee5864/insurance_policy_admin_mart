{{ config(materialized='table') }}

select distinct
    coverage_id,
    coverage_type,
    coverage_limit,
    deductible as coverage_deductible
from {{ ref('stg_coverages') }}