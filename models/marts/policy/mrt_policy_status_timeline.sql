with portfolio as (
    select
        policy_id,
        policy_status,
        start_date,
        end_date,
        updated_at
    from {{ ref('int_policy_status_history') }}
),

calendar as (
    select distinct policy_id, premium_year as year, premium_month as month
    from {{ ref('int_policy_premiums') }}
    union
    select distinct policy_id, claim_year as year, claim_month as month
    from {{ ref('int_policy_claims') }}
),

calendar_dates as (
    select
        policy_id,
        year,
        month,
        make_date(year, month, 1) as month_start
    from calendar
)

select
    cal.policy_id,
    cal.year,
    cal.month,

    p.policy_status,
    p.start_date,
    p.end_date,
    p.updated_at

from calendar_dates cal
left join portfolio p
    on cal.policy_id = p.policy_id
   and cal.month_start >= p.start_date
   and (p.end_date is null or cal.month_start <= p.end_date)
