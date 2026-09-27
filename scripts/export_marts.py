"""Export the dbt marts for BI tools and the Streamlit app.

- exports/*.csv      small aggregate tables (committed; the Streamlit app reads these)
- exports/*.parquet  member-year, stay and beneficiary tables for a Power BI star schema
"""
import sys
from pathlib import Path

import duckdb

db = sys.argv[1] if len(sys.argv) > 1 else "medicare.duckdb"
out = Path("exports")
out.mkdir(exist_ok=True)
con = duckdb.connect(db, read_only=True)

AGGREGATES = ["agg_utilization_by_year", "agg_cost_concentration", "agg_chronic_burden",
              "agg_conditions", "agg_readmissions", "agg_state_year"]
DETAIL = ["fct_member_years", "fct_inpatient_stays", "dim_beneficiaries"]

for t in AGGREGATES:
    con.execute(f"copy (select * from {t} order by all) to '{out / t}.csv' (header)")
for t in DETAIL:
    con.execute(f"copy (select * from {t}) to '{out / t}.parquet' (format parquet, compression zstd)")
for f in sorted(out.iterdir()):
    print(f"{f.name:40s} {f.stat().st_size / 1e6:6.2f} MB")
