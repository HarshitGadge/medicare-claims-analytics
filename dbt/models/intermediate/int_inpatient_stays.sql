/*
  One row per hospital stay. Claims for the same beneficiary are merged into one stay when they
    - overlap, or start on the day the previous claim ends, or
    - start the next calendar day at a different provider (a transfer).
  This follows the CMS readmission measures, which treat a chain of transfers (same or next day, between hospitals)
  as one index admission. A next-day admission to the same provider starts a new stay.

  Gaps-and-islands: compare each claim with the latest discharge among the beneficiary's earlier claims.
*/
with ordered as (
    select
        *,
        max(discharge_date) over (
            partition by bene_id
            order by admission_date, discharge_date, claim_id
            rows between unbounded preceding and 1 preceding
        ) as prior_max_discharge,
        arg_max(provider_id, discharge_date) over (
            partition by bene_id
            order by admission_date, discharge_date, claim_id
            rows between unbounded preceding and 1 preceding
        ) as prior_provider_id
    from {{ ref('int_inpatient_claims') }}
),

flagged as (
    select
        *,
        case
            when prior_max_discharge is null then 1
            when admission_date <= prior_max_discharge then 0                        -- overlap or same-day
            when admission_date = prior_max_discharge + 1
                 and provider_id is distinct from prior_provider_id then 0           -- next-day transfer
            else 1
        end as starts_new_stay
    from ordered
),

numbered as (
    select
        *,
        sum(starts_new_stay) over (
            partition by bene_id
            order by admission_date, discharge_date, claim_id
            rows between unbounded preceding and current row
        ) as stay_seq
    from flagged
)

select
    bene_id || '-' || lpad(stay_seq::varchar, 3, '0')              as stay_id,
    bene_id,
    stay_seq,
    min(admission_date)                                             as admission_date,
    max(discharge_date)                                             as discharge_date,
    count(*)                                                        as n_claims,
    count(*) > 1                                                    as includes_transfer_or_overlap,
    arg_min(principal_dx, admission_date)                           as principal_dx,
    arg_min(drg_code, admission_date)                               as drg_code,
    arg_max(provider_id, discharge_date)                            as discharging_provider_id,
    sum(medicare_paid)                                              as medicare_paid,
    sum(bene_cost_share)                                            as bene_cost_share
from numbered
group by bene_id, stay_seq
