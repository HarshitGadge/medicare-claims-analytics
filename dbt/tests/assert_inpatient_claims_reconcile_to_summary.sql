-- Inpatient payments summed from claims should match the beneficiary summary file's annual inpatient
-- reimbursement within a tolerance (default 6%) for every year. A larger gap points to a join or date-parsing bug.
-- The committed 1% sample is noisier, so CI runs with a 10% tolerance.
with from_claims as (
    select year(claim_from_date) as yr, sum(medicare_paid) as paid
    from {{ ref('stg_synpuf__inpatient_claims') }}
    where claim_from_date is not null
    group by 1
),

from_summary as (
    select coverage_year as yr, sum(medicare_paid_ip) as paid
    from {{ ref('stg_synpuf__beneficiary_years') }}
    group by 1
)

select s.yr, s.paid as summary_paid, c.paid as claims_paid, abs(c.paid / s.paid - 1) as rel_gap
from from_summary s
join from_claims c using (yr)
where abs(c.paid / s.paid - 1) > {{ var('ip_reconciliation_tolerance', 0.06) }}
