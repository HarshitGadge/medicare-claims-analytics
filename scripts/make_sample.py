"""Write a deterministic ~1% beneficiary sample of the raw DE-SynPUF files to data/sample/.

The sample keeps every claim for the selected beneficiaries, so all models and tests run on it.
It is committed to the repo so CI (and anyone without the full download) can run `dbt build`.
"""
from pathlib import Path

import duckdb

RAW, OUT = Path("data/raw"), Path("data/sample")
OUT.mkdir(parents=True, exist_ok=True)
KEEP = "hash(DESYNPUF_ID) % 100 = 0"

con = duckdb.connect()
for f in sorted(RAW.glob("DE1_0_*.csv")):
    con.execute(
        f"copy (select * from read_csv('{f}', all_varchar = true) where {KEEP}) "
        f"to '{OUT / f.name}' (header, delimiter ',')"
    )
    n = con.execute(f"select count(*) from read_csv('{OUT / f.name}', all_varchar = true)").fetchone()[0]
    print(f"{f.name}: {n:,} rows")
