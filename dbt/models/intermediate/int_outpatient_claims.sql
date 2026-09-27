-- One row per outpatient claim (segments combined). Dates come from the first segment.
select
    bene_id,
    claim_id,
    min(claim_from_date)                            as claim_from_date,
    max(claim_thru_date)                            as claim_thru_date,
    arg_min(provider_id, claim_segment)             as provider_id,
    arg_min(principal_dx, claim_segment)            as principal_dx,
    sum(medicare_paid)                              as medicare_paid,
    count(*)                                        as n_segments
from {{ ref('stg_synpuf__outpatient_claims') }}
group by bene_id, claim_id
