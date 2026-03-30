{{ config(materialized='view') }}

with base as (
    select 
        p.policy_id,
        p.product_id,
        p.insured_id,
        i.name as insured_name,
        i.gender as insured_gender,
        i.birth_date,
        i.region as insured_region,
        date_diff('year', i.birth_date, current_date) as age
    from {{ ref('int_policy_latest') }} p
    join {{ ref('stg_insureds') }} i
        on p.insured_id = i.insured_id
    where p.policy_status = 'active'
)

select
    policy_id,
    product_id,
    insured_id,
    insured_name,
    insured_gender,
    insured_region,
    case
        when age < 20 then '0-19'
        when age between 20 and 29 then '20-29'
        when age between 30 and 39 then '30-39'
        when age between 40 and 49 then '40-49'
        when age between 50 and 59 then '50-59'
        when age >= 60 then '60+'
    end as insured_age_group
from base
