-- stg_products.sql
{{
    config(
        materialized='view'
    )
}}

select
    product_id,
    product_name,
    renewal_flag
from {{ ref('products') }}