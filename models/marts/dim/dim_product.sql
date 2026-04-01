{{ config(materialized='table') }}

select distinct
    product_id,
    product_name,
    renewal_flag
from {{ ref('stg_products') }}
