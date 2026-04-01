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
        insured_age_group,
        policy_status
    from {{ ref('int_policy_portfolio') }}
),

calendar as (
    -- premiums와 claims의 union으로 월별 timeline 생성
    select distinct policy_id, premium_year as year, premium_month as month
    from {{ ref('int_policy_premiums') }}
    union
    select distinct policy_id, claim_year as year, claim_month as month
    from {{ ref('int_policy_claims') }}
)

select
    cal.policy_id,
    cal.year,
    cal.month,

    p.product_id,
    p.insured_gender,
    p.insured_region,
    p.insured_age_group,

    p.policy_status

from calendar cal
left join portfolio p using (policy_id)
