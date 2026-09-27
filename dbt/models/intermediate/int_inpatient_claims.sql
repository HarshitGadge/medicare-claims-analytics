-- One row per inpatient claim (segments combined).
select
    bene_id,
    claim_id,
    min(admission_date)                             as admission_date,
    max(discharge_date)                             as discharge_date,
    arg_min(provider_id, claim_segment)             as provider_id,
    arg_min(drg_code, claim_segment)                as drg_code,
    arg_min(principal_dx, claim_segment)            as principal_dx,
    sum(medicare_paid)                              as medicare_paid,
    sum(coalesce(bene_deductible, 0) + coalesce(bene_coinsurance, 0)) as bene_cost_share,
    sum(utilization_days)                           as utilization_days,
    count(*)                                        as n_segments
from {{ ref('stg_synpuf__inpatient_claims') }}
group by bene_id, claim_id
