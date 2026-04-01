{{
    config(
        materialized='table'
    )
}}

with portfolio as (
    select
        policy_id,
        product_id,
        insured_gender,
        insured_region,
        insured_age_group
    from {{ ref('int_policy_portfolio') }}
),

coverages as (
    select
        policy_id,
        coverage_id,
        coverage_type,
        coverage_limit,
        deductible as coverage_deductible
    from {{ ref('int_policy_coverages') }}
)

select
    c.policy_id,
    c.coverage_id,
    c.coverage_type,
    c.coverage_limit,
    c.coverage_deductible,

    p.product_id,
    p.insured_gender,
    p.insured_region,
    p.insured_age_group

from coverages c
left join portfolio p using (policy_id)
