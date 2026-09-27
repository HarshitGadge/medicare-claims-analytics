-- One row per inpatient claim segment.
with source as (
    select * from {{ source('synpuf', 'inpatient_claims') }}
)

select
    desynpuf_id                                     as bene_id,
    clm_id                                          as claim_id,
    segment::integer                                as claim_segment,
    strptime(clm_from_dt, '%Y%m%d')::date           as claim_from_date,
    strptime(clm_thru_dt, '%Y%m%d')::date           as claim_thru_date,
    strptime(clm_admsn_dt, '%Y%m%d')::date          as admission_date,
    strptime(nch_bene_dschrg_dt, '%Y%m%d')::date    as discharge_date,
    prvdr_num                                       as provider_id,
    at_physn_npi                                    as attending_npi,
    clm_pmt_amt::double                             as medicare_paid,
    nch_prmry_pyr_clm_pd_amt::double                as primary_payer_paid,
    nch_bene_ip_ddctbl_amt::double                  as bene_deductible,
    nch_bene_pta_coinsrnc_lblty_am::double          as bene_coinsurance,
    clm_utlztn_day_cnt::integer                     as utilization_days,
    clm_drg_cd                                      as drg_code,
    admtng_icd9_dgns_cd                             as admitting_dx,
    icd9_dgns_cd_1                                  as principal_dx,
    icd9_dgns_cd_2                                  as dx_2,
    icd9_dgns_cd_3                                  as dx_3,
    icd9_prcdr_cd_1                                 as principal_procedure
from source
