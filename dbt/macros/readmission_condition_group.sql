{#
  Maps an ICD-9-CM principal diagnosis to the condition cohorts used by the CMS Hospital
  Readmissions Reduction Program (HRRP). These are simplified versions of the CMS cohort
  definitions (principal-diagnosis code lists only; no procedure-based or secondary-diagnosis rules).
    AMI        410.xx, excluding 410.x2 (subsequent episode of care)
    Heart failure  428.xx and the hypertensive heart / kidney disease with heart failure codes
    Pneumonia  480–483, 485, 486, 487.0, 488.11
    COPD       491.21, 491.22, 491.8, 491.9, 492.8, 493.20–493.22, 496
#}
{% macro readmission_condition_group(dx) %}
    case
        when {{ dx }} like '410%' and {{ dx }} not like '410_2' then 'AMI'
        when {{ dx }} like '428%'
          or {{ dx }} in ('40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493')
            then 'Heart failure'
        when left({{ dx }}, 3) in ('480', '481', '482', '483', '485', '486')
          or {{ dx }} in ('4870', '48811')
            then 'Pneumonia'
        when {{ dx }} in ('49121', '49122', '4918', '4919', '4928', '49320', '49321', '49322', '496')
            then 'COPD'
        else 'Other'
    end
{% endmacro %}
