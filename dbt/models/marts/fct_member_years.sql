/*
  One row per beneficiary per year: demographics, coverage, chronic conditions, spending by setting
  (from the beneficiary summary file, which also covers carrier / professional claims), and utilization
  counted from the inpatient and outpatient claims.
*/
with bene as (
    select * from {{ ref('stg_synpuf__beneficiary_years') }}
),

admissions as (
    select
        bene_id,
        year(admission_date)                        as yr,
        count(*)                                    as inpatient_admissions,
        sum(date_diff('day', admission_date, discharge_date)) as inpatient_days,
        sum(medicare_paid)                          as inpatient_claims_paid
    from {{ ref('int_inpatient_stays') }}
    group by 1, 2
),

outpatient as (
    select
        bene_id,
        year(claim_from_date)                       as yr,
        count(*)                                    as outpatient_claims,
        sum(medicare_paid)                          as outpatient_claims_paid
    from {{ ref('int_outpatient_claims') }}
    where claim_from_date is not null
    group by 1, 2
)

select
    b.bene_id || '-' || b.coverage_year                                   as member_year_id,
    b.bene_id,
    b.coverage_year,
    b.sex,
    b.race,
    b.has_esrd,
    b.ssa_state_code,
    b.coverage_year - year(b.birth_date)                                  as age,
    case
        when b.coverage_year - year(b.birth_date) < 65 then 'Under 65'
        when b.coverage_year - year(b.birth_date) < 75 then '65-74'
        when b.coverage_year - year(b.birth_date) < 85 then '75-84'
        else '85+'
    end                                                                   as age_band,
    b.death_date is not null and year(b.death_date) = b.coverage_year     as died_this_year,

    b.part_a_months,
    b.part_b_months,
    b.hmo_months,
    b.part_d_months,
    greatest(b.part_a_months, b.part_b_months)                            as member_months,

    b.has_alzheimers, b.has_heart_failure, b.has_chronic_kidney, b.has_cancer, b.has_copd,
    b.has_depression, b.has_diabetes, b.has_ischemic_heart, b.has_osteoporosis, b.has_ra_oa, b.has_stroke_tia,
    (b.has_alzheimers::int + b.has_heart_failure::int + b.has_chronic_kidney::int + b.has_cancer::int
     + b.has_copd::int + b.has_depression::int + b.has_diabetes::int + b.has_ischemic_heart::int
     + b.has_osteoporosis::int + b.has_ra_oa::int + b.has_stroke_tia::int)  as chronic_condition_count,

    b.medicare_paid_ip,
    b.medicare_paid_op,
    b.medicare_paid_carrier,
    b.medicare_paid_ip + b.medicare_paid_op + b.medicare_paid_carrier     as medicare_paid_total,
    b.bene_responsibility_ip + b.bene_responsibility_op + b.bene_responsibility_carrier
                                                                          as bene_responsibility_total,

    coalesce(a.inpatient_admissions, 0)                                   as inpatient_admissions,
    coalesce(a.inpatient_days, 0)                                         as inpatient_days,
    coalesce(a.inpatient_claims_paid, 0)                                  as inpatient_claims_paid,
    coalesce(o.outpatient_claims, 0)                                      as outpatient_claims,
    coalesce(o.outpatient_claims_paid, 0)                                 as outpatient_claims_paid
from bene b
left join admissions a on a.bene_id = b.bene_id and a.yr = b.coverage_year
left join outpatient o on o.bene_id = b.bene_id and o.yr = b.coverage_year
