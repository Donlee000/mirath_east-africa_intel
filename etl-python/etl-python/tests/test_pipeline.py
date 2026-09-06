from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "src"))

from mirath_etl.config import END_YEAR, START_YEAR, TARGET_COUNTRIES
from mirath_etl.pipeline import run_pipeline


def test_pipeline_scope_and_keys(tmp_path):
    tables = run_pipeline(
        input_dir=PROJECT_ROOT / "data" / "raw",
        output_dir=tmp_path,
    )

    for name in ("fact_demographic", "fact_macro", "fact_socioeconomic"):
        assert set(tables[name]["country"]).issubset(TARGET_COUNTRIES)
        assert tables[name]["year"].between(START_YEAR, END_YEAR).all()

    assert len(set(tables["fact_macro"]["country"])) == 19
    assert "United Arab Emirates" not in set(tables["fact_macro"]["country"])
    assert not tables["fact_macro"].duplicated(["country", "year"]).any()
    assert not tables["fact_trade_product"].duplicated(
        ["country", "year", "product_group", "grouping_level"]
    ).any()

