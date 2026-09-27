-- State-level PMPM, admissions and readmission rate by year (for maps and filters).
with members as (
    select
        coverage_year,
        ssa_state_code,
        count(*)                                                            as members,
        sum(member_months)                                                  as member_months,
        sum(medicare_paid_total) / nullif(sum(member_months), 0)            as pmpm_total,
        sum(inpatient_admissions) * 12000.0 / nullif(sum(member_months), 0) as admits_per_1000
    from {{ ref('fct_member_years') }}
    where member_months > 0
    group by 1, 2
),

readmits as (
    select
        s.discharge_year                    as coverage_year,
        b.ssa_state_code,
        count(*)                            as index_stays,
        avg(s.is_readmitted_30d::int)       as readmission_rate_30d
    from {{ ref('fct_inpatient_stays') }} s
    join {{ ref('dim_beneficiaries') }} b using (bene_id)
    where s.is_index_stay
    group by 1, 2
)

select
    m.*,
    st.state_abbrev,
    st.state_name,
    r.index_stays,
    r.readmission_rate_30d
from members m
left join readmits r using (coverage_year, ssa_state_code)
left join {{ ref('ssa_state_codes') }} st using (ssa_state_code)
