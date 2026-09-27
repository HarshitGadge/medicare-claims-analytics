-- One row per outpatient claim segment. Continuation segments (segment 2) carry no dates.
with source as (
    select * from {{ source('synpuf', 'outpatient_claims') }}
)

select
    desynpuf_id                                     as bene_id,
    clm_id                                          as claim_id,
    segment::integer                                as claim_segment,
    strptime(clm_from_dt, '%Y%m%d')::date           as claim_from_date,
    strptime(clm_thru_dt, '%Y%m%d')::date           as claim_thru_date,
    prvdr_num                                       as provider_id,
    clm_pmt_amt::double                             as medicare_paid,
    nch_prmry_pyr_clm_pd_amt::double                as primary_payer_paid,
    nch_bene_ptb_ddctbl_amt::double                 as bene_deductible,
    nch_bene_ptb_coinsrnc_amt::double               as bene_coinsurance,
    icd9_dgns_cd_1                                  as principal_dx,
    hcpcs_cd_1                                      as first_hcpcs
from source
