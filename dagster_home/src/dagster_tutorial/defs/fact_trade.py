from pathlib import Path

import dagster as dg
import pandas as pd
import requests


START_YEAR = 2020
END_YEAR = 2024

TRADE_INDICATORS = {
    "imports_usd": "NE.IMP.GNFS.CD",
    "exports_usd": "NE.EXP.GNFS.CD",
    "import_growth_pct": "NE.IMP.GNFS.KD.ZG",
    "export_growth_pct": "NE.EXP.GNFS.KD.ZG",
}


@dg.asset(
    name="FACT_TRADE",
    group_name="trade_data",
    deps=[
        dg.AssetKey("DIM_COUNTRY"),
        dg.AssetKey("FACT_SECTOR"),
    ],
    description="Country-level trade indicators from 2020 to 2024.",
)
def fact_trade(
    context: dg.AssetExecutionContext,
) -> pd.DataFrame:
    country_file = Path("data") / "dim_country.csv"

    if not country_file.exists():
        raise FileNotFoundError(
            "DIM_COUNTRY must be materialized before FACT_TRADE."
        )

    countries = pd.read_csv(country_file)
    country_codes = countries["country_code"].tolist()

    rows = {}

    for country in countries.to_dict(orient="records"):
        for year in range(START_YEAR, END_YEAR + 1):
            key = (country["country_code"], year)

            rows[key] = {
                "country_code": country["country_code"],
                "country_name": country["country_name"],
                "year": year,
                "imports_usd": None,
                "exports_usd": None,
                "import_growth_pct": None,
                "export_growth_pct": None,
            }

    api_countries = ";".join(country_codes)
    api_base_url = "https://api.worldbank.org/v2"

    for column_name, indicator_code in TRADE_INDICATORS.items():
        url = (
            f"{api_base_url}/country/{api_countries}"
            f"/indicator/{indicator_code}"
        )

        response = requests.get(
            url,
            params={
                "format": "json",
                "date": f"{START_YEAR}:{END_YEAR}",
                "per_page": 20000,
            },
            timeout=60,
        )
        response.raise_for_status()

        payload = response.json()

        if not isinstance(payload, list) or len(payload) < 2:
            raise RuntimeError(
                f"Unexpected API response for {indicator_code}"
            )

        for observation in payload[1] or []:
            country_code = observation.get("countryiso3code")
            year = int(observation["date"])
            key = (country_code, year)

            if key in rows:
                rows[key][column_name] = observation.get("value")

    dataframe = pd.DataFrame(rows.values())

    dataframe["trade_balance_usd"] = (
        dataframe["exports_usd"] - dataframe["imports_usd"]
    )

    dataframe["total_trade_usd"] = (
        dataframe["exports_usd"] + dataframe["imports_usd"]
    )

    # These require detailed WITS product and partner records.
    dataframe["product_share_pct"] = pd.NA
    dataframe["partner_share_pct"] = pd.NA
    dataframe["rca"] = pd.NA

    dataframe = dataframe.sort_values(
        ["country_name", "year"]
    ).reset_index(drop=True)

    output_directory = Path("data")
    output_directory.mkdir(exist_ok=True)

    output_file = output_directory / "fact_trade.csv"
    dataframe.to_csv(output_file, index=False)

    missing_values = int(
        dataframe[list(TRADE_INDICATORS)].isna().sum().sum()
    )

    context.add_output_metadata(
        {
            "start_year": START_YEAR,
            "end_year": END_YEAR,
            "number_of_countries": len(country_codes),
            "number_of_rows": len(dataframe),
            "missing_core_values": missing_values,
            "granular_wits_metrics": "Pending enrichment",
            "output_file": str(output_file.resolve()),
        }
    )

    return dataframe