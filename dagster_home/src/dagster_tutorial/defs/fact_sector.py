from pathlib import Path

import dagster as dg
import pandas as pd


SECTORS = [
    {
        "sector_code": "MAN",
        "sector_name": "Manufacturing",
        "wits_supported": True,
        "measurement_basis": "Merchandise trade product groups",
    },
    {
        "sector_code": "LOG",
        "sector_name": "Logistics",
        "wits_supported": False,
        "measurement_basis": "Requires logistics or services data",
    },
    {
        "sector_code": "RET",
        "sector_name": "Retail",
        "wits_supported": False,
        "measurement_basis": "Requires retail or services data",
    },
    {
        "sector_code": "PHA",
        "sector_name": "Pharma",
        "wits_supported": True,
        "measurement_basis": "Pharmaceutical product trade",
    },
    {
        "sector_code": "TEC",
        "sector_name": "Technology",
        "wits_supported": True,
        "measurement_basis": "Technology-related product trade",
    },
    {
        "sector_code": "CON",
        "sector_name": "Construction",
        "wits_supported": False,
        "measurement_basis": "Requires construction-sector data",
    },
]


@dg.asset(
    name="FACT_SECTOR",
    group_name="trade_data",
    deps=[dg.AssetKey("DIM_COUNTRY")],
    description="Sector coverage for every country in the target region.",
)
def fact_sector(
    context: dg.AssetExecutionContext,
) -> pd.DataFrame:
    country_file = Path("data") / "dim_country.csv"

    if not country_file.exists():
        raise FileNotFoundError(
            "DIM_COUNTRY must be materialized before FACT_SECTOR."
        )

    countries = pd.read_csv(country_file)

    rows = []

    for country in countries.to_dict(orient="records"):
        for sector in SECTORS:
            rows.append(
                {
                    "country_code": country["country_code"],
                    "country_name": country["country_name"],
                    **sector,
                    "primary_source": (
                        "WITS"
                        if sector["wits_supported"]
                        else "Source required"
                    ),
                }
            )

    dataframe = pd.DataFrame(rows)

    output_directory = Path("data")
    output_directory.mkdir(exist_ok=True)

    output_file = output_directory / "fact_sector.csv"
    dataframe.to_csv(output_file, index=False)

    context.add_output_metadata(
        {
            "number_of_countries": dataframe[
                "country_code"
            ].nunique(),
            "number_of_sectors": dataframe[
                "sector_code"
            ].nunique(),
            "number_of_rows": len(dataframe),
            "wits_supported_sectors": int(
                dataframe.loc[
                    dataframe["wits_supported"],
                    "sector_code",
                ].nunique()
            ),
            "output_file": str(output_file.resolve()),
        }
    )

    return dataframe