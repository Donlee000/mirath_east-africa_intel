from io import BytesIO
from pathlib import Path

import dagster as dg
import pandas as pd
import requests


START_YEAR = 2020
END_YEAR = 2024

PPI_DATA_URL = (
    "https://www.worldbank.org/content/dam/PPI/documents/"
    "2024-PPI-Full-DTA.dta"
)


@dg.asset(
    name="FACT_COMPANY",
    group_name="company_data",
    deps=[dg.AssetKey("DIM_COUNTRY")],
    description=(
        "Infrastructure projects and investments in the selected "
        "countries from 2020 to 2024."
    ),
)
def fact_company(
    context: dg.AssetExecutionContext,
) -> pd.DataFrame:
    country_file = Path("data") / "dim_country.csv"

    if not country_file.exists():
        raise FileNotFoundError(
            "DIM_COUNTRY must be materialized before FACT_COMPANY."
        )

    countries = pd.read_csv(country_file)
    selected_countries = set(countries["country_name"])

    country_code_lookup = dict(
        zip(
            countries["country_name"],
            countries["country_code"],
        )
    )

    response = requests.get(PPI_DATA_URL, timeout=180)
    response.raise_for_status()

    source = pd.read_stata(BytesIO(response.content))

    source["IY"] = pd.to_numeric(
        source["IY"],
        errors="coerce",
    )

    filtered = source[
        source["country"].isin(selected_countries)
        & source["IY"].between(START_YEAR, END_YEAR)
    ].copy()

    name_text = filtered["name"].astype("string").fillna("")
    description_text = (
        filtered["Description"].astype("string").fillna("")
    )

    expansion_text = (
        name_text + " " + description_text
    ).str.lower()

    filtered["expansion"] = expansion_text.str.contains(
        "expansion|phase|modernization|extension",
        regex=True,
    )

    dataframe = pd.DataFrame(
        {
            "project_id": filtered["ID"],
            "company": filtered["name"],
            "record_type": "PPI project",
            "industry": filtered["sector"],
            "subsector": filtered["ssector"],
            "country": filtered["country"],
            "investment_year": filtered["IY"].astype("Int64"),
            "project_type": filtered["stype"],
            "project_status": filtered["status_n"],
            "expansion": filtered["expansion"],
            "investment_usd_millions": pd.to_numeric(
                filtered["investment"],
                errors="coerce",
            ),
            "description": filtered["Description"],
        }
    )

    dataframe["country_code"] = dataframe["country"].map(
        country_code_lookup
    )

    dataframe = dataframe[
        [
            "project_id",
            "company",
            "record_type",
            "industry",
            "subsector",
            "country_code",
            "country",
            "investment_year",
            "project_type",
            "project_status",
            "expansion",
            "investment_usd_millions",
            "description",
        ]
    ]

    dataframe = dataframe.sort_values(
        ["investment_year", "country", "company"]
    ).reset_index(drop=True)

    output_directory = Path("data")
    output_directory.mkdir(exist_ok=True)

    output_file = output_directory / "fact_company.csv"
    dataframe.to_csv(output_file, index=False)

    total_investment = dataframe[
        "investment_usd_millions"
    ].sum(skipna=True)

    context.add_output_metadata(
        {
            "start_year": START_YEAR,
            "end_year": END_YEAR,
            "number_of_records": len(dataframe),
            "countries_with_projects": dataframe[
                "country"
            ].nunique(),
            "total_investment_usd_millions": float(
                total_investment
            ),
            "output_file": str(output_file.resolve()),
        }
    )

    return dataframe