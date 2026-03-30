-- stg_policy_status_history.sql
{{
    config(
        materialized='view'
    )
}}

select
    policy_id,
    status,
    cast(start_date as date) as start_date,
    cast(end_date as date) as end_date,
    cast(updated_at as timestamp) as updated_at
from {{ ref('policy_status_history') }}