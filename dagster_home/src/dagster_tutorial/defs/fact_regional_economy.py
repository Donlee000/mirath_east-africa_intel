from pathlib import Path

import dagster as dg
import pandas as pd


@dg.asset(
    name="FACT_REGIONAL_ECONOMY",
    group_name="economic_data",
    deps=[dg.AssetKey("FACT_MACRO")],
    description="Annual economic totals for the Eastern Africa region.",
)
def fact_regional_economy(
    context: dg.AssetExecutionContext,
) -> pd.DataFrame:
    macro_file = Path("data") / "fact_macro.csv"

    if not macro_file.exists():
        raise FileNotFoundError(
            "FACT_MACRO must be materialized before "
            "FACT_REGIONAL_ECONOMY."
        )

    macro = pd.read_csv(macro_file)

    # Estimate population using GDP divided by GDP per capita.
    macro["estimated_population"] = (
        macro["gdp_usd"] / macro["gdp_per_capita_usd"]
    )

    regional_rows = []

    for year, annual_data in macro.groupby("year"):
        regional_gdp = annual_data["gdp_usd"].sum(min_count=1)

        regional_population = annual_data[
            "estimated_population"
        ].sum(min_count=1)

        if pd.notna(regional_gdp) and regional_population > 0:
            regional_per_capita = (
                regional_gdp / regional_population
            )
        else:
            regional_per_capita = None

        growth_data = annual_data.dropna(
            subset=["gdp_usd", "gdp_growth_pct"]
        )

        if not growth_data.empty:
            weighted_growth = (
                growth_data["gdp_growth_pct"]
                * growth_data["gdp_usd"]
            ).sum() / growth_data["gdp_usd"].sum()
        else:
            weighted_growth = None

        regional_rows.append(
            {
                "region_code": "EAF",
                "region_name": "Eastern Africa",
                "year": int(year),
                "regional_gdp_usd": regional_gdp,
                "regional_gdp_per_capita_usd": regional_per_capita,
                "regional_gdp_growth_pct": weighted_growth,
                "countries_reporting": int(
                    annual_data["gdp_usd"].notna().sum()
                ),
            }
        )

    dataframe = pd.DataFrame(regional_rows)
    dataframe = dataframe.sort_values("year").reset_index(drop=True)

    output_directory = Path("data")
    output_directory.mkdir(exist_ok=True)

    output_file = (
        output_directory / "fact_regional_economy.csv"
    )
    dataframe.to_csv(output_file, index=False)

    context.add_output_metadata(
        {
            "region": "Eastern Africa",
            "number_of_years": len(dataframe),
            "number_of_rows": len(dataframe),
            "output_file": str(output_file.resolve()),
        }
    )

    return dataframe