-- 30-day all-cause readmission rate by discharge year and index condition (plus an 'All conditions' row).
with index_stays as (
    select * from {{ ref('fct_inpatient_stays') }} where is_index_stay
)

select
    discharge_year,
    condition_group,
    count(*)                                        as index_stays,
    sum(is_readmitted_30d::int)                     as readmissions_30d,
    avg(is_readmitted_30d::int)                     as readmission_rate_30d,
    avg(length_of_stay_days)                        as avg_length_of_stay,
    avg(medicare_paid)                              as avg_paid_per_stay
from index_stays
group by discharge_year, condition_group

union all

select
    discharge_year,
    'All conditions',
    count(*),
    sum(is_readmitted_30d::int),
    avg(is_readmitted_30d::int),
    avg(length_of_stay_days),
    avg(medicare_paid)
from index_stays
group by discharge_year
