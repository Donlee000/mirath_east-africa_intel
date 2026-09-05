from pathlib import Path

import dagster as dg
import pandas as pd
import requests


START_YEAR = 2020
END_YEAR = 2024

INDICATORS = {
    "gdp_usd": "NY.GDP.MKTP.CD",
    "gdp_growth_pct": "NY.GDP.MKTP.KD.ZG",
    "gdp_per_capita_usd": "NY.GDP.PCAP.CD",
    "inflation_pct": "FP.CPI.TOTL.ZG",
    "fdi_net_inflows_pct_gdp": "BX.KLT.DINV.WD.GD.ZS",
}


@dg.asset(
    name="FACT_MACRO",
    group_name="economic_data",
    deps=[dg.AssetKey("DIM_COUNTRY")],
    description="Macroeconomic indicators for the selected countries from 2020 to 2024.",
)
def fact_macro(context: dg.AssetExecutionContext) -> pd.DataFrame:
    country_file = Path("data") / "dim_country.csv"

    if not country_file.exists():
        raise FileNotFoundError(
            "DIM_COUNTRY must be materialized before FACT_MACRO."
        )

    countries = pd.read_csv(country_file)
    country_codes = countries["country_code"].tolist()

    # Create one row for every country and year, including missing observations.
    rows = {}

    for country in countries.to_dict(orient="records"):
        for year in range(START_YEAR, END_YEAR + 1):
            key = (country["country_code"], year)

            rows[key] = {
                "country_code": country["country_code"],
                "country_name": country["country_name"],
                "year": year,
                "gdp_usd": None,
                "gdp_growth_pct": None,
                "gdp_per_capita_usd": None,
                "inflation_pct": None,
                "fdi_net_inflows_pct_gdp": None,
            }

    api_countries = ";".join(country_codes)
    api_base_url = "https://api.worldbank.org/v2"

    for column_name, indicator_code in INDICATORS.items():
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
                f"Unexpected World Bank response for {indicator_code}"
            )

        observations = payload[1] or []

        for observation in observations:
            country_code = observation.get("countryiso3code")
            year = int(observation["date"])
            key = (country_code, year)

            if key in rows:
                rows[key][column_name] = observation.get("value")

    dataframe = pd.DataFrame(rows.values())

    dataframe = dataframe.sort_values(
        by=["country_name", "year"]
    ).reset_index(drop=True)

    output_directory = Path("data")
    output_directory.mkdir(exist_ok=True)

    output_file = output_directory / "fact_macro.csv"
    dataframe.to_csv(output_file, index=False)

    missing_values = int(
        dataframe[list(INDICATORS.keys())].isna().sum().sum()
    )

    context.add_output_metadata(
        {
            "start_year": START_YEAR,
            "end_year": END_YEAR,
            "number_of_countries": len(country_codes),
            "number_of_rows": len(dataframe),
            "missing_indicator_values": missing_values,
            "output_file": str(output_file.resolve()),
        }
    )

    return dataframe