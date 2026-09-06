from __future__ import annotations

import re
from pathlib import Path

import pandas as pd

from .config import COUNTRY_ALIASES, END_YEAR, START_YEAR, TARGET_COUNTRIES


def snake_case(value: object) -> str:
    text = str(value).strip().lower()
    text = text.replace("us$", "usd").replace("%", " pct ").replace("$", " usd ")
    text = re.sub(r"[^a-z0-9]+", "_", text)
    return re.sub(r"_+", "_", text).strip("_")


def normalize_country(series: pd.Series) -> pd.Series:
    cleaned = series.astype("string").str.strip()
    return cleaned.replace(COUNTRY_ALIASES)


def normalize_columns(frame: pd.DataFrame) -> pd.DataFrame:
    result = frame.copy()
    result.columns = [snake_case(column) for column in result.columns]
    return result


def coerce_numeric_columns(
    frame: pd.DataFrame,
    excluded: set[str],
) -> pd.DataFrame:
    result = frame.copy()
    for column in result.columns:
        if column not in excluded:
            result[column] = pd.to_numeric(result[column], errors="coerce")
    return result


def filter_country_scope(frame: pd.DataFrame) -> pd.DataFrame:
    result = frame.copy()
    result["country"] = normalize_country(result["country"])
    return result[result["country"].isin(TARGET_COUNTRIES)].copy()


def filter_year_scope(frame: pd.DataFrame, year_column: str) -> pd.DataFrame:
    result = frame.copy()
    result[year_column] = pd.to_numeric(result[year_column], errors="coerce").astype("Int64")
    return result[result[year_column].between(START_YEAR, END_YEAR)].copy()


def read_multilevel_data_sheet(path: Path, identifier_columns: list[str]) -> pd.DataFrame:
    frame = pd.read_excel(path, sheet_name="Data", header=1)
    rename_map = {
        frame.columns[index]: name
        for index, name in enumerate(identifier_columns)
    }
    return frame.rename(columns=rename_map)


def transform_demographic(path: Path) -> pd.DataFrame:
    frame = read_multilevel_data_sheet(path, ["Country", "Year"])
    frame = normalize_columns(frame)
    frame = filter_country_scope(frame)
    frame = filter_year_scope(frame, "year")
    frame = coerce_numeric_columns(frame, {"country", "year"})
    return frame.sort_values(["country", "year"]).reset_index(drop=True)


def transform_macro(path: Path) -> pd.DataFrame:
    frame = pd.read_excel(path, sheet_name="Data", header=1)
    frame = normalize_columns(frame)
    frame = filter_country_scope(frame)
    frame = filter_year_scope(frame, "year")
    frame = coerce_numeric_columns(frame, {"country", "year"})
    return frame.sort_values(["country", "year"]).reset_index(drop=True)


def transform_socioeconomic(path: Path) -> pd.DataFrame:
    frame = read_multilevel_data_sheet(path, ["Country", "Year"])
    frame = normalize_columns(frame)
    frame = filter_country_scope(frame)
    frame = filter_year_scope(frame, "year")
    frame = coerce_numeric_columns(frame, {"country", "year"})
    return frame.sort_values(["country", "year"]).reset_index(drop=True)


def transform_trade(path: Path) -> pd.DataFrame:
    frame = read_multilevel_data_sheet(
        path,
        ["Country", "Product Group", "Grouping Level"],
    )
    frame = normalize_columns(frame)
    frame = filter_country_scope(frame)
    frame.insert(1, "year", 2023)
    frame = coerce_numeric_columns(
        frame,
        {"country", "year", "product_group", "grouping_level"},
    )
    return frame.sort_values(["country", "grouping_level", "product_group"]).reset_index(drop=True)


def transform_companies(path: Path) -> pd.DataFrame:
    frame = pd.read_excel(path, sheet_name="Companies", header=1)
    frame = normalize_columns(frame)
    frame = filter_country_scope(frame)
    frame = filter_year_scope(frame, "signal_year")
    frame["source_date"] = pd.to_datetime(frame["source_date"], errors="coerce")

    numeric_columns = [
        "investment_est_usd_million",
        "investment_score",
        "recency_score",
        "facility_type_score",
        "infrastructure_synergy_score",
        "opportunity_score",
    ]
    for column in numeric_columns:
        frame[column] = pd.to_numeric(frame[column], errors="coerce")

    return frame.sort_values(
        ["country", "opportunity_score", "company"],
        ascending=[True, False, True],
    ).reset_index(drop=True)


def transform_infrastructure(path: Path) -> pd.DataFrame:
    frame = pd.read_excel(path, sheet_name="Infrastructure", header=1)
    frame = normalize_columns(frame)
    frame = filter_country_scope(frame)
    frame["source_date"] = pd.to_datetime(frame["source_date"], errors="coerce")
    frame["source_year"] = frame["source_date"].dt.year.astype("Int64")
    frame = filter_year_scope(frame, "source_year")
    return frame.sort_values(["country", "source_date", "project_name"]).reset_index(drop=True)
