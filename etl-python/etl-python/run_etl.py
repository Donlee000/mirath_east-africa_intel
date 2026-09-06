from __future__ import annotations

import argparse
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from mirath_etl import run_pipeline


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Clean and validate the Mirath East Africa Excel datasets."
    )
    parser.add_argument("--input-dir", type=Path, default=None)
    parser.add_argument("--output-dir", type=Path, default=None)
    parser.add_argument(
        "--load-sql",
        action="store_true",
        help="Load processed tables to Azure SQL using AZURE_SQL_CONNECTION_STRING.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_args()
    results = run_pipeline(
        input_dir=arguments.input_dir,
        output_dir=arguments.output_dir,
        load_sql=arguments.load_sql,
    )
    for table_name, table in results.items():
        print(f"{table_name}: {len(table):,} rows")

