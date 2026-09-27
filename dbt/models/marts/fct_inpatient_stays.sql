/*
  One row per hospital stay, with 30-day all-cause readmission flags.

  Index stay (eligible to be counted in the readmission rate):
    - the beneficiary was discharged alive, and
    - the discharge is at least 30 days before the end of the data, so the full follow-up window is observed.
  Readmission: the beneficiary's next stay starts 1–30 days after this discharge. Same-day admissions and
  next-day transfers to a different provider were already merged into the stay in int_inpatient_stays.
*/
{% set data_end = "date '" ~ var('data_end_date') ~ "'" %}

with stays as (
    select * from {{ ref('int_inpatient_stays') }}
),

with_next as (
    select
        s.*,
        lead(s.admission_date) over (partition by s.bene_id order by s.stay_seq) as next_admission_date,
        lead(s.stay_id)        over (partition by s.bene_id order by s.stay_seq) as next_stay_id,
        b.death_date
    from stays s
    left join {{ ref('dim_beneficiaries') }} b using (bene_id)
)

select
    stay_id,
    bene_id,
    stay_seq,
    admission_date,
    discharge_date,
    year(discharge_date)                                                      as discharge_year,
    date_diff('day', admission_date, discharge_date)                          as length_of_stay_days,
    n_claims,
    includes_transfer_or_overlap,
    principal_dx,
    {{ readmission_condition_group('principal_dx') }}                        as condition_group,
    drg_code,
    discharging_provider_id,
    medicare_paid,
    bene_cost_share,

    death_date is not null and death_date <= discharge_date                   as died_in_hospital,
    death_date is not null
        and death_date > discharge_date
        and date_diff('day', discharge_date, death_date) <= 30                as died_within_30d,
    next_stay_id,
    next_admission_date,
    date_diff('day', discharge_date, next_admission_date)                     as days_to_next_admission,

    date_diff('day', discharge_date, {{ data_end }}) >= 30                    as has_30d_follow_up,
    (death_date is null or death_date > discharge_date)
        and date_diff('day', discharge_date, {{ data_end }}) >= 30            as is_index_stay,
    (death_date is null or death_date > discharge_date)
        and date_diff('day', discharge_date, {{ data_end }}) >= 30
        and coalesce(date_diff('day', discharge_date, next_admission_date) between 1 and 30, false)
                                                                              as is_readmitted_30d
from with_next
