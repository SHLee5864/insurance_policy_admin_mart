with portfolio as (
    select
        policy_id,
        product_id,
        insured_gender,
        insured_region,
        insured_age_group
    from {{ ref('int_policy_portfolio') }}
),

premiums as (
    select
        policy_id,
        premium_year as year,
        premium_month as month,
        sum(premium_amount) as premium_amount
    from {{ ref('int_policy_premiums') }}
    group by 1,2,3
),

claims as (
    select
        policy_id,
        claim_year as year,
        claim_month as month,
        sum(claim_amount) as claim_amount,
        count(*) as claim_count
    from {{ ref('int_policy_claims') }}
    group by 1,2,3
),

joined as (
    select
        -- dimension keys
        p.product_id,
        p.insured_gender,
        p.insured_region,
        p.insured_age_group,

        -- time
        pr.year,
        pr.month,

        -- policy count = 해당 연/월에 보험료가 존재한 계약 수
        count(distinct pr.policy_id) as policy_count,

        -- raw agg
        sum(pr.premium_amount) as total_premium,
        sum(coalesce(c.claim_amount, 0)) as total_claim,
        sum(coalesce(c.claim_count, 0)) as claim_count

    from premiums pr
    left join portfolio p using (policy_id)
    left join claims c
        on pr.policy_id = c.policy_id
       and pr.year = c.year
       and pr.month = c.month

    group by 1,2,3,4,5,6
)

select
    *,
    total_claim / nullif(total_premium, 0) as loss_ratio,
    claim_count / nullif(policy_count, 0) as frequency,
    total_claim / nullif(claim_count, 0) as severity,
    total_premium / nullif(policy_count, 0) as premium_per_policy,
    total_claim / nullif(policy_count, 0) as claim_per_policy
from joined
