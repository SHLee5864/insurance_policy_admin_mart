-- stg_claims.sql
{{
    config(
        materialized='view'
    )
}}

select
    claim_id,
    policy_id,
    claim_amount,
    cast(claim_date as date) as claim_date,
    claim_type,
    "status" as claim_status
from {{ ref('claims') }}