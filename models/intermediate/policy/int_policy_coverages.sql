{{ config(materialized='view') }}

with active_policies as (
    select *
    from {{ ref('int_policy_latest') }}
    where policy_status = 'active'
),
coverages as (
    select *
    from {{ ref('stg_coverages') }}
)

select
    p.policy_id,
    p.product_id,
    c.coverage_id,
    c.coverage_type,
    c.coverage_limit,
    c.deductible
from active_policies p
left join coverages c on p.policy_id = c.policy_id
