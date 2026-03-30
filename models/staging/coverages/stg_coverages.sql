-- stg_coverages.sql
{{
    config(
        materialized='view'
    )
}}

select
    policy_id,
    coverage_id,
    coverage_type,
    "limit" as coverage_limit,
    deductible
from {{ ref('coverages') }}