 -- int_policy_status_history.sql
{{
    config(
        materialized='view'
    )
}}
with ordered as (
    select
        policy_id,
        status as policy_status,
        start_date,
        end_date,
        updated_at,
        lead(start_date) over (partition by policy_id order by start_date asc) as next_start_date
    from {{ ref('stg_policy_status_history') }}
)
select policy_id, policy_status, start_date
    , case when next_start_date is null then null
           else next_start_date - interval '1 day' end as end_date, updated_at
from ordered