-- stg_insureds.sql
{{
    config(
        materialized='view'
    )
}}

select
    insured_id,
    name,
    gender,
    cast(birth_date as date) as birth_date,
    region
from {{ ref('insureds') }}