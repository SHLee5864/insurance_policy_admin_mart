{{ config(materialized='view') }}

select 
    p.policy_id,
    p.product_id,
    s.claim_amount,
    year(s.claim_date) as claim_year,
    month(s.claim_date) as claim_month,
    s.claim_type,
    s.claim_status
from {{ ref('int_policy_latest') }} p
join {{ ref('stg_claims') }} s
    on p.policy_id = s.policy_id
where p.policy_status = 'active'