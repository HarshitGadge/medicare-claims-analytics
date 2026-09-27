-- Fails if any stay is discharged before it was admitted.
select stay_id, admission_date, discharge_date
from {{ ref('fct_inpatient_stays') }}
where discharge_date < admission_date
