from pathlib import Path

START_YEAR = 2020
END_YEAR = 2024

TARGET_COUNTRIES = (
    "Burundi",
    "Comoros",
    "DRC Congo",
    "Djibouti",
    "Eritrea",
    "Ethiopia",
    "Kenya",
    "Madagascar",
    "Malawi",
    "Mauritius",
    "Mozambique",
    "Rwanda",
    "Seychelles",
    "Somalia",
    "South Sudan",
    "Tanzania",
    "Uganda",
    "Zambia",
    "Zimbabwe",
)

COUNTRY_ALIASES = {
    "Congo, Dem. Rep.": "DRC Congo",
    "Democratic Republic of the Congo": "DRC Congo",
    "United Republic of Tanzania": "Tanzania",
    "Tanzania, United Republic of": "Tanzania",
}

SOURCE_FILES = {
    "demographic": "East_Africa_Demographic_Indicators.xlsx",
    "macro": "East_Africa_Macro_Indicators.xlsx",
    "socioeconomic": "East_Africa_Socioeconomic_Indicators.xlsx",
    "trade_product": "East_Africa_Trade_by_Product.xlsx",
    "company_infrastructure": "Castle_East_Africa_Company_Infrastructure_Tracker.xlsx",
}


def default_project_root() -> Path:
    return Path(__file__).resolve().parents[2]

