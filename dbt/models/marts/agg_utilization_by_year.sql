-- Plan-level cost and utilization per year: PMPM by setting and utilization per 1,000 member-years.
select
    coverage_year,
    count(*)                                                        as members,
    sum(member_months)                                              as member_months,
    sum(medicare_paid_total)                                        as medicare_paid_total,
    sum(medicare_paid_ip)                                           as medicare_paid_ip,
    sum(medicare_paid_op)                                           as medicare_paid_op,
    sum(medicare_paid_carrier)                                      as medicare_paid_carrier,
    sum(medicare_paid_total)   / nullif(sum(member_months), 0)      as pmpm_total,
    sum(medicare_paid_ip)      / nullif(sum(member_months), 0)      as pmpm_ip,
    sum(medicare_paid_op)      / nullif(sum(member_months), 0)      as pmpm_op,
    sum(medicare_paid_carrier) / nullif(sum(member_months), 0)      as pmpm_carrier,
    sum(inpatient_admissions)  * 12000.0 / nullif(sum(member_months), 0) as admits_per_1000,
    sum(inpatient_days)        * 12000.0 / nullif(sum(member_months), 0) as inpatient_days_per_1000,
    sum(outpatient_claims)     * 12000.0 / nullif(sum(member_months), 0) as outpatient_claims_per_1000,
    sum(inpatient_days)        * 1.0     / nullif(sum(inpatient_admissions), 0) as avg_length_of_stay,
    avg(chronic_condition_count)                                    as avg_chronic_conditions,
    avg(died_this_year::int)                                        as mortality_rate
from {{ ref('fct_member_years') }}
where member_months > 0
group by coverage_year
