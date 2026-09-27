{{ config(severity = 'warn') }}
-- Negative inpatient payments are adjustment claims. Warn if they exceed 0.5% of claim segments.
select count(*) filter (where medicare_paid < 0) as negative_segments, count(*) as segments
from {{ ref('stg_synpuf__inpatient_claims') }}
having count(*) filter (where medicare_paid < 0) > 0.005 * count(*)
