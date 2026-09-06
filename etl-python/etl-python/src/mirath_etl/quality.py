from __future__ import annotations

from typing import Any

import pandas as pd

from .config import END_YEAR, START_YEAR, TARGET_COUNTRIES


PRIMARY_KEYS = {
    "fact_demographic": ["country", "year"],
    "fact_macro": ["country", "year"],
    "fact_socioeconomic": ["country", "year"],
    "fact_trade_product": ["country", "year", "product_group", "grouping_level"],
    "fact_company": ["country", "company", "signal_year"],
    "fact_infrastructure": ["country", "project_name", "source_date"],
}


def profile_table(name: str, frame: pd.DataFrame) -> dict[str, Any]:
    countries = sorted(frame["country"].dropna().astype(str).unique()) if "country" in frame else []
    key = PRIMARY_KEYS[name]
    duplicate_count = int(frame.duplicated(key).sum())
    missing_by_column = {
        column: int(count)
        for column, count in frame.isna().sum().items()
        if int(count) > 0
    }

    year_column = next(
        (candidate for candidate in ("year", "signal_year", "source_year") if candidate in frame),
        None,
    )
    years = (
        sorted(int(value) for value in frame[year_column].dropna().unique())
        if year_column
        else []
    )

    return {
        "table": name,
        "rows": int(len(frame)),
        "columns": int(len(frame.columns)),
        "duplicate_primary_keys": duplicate_count,
        "country_count": len(countries),
        "countries_present": countries,
        "countries_missing": sorted(set(TARGET_COUNTRIES) - set(countries)),
        "years_present": years,
        "missing_required_years": sorted(set(range(START_YEAR, END_YEAR + 1)) - set(years)),
        "missing_values_by_column": missing_by_column,
    }


def validate_tables(tables: dict[str, pd.DataFrame]) -> list[dict[str, Any]]:
    report = []
    for name, frame in tables.items():
        profile = profile_table(name, frame)
        if profile["duplicate_primary_keys"]:
            raise ValueError(
                f"{name} contains {profile['duplicate_primary_keys']} duplicate primary keys"
            )
        report.append(profile)
    return report

