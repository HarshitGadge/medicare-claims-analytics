#!/usr/bin/env bash
# Download CMS DE-SynPUF Sample 1 (beneficiary summary 2008–2010, inpatient and outpatient claims)
# into data/raw/. Source: https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf/de10-sample-1
set -euo pipefail
cd "$(dirname "$0")/../data/raw"
BASE="https://www.cms.gov/research-statistics-data-and-systems/downloadable-public-use-files/synpufs/downloads"
FILES=(
  "$BASE/de1_0_2008_beneficiary_summary_file_sample_1.zip"
  "$BASE/de1_0_2009_beneficiary_summary_file_sample_1.zip"
  # CMS's page links the 2010 file under this name; the archive contains the Sample 1 CSV.
  "https://www.cms.gov/research-statistics-data-and-systems/statistics-trends-and-reports/synpufs/downloads/de1_0_2010_beneficiary_summary_file_sample_20.zip"
  "$BASE/de1_0_2008_to_2010_inpatient_claims_sample_1.zip"
  "$BASE/de1_0_2008_to_2010_outpatient_claims_sample_1.zip"
)
for url in "${FILES[@]}"; do
  echo "Downloading ${url##*/}"
  curl -fsSL -A "Mozilla/5.0" -o tmp.zip "$url"
  unzip -o -q tmp.zip && rm tmp.zip
done
ls -lh DE1_0_*.csv
