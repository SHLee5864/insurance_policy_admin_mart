-- stg_policies.sql
{{
    config(
        materialized='view'
    )
}}

select
    policy_id,
    insured_id,
    product_id,
    status,
    cast(effective_date as date) as effective_date,
    cast(expiry_date as date) as expiry_date,
    cast(updated_at as timestamp) as updated_at
from {{ ref('policies') }}