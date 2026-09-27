"""Medicare claims dashboard (Streamlit).

Reads the aggregate marts exported by scripts/export_marts.py (exports/*.csv), so it runs without the raw data:

    streamlit run app/streamlit_app.py
"""
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

EXPORTS = Path(__file__).resolve().parent.parent / "exports"
BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
INK2, GRID = "#52514e", "#e4e3df"

st.set_page_config(page_title="Medicare Claims Dashboard", layout="wide")


@st.cache_data
def load(name: str) -> pd.DataFrame:
    return pd.read_csv(EXPORTS / f"{name}.csv")


util = load("agg_utilization_by_year")
conc = load("agg_cost_concentration")
burden = load("agg_chronic_burden")
conditions = load("agg_conditions")
readm = load("agg_readmissions")
states = load("agg_state_year")


def style(fig: go.Figure, height: int = 320) -> go.Figure:
    fig.update_layout(height=height, margin=dict(l=10, r=10, t=40, b=10), plot_bgcolor="rgba(0,0,0,0)",
                      paper_bgcolor="rgba(0,0,0,0)", legend=dict(orientation="h", y=-0.2), font=dict(size=13))
    fig.update_xaxes(showgrid=False)
    fig.update_yaxes(gridcolor=GRID)
    return fig


st.title("Medicare claims: cost, utilization and readmissions")
st.caption(
    "CMS DE-SynPUF Sample 1 (synthetic Medicare fee-for-service claims, 2008–2010), modeled with dbt + DuckDB. "
    "The data is synthetic: it shows what the pipeline produces, not real Medicare trends. "
    "2010 has fewer claims in the source file, so 2008–2009 are the main comparison years."
)

year = st.segmented_control("Year", options=[2008, 2009, 2010], default=2009)
if year is None:
    year = 2009
u = util.set_index("coverage_year").loc[year]
r_all = readm[(readm.discharge_year == year) & (readm.condition_group == "All conditions")].iloc[0]
top5 = conc[(conc.coverage_year == year) & conc.spend_band.str[:1].isin(["1", "2"])].share_of_spend.sum()

k1, k2, k3, k4, k5 = st.columns(5)
k1.metric("Members", f"{u.members:,.0f}")
k2.metric("PMPM (Medicare paid)", f"${u.pmpm_total:,.0f}")
k3.metric("Admissions per 1,000", f"{u.admits_per_1000:,.0f}")
k4.metric("30-day readmission rate", f"{r_all.readmission_rate_30d:.1%}")
k5.metric("Spend from top 5% of members", f"{top5:.0%}")

tab_cost, tab_chronic, tab_readm, tab_map = st.tabs(["Cost & utilization", "Chronic conditions", "Readmissions", "By state"])

with tab_cost:
    c1, c2 = st.columns(2)
    long = util.melt(id_vars="coverage_year", value_vars=["pmpm_ip", "pmpm_carrier", "pmpm_op"], var_name="setting", value_name="pmpm")
    long["setting"] = long.setting.map({"pmpm_ip": "Inpatient", "pmpm_carrier": "Professional (carrier)", "pmpm_op": "Outpatient"})
    fig = px.bar(long, x="coverage_year", y="pmpm", color="setting", barmode="group", text_auto="$.0f",
                 color_discrete_sequence=[BLUE, ORANGE, AQUA], labels={"coverage_year": "Year", "pmpm": "PMPM", "setting": ""},
                 title="PMPM by setting")
    fig.update_xaxes(type="category")
    fig.update_layout(bargap=0.25, bargroupgap=0.06)
    fig.update_traces(hovertemplate="%{x} · %{fullData.name}: $%{y:,.0f} PMPM<extra></extra>")
    c1.plotly_chart(style(fig), use_container_width=True)

    c = conc[conc.coverage_year == year].sort_values("spend_band")
    c = c.assign(band=c.spend_band.str[3:], share_of_members=c.members / c.members.sum())
    fig = go.Figure()
    fig.add_bar(y=c.band, x=c.share_of_spend * 100, orientation="h", marker_color=BLUE, name="Share of spending",
                text=[f"{v:.0%}" for v in c.share_of_spend], textposition="outside",
                hovertemplate="%{y}: %{x:.1f}% of spending<extra></extra>")
    fig.update_layout(title=f"Share of {year} spending by member spending band")
    fig.update_yaxes(autorange="reversed")
    fig.update_xaxes(title="% of total Medicare paid", range=[0, 45])
    c2.plotly_chart(style(fig), use_container_width=True)

    table = util.set_index("coverage_year")[
        ["members", "member_months", "pmpm_total", "pmpm_ip", "pmpm_op", "pmpm_carrier", "admits_per_1000",
         "inpatient_days_per_1000", "outpatient_claims_per_1000", "avg_length_of_stay"]].round(1)
    table.index.name = "Year"
    table.columns = ["Members", "Member months", "PMPM", "PMPM inpatient", "PMPM outpatient", "PMPM professional",
                     "Admits / 1,000", "IP days / 1,000", "OP claims / 1,000", "Avg length of stay"]
    st.dataframe(table, use_container_width=True)

with tab_chronic:
    c1, c2 = st.columns(2)
    b = burden[burden.coverage_year == year].sort_values("chronic_conditions")
    fig = px.bar(b, x="chronic_conditions_label", y="pmpm_total", text_auto="$.0f", color_discrete_sequence=[BLUE],
                 labels={"chronic_conditions_label": "Number of chronic conditions", "pmpm_total": "PMPM"},
                 title=f"PMPM by number of chronic conditions, {year}")
    fig.update_traces(customdata=b[["members", "share_of_spend"]],
                      hovertemplate="%{x} conditions: $%{y:,.0f} PMPM<br>%{customdata[0]:,} members, %{customdata[1]:.0%} of spend<extra></extra>")
    c1.plotly_chart(style(fig), use_container_width=True)

    cd = conditions[conditions.coverage_year == year].sort_values("prevalence")
    fig = go.Figure()
    fig.add_bar(y=cd.condition, x=cd.pmpm_with, orientation="h", name="With the condition", marker_color=BLUE,
                hovertemplate="%{y}: $%{x:,.0f} PMPM with<extra></extra>")
    fig.add_bar(y=cd.condition, x=cd.pmpm_without, orientation="h", name="Without", marker_color=ORANGE,
                hovertemplate="%{y}: $%{x:,.0f} PMPM without<extra></extra>")
    fig.update_layout(barmode="group", title=f"PMPM with vs without each condition, {year}")
    fig.update_xaxes(title="PMPM", tickprefix="$")
    c2.plotly_chart(style(fig, 420), use_container_width=True)

with tab_readm:
    st.caption("Index stay: discharged alive with 30 days of follow-up in the data. Readmission: any stay starting 1–30 days later. "
               "Condition groups use simplified CMS HRRP ICD-9 cohorts.")
    rr = readm[readm.condition_group != "Other"].copy()
    fig = px.bar(rr, x="condition_group", y="readmission_rate_30d", color=rr.discharge_year.astype(str), barmode="group",
                 color_discrete_sequence=[BLUE, ORANGE, AQUA], text_auto=".1%",
                 category_orders={"condition_group": ["All conditions", "AMI", "Heart failure", "Pneumonia", "COPD"]},
                 labels={"condition_group": "", "readmission_rate_30d": "30-day readmission rate", "color": "Year"},
                 title="30-day all-cause readmission rate by index condition")
    fig.update_yaxes(tickformat=".0%")
    st.plotly_chart(style(fig, 360), use_container_width=True)
    st.info("The rate falls from 2008 to 2010 because later years of the synthetic file have fewer follow-up claims. "
            "Compare conditions within a year rather than across years.")
    st.dataframe(readm.pivot(index="condition_group", columns="discharge_year", values=["index_stays", "readmission_rate_30d"]).round(3),
                 use_container_width=True)

with tab_map:
    metric = st.radio("Metric", ["PMPM", "Admissions per 1,000", "30-day readmission rate"], horizontal=True)
    col = {"PMPM": "pmpm_total", "Admissions per 1,000": "admits_per_1000", "30-day readmission rate": "readmission_rate_30d"}[metric]
    s = states[(states.coverage_year == year) & states.state_abbrev.notna()]
    fig = px.choropleth(s, locations="state_abbrev", locationmode="USA-states", scope="usa", color=col,
                        color_continuous_scale=["#cde2fb", "#6da7ec", "#2a78d6", "#184f95"],
                        hover_name="state_name", hover_data={"members": ":,", col: ":.3f", "state_abbrev": False},
                        title=f"{metric} by state, {year}")
    st.plotly_chart(style(fig, 460), use_container_width=True)
    st.caption("States with few members swing more from year to year. Code 54 ('Other') is excluded from the map.")
