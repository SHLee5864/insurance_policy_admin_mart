{{ config(materialized='table') }}

select distinct
    coverage_id,
    coverage_type,
    coverage_limit,
    coverage_deductible
from {{ ref('stg_coverages') }}