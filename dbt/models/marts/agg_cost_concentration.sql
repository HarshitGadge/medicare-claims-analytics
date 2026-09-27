-- How concentrated spending is: share of total Medicare payments by member spending percentile band.
-- Member-years with no Part A or B coverage months are excluded, as in the PMPM marts.
with ranked as (
    select
        coverage_year,
        medicare_paid_total,
        percent_rank() over (partition by coverage_year order by medicare_paid_total desc) as pct_rank
    from {{ ref('fct_member_years') }}
    where member_months > 0
),

banded as (
    select
        *,
        case
            when pct_rank < 0.01 then '1. Top 1%'
            when pct_rank < 0.05 then '2. Next 4% (top 1–5%)'
            when pct_rank < 0.20 then '3. Next 15% (top 5–20%)'
            when pct_rank < 0.50 then '4. Next 30% (top 20–50%)'
            else '5. Bottom 50%'
        end as spend_band
    from ranked
)

select
    coverage_year,
    spend_band,
    count(*)                                                                         as members,
    sum(medicare_paid_total)                                                         as medicare_paid_total,
    avg(medicare_paid_total)                                                         as avg_paid_per_member,
    sum(medicare_paid_total) / sum(sum(medicare_paid_total)) over (partition by coverage_year) as share_of_spend
from banded
group by coverage_year, spend_band
