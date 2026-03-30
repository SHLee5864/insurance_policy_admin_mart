 -- int_policy_latest.sql
{{
    config(
        materialized='view'
    )
}}
with policy_status_latest as (
    select
        policy_id,
        status as policy_status,
        start_date,
        end_date,
        updated_at,
        row_number() over (partition by policy_id order by updated_at desc) as rn
    from {{ ref('stg_policy_status_history') }}
)
select a.policy_id, b.product_id, b.insured_id, a.policy_status, a.start_date, a.end_date, a.updated_at
from policy_status_latest a
join {{ ref('stg_policies') }} b on a.policy_id = b.policy_id
where a.rn = 1