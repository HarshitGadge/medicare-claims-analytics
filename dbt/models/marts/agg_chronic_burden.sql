-- Cost and utilization by number of chronic conditions (0 to 6+).
select
    coverage_year,
    least(chronic_condition_count, 6)                                   as chronic_conditions,
    case when chronic_condition_count >= 6 then '6+' else chronic_condition_count::varchar end as chronic_conditions_label,
    count(*)                                                            as members,
    sum(member_months)                                                  as member_months,
    sum(medicare_paid_total) / nullif(sum(member_months), 0)            as pmpm_total,
    sum(inpatient_admissions) * 12000.0 / nullif(sum(member_months), 0) as admits_per_1000,
    sum(medicare_paid_total) / sum(sum(medicare_paid_total)) over (partition by coverage_year) as share_of_spend,
    count(*) * 1.0 / sum(count(*)) over (partition by coverage_year)   as share_of_members
from {{ ref('fct_member_years') }}
where member_months > 0
group by 1, 2, 3
