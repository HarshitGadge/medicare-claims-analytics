-- One row per beneficiary per coverage year. Codes decoded using the DE-SynPUF codebook.
with source as (
    select * from {{ source('synpuf', 'beneficiary_summary') }}
)

select
    desynpuf_id                                                            as bene_id,
    cast(regexp_extract(filename, 'DE1_0_(\d{4})_Beneficiary', 1) as integer) as coverage_year,
    strptime(bene_birth_dt, '%Y%m%d')::date                                as birth_date,
    strptime(bene_death_dt, '%Y%m%d')::date                                as death_date,
    case bene_sex_ident_cd when '1' then 'Male' when '2' then 'Female' end as sex,
    case bene_race_cd
        when '1' then 'White' when '2' then 'Black'
        when '3' then 'Other' when '5' then 'Hispanic'
    end                                                                    as race,
    bene_esrd_ind = 'Y'                                                    as has_esrd,
    sp_state_code                                                          as ssa_state_code,
    bene_county_cd                                                         as ssa_county_code,

    -- coverage months (0–12)
    bene_hi_cvrage_tot_mons::integer                                       as part_a_months,
    bene_smi_cvrage_tot_mons::integer                                      as part_b_months,
    bene_hmo_cvrage_tot_mons::integer                                      as hmo_months,
    plan_cvrg_mos_num::integer                                             as part_d_months,

    -- chronic condition indicators (1 = yes, 2 = no)
    sp_alzhdmta = '1'                                                      as has_alzheimers,
    sp_chf      = '1'                                                      as has_heart_failure,
    sp_chrnkidn = '1'                                                      as has_chronic_kidney,
    sp_cncr     = '1'                                                      as has_cancer,
    sp_copd     = '1'                                                      as has_copd,
    sp_depressn = '1'                                                      as has_depression,
    sp_diabetes = '1'                                                      as has_diabetes,
    sp_ischmcht = '1'                                                      as has_ischemic_heart,
    sp_osteoprs = '1'                                                      as has_osteoporosis,
    sp_ra_oa    = '1'                                                      as has_ra_oa,
    sp_strketia = '1'                                                      as has_stroke_tia,

    -- annual fee-for-service amounts by setting (IP = inpatient, OP = outpatient, CAR = carrier / professional)
    medreimb_ip::double                                                    as medicare_paid_ip,
    benres_ip::double                                                      as bene_responsibility_ip,
    pppymt_ip::double                                                      as primary_payer_paid_ip,
    medreimb_op::double                                                    as medicare_paid_op,
    benres_op::double                                                      as bene_responsibility_op,
    pppymt_op::double                                                      as primary_payer_paid_op,
    medreimb_car::double                                                   as medicare_paid_carrier,
    benres_car::double                                                     as bene_responsibility_carrier,
    pppymt_car::double                                                     as primary_payer_paid_carrier
from source
