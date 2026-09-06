from __future__ import annotations

import json
from pathlib import Path

import pandas as pd

from .config import SOURCE_FILES, default_project_root
from .quality import validate_tables
from .sql_loader import load_to_azure_sql
from .transforms import (
    transform_companies,
    transform_demographic,
    transform_infrastructure,
    transform_macro,
    transform_socioeconomic,
    transform_trade,
)


def run_pipeline(
    input_dir: Path | None = None,
    output_dir: Path | None = None,
    load_sql: bool = False,
) -> dict[str, pd.DataFrame]:
    root = default_project_root()
    input_dir = Path(input_dir or root / "data" / "raw")
    output_dir = Path(output_dir or root / "data" / "processed")
    output_dir.mkdir(parents=True, exist_ok=True)

    missing_files = [
        filename
        for filename in SOURCE_FILES.values()
        if not (input_dir / filename).exists()
    ]
    if missing_files:
        raise FileNotFoundError(f"Missing source workbooks: {missing_files}")

    company_file = input_dir / SOURCE_FILES["company_infrastructure"]
    tables = {
        "fact_demographic": transform_demographic(input_dir / SOURCE_FILES["demographic"]),
        "fact_macro": transform_macro(input_dir / SOURCE_FILES["macro"]),
        "fact_socioeconomic": transform_socioeconomic(input_dir / SOURCE_FILES["socioeconomic"]),
        "fact_trade_product": transform_trade(input_dir / SOURCE_FILES["trade_product"]),
        "fact_company": transform_companies(company_file),
        "fact_infrastructure": transform_infrastructure(company_file),
    }

    quality_report = validate_tables(tables)

    for name, frame in tables.items():
        frame.to_csv(output_dir / f"{name}.csv", index=False, date_format="%Y-%m-%d")

    with (output_dir / "data_quality_report.json").open("w", encoding="utf-8") as file:
        json.dump(quality_report, file, indent=2, default=str)

    if load_sql:
        load_to_azure_sql(tables)

    return tables

