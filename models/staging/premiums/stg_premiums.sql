-- stg_premiums.sql
{{
    config(
        materialized='view'
    )
}}

select
    premium_id,
    policy_id,
    amount,
    cast(payment_date as date) as payment_date,
    payment_method,
    year as active_year
from {{ ref('premiums') }}