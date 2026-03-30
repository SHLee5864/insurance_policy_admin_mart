{{ config(materialized='view') }}

with premiums as (
    select
        policy_id,
        sum(premium_amount) as total_premiums
    from {{ ref('int_policy_premiums') }}
    group by policy_id
),

claims as (
    select
        policy_id,
        sum(claim_amount) as total_claims
    from {{ ref('int_policy_claims') }}
    group by policy_id
),

coverages as (
    select
        policy_id,
        count(distinct coverage_id) as coverage_count
    from {{ ref('int_policy_coverages') }}
    group by policy_id
)

select
    p.policy_id,
    p.product_id,
    p.insured_id,
    p.insured_name,
    p.insured_gender,
    p.insured_region,
    p.insured_age_group,

    coalesce(pr.total_premiums, 0) as total_premiums,
    coalesce(cl.total_claims, 0) as total_claims,
    coalesce(cov.coverage_count, 0) as coverage_count

from {{ ref('int_policy_portfolio') }} p
left join premiums pr using (policy_id)
left join claims cl using (policy_id)
left join coverages cov using (policy_id)
