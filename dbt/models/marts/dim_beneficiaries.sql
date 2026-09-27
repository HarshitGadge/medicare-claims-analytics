-- One row per beneficiary. Demographics from the most recent year the beneficiary appears.
with ranked as (
    select
        *,
        row_number() over (partition by bene_id order by coverage_year desc) as rn,
        min(coverage_year) over (partition by bene_id)                        as first_coverage_year
    from {{ ref('stg_synpuf__beneficiary_years') }}
)

select
    r.bene_id,
    r.birth_date,
    r.death_date,
    r.sex,
    r.race,
    r.ssa_state_code,
    s.state_abbrev,
    s.state_name,
    r.first_coverage_year,
    r.coverage_year                                                                                             as last_coverage_year
from ranked r
left join {{ ref('ssa_state_codes') }} s
    on r.ssa_state_code = s.ssa_state_code
where r.rn = 1
