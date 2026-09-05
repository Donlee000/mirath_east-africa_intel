from pathlib import Path

import dagster as dg
import pandas as pd


@dg.asset(
    name="DIM_COUNTRY",
    group_name="economic_data",
    description="Countries included in the regional economic data platform.",
)
def dim_country(context: dg.AssetExecutionContext) -> pd.DataFrame:
    countries = [
        {"country_code": "BDI", "country_name": "Burundi", "capital": "Gitega"},
        {"country_code": "COM", "country_name": "Comoros", "capital": "Moroni"},
        {"country_code": "DJI", "country_name": "Djibouti", "capital": "Djibouti City"},
        {"country_code": "ERI", "country_name": "Eritrea", "capital": "Asmara"},
        {"country_code": "ETH", "country_name": "Ethiopia", "capital": "Addis Ababa"},
        {"country_code": "KEN", "country_name": "Kenya", "capital": "Nairobi"},
        {
            "country_code": "MDG",
            "country_name": "Madagascar",
            "capital": "Antananarivo",
        },
        {"country_code": "MWI", "country_name": "Malawi", "capital": "Lilongwe"},
        {"country_code": "MUS", "country_name": "Mauritius", "capital": "Port Louis"},
        {"country_code": "MOZ", "country_name": "Mozambique", "capital": "Maputo"},
        {"country_code": "RWA", "country_name": "Rwanda", "capital": "Kigali"},
        {"country_code": "SYC", "country_name": "Seychelles", "capital": "Victoria"},
        {"country_code": "SOM", "country_name": "Somalia", "capital": "Mogadishu"},
        {"country_code": "SSD", "country_name": "South Sudan", "capital": "Juba"},
        {"country_code": "TZA", "country_name": "Tanzania", "capital": "Dodoma"},
        {"country_code": "UGA", "country_name": "Uganda", "capital": "Kampala"},
        {"country_code": "ZMB", "country_name": "Zambia", "capital": "Lusaka"},
        {"country_code": "ZWE", "country_name": "Zimbabwe", "capital": "Harare"},
    ]

    dataframe = pd.DataFrame(countries)

    output_directory = Path("data")
    output_directory.mkdir(exist_ok=True)

    output_file = output_directory / "dim_country.csv"
    dataframe.to_csv(output_file, index=False)

    context.add_output_metadata(
        {
            "number_of_countries": len(dataframe),
            "output_file": str(output_file.resolve()),
        }
    )

    return dataframe