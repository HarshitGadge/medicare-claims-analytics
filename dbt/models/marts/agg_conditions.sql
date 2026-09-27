-- Prevalence of each chronic condition and PMPM for members with vs without it.
{% set conditions = {
    'has_alzheimers': "Alzheimer''s / dementia", 'has_heart_failure': 'Heart failure',
    'has_chronic_kidney': 'Chronic kidney disease', 'has_cancer': 'Cancer', 'has_copd': 'COPD',
    'has_depression': 'Depression', 'has_diabetes': 'Diabetes', 'has_ischemic_heart': 'Ischemic heart disease',
    'has_osteoporosis': 'Osteoporosis', 'has_ra_oa': 'Rheumatoid arthritis / osteoarthritis',
    'has_stroke_tia': 'Stroke / TIA'
} %}

{% for col, label in conditions.items() %}
select
    coverage_year,
    '{{ label }}'                                                                             as condition,
    avg({{ col }}::int)                                                                       as prevalence,
    sum(case when {{ col }} then medicare_paid_total end) / nullif(sum(case when {{ col }} then member_months end), 0)     as pmpm_with,
    sum(case when not {{ col }} then medicare_paid_total end) / nullif(sum(case when not {{ col }} then member_months end), 0) as pmpm_without,
    sum(case when {{ col }} then medicare_paid_total end) / sum(medicare_paid_total)          as share_of_spend_with
from {{ ref('fct_member_years') }}
where member_months > 0
group by coverage_year
{% if not loop.last %}union all{% endif %}
{% endfor %}
