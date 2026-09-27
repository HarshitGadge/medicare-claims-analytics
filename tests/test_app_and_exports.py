"""Smoke tests for the committed exports and the Streamlit app."""
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parent.parent
EXPORTS = ROOT / "exports"


def test_spend_bands_sum_to_one():
    conc = pd.read_csv(EXPORTS / "agg_cost_concentration.csv")
    totals = conc.groupby("coverage_year").share_of_spend.sum()
    assert totals.between(0.999, 1.001).all()


def test_readmission_rates_are_consistent():
    r = pd.read_csv(EXPORTS / "agg_readmissions.csv")
    assert (r.readmissions_30d <= r.index_stays).all()
    recomputed = r.readmissions_30d / r.index_stays
    assert (recomputed - r.readmission_rate_30d).abs().max() < 1e-9
    # the condition rows add up to the 'All conditions' row
    parts = r[r.condition_group != "All conditions"].groupby("discharge_year").index_stays.sum()
    total = r[r.condition_group == "All conditions"].set_index("discharge_year").index_stays
    assert parts.equals(total.loc[parts.index])


def test_pmpm_components_add_up():
    u = pd.read_csv(EXPORTS / "agg_utilization_by_year.csv")
    assert ((u.pmpm_ip + u.pmpm_op + u.pmpm_carrier) - u.pmpm_total).abs().max() < 1e-6


@pytest.mark.parametrize("year", [2008, 2009, 2010])
def test_streamlit_app_runs_without_errors(year):
    from streamlit.testing.v1 import AppTest

    at = AppTest.from_file(str(ROOT / "app" / "streamlit_app.py"), default_timeout=60)
    at.run()
    assert not at.exception
    at.segmented_control[0].set_value(year).run()
    assert not at.exception
    assert len(at.metric) == 5
