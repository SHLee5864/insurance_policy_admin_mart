{{ config(materialized='view') }}

select 
    p.policy_id,
    p.product_id,
    s.amount as premium_amount,
    year(s.payment_date) as premium_year,
    month(s.payment_date) as premium_month,
    s.payment_method
from {{ ref('int_policy_latest') }} p
join {{ ref('stg_premiums') }} s
    on p.policy_id = s.policy_id
where p.policy_status = 'active'