# Mirath East Africa Python ETL

This folder converts five curated Excel source workbooks into standardized, validated tables for Azure SQL Database and Power BI. It enforces the investment-analysis scope of 19 East African countries and the 2020–2024 period, normalizes inconsistent country names and Excel headers, removes UAE and 2019 from the macro source, and writes a machine-readable quality report alongside the processed CSV files.

## Repository structure

```text
etl-python/
├── data/
│   ├── raw/                 # Original Excel source snapshots
│   └── processed/           # Generated CSVs and quality report (not committed)
├── src/mirath_etl/
│   ├── config.py            # Scope, source filenames and country mappings
│   ├── transforms.py        # Workbook-specific cleaning logic
│   ├── quality.py           # Coverage, null and duplicate checks
│   ├── pipeline.py          # End-to-end orchestration
│   └── sql_loader.py        # Optional Azure SQL load
├── tests/test_pipeline.py
├── requirements.txt
└── run_etl.py
```

## Run locally

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python run_etl.py
pytest
```

The pipeline creates:

- `fact_demographic.csv`
- `fact_macro.csv`
- `fact_socioeconomic.csv`
- `fact_trade_product.csv`
- `fact_company.csv`
- `fact_infrastructure.csv`
- `data_quality_report.json`

## Load to Azure SQL

Keep credentials outside the repository. Set a SQLAlchemy-compatible ODBC connection string in an environment variable, then enable the loader:

```powershell
$env:AZURE_SQL_CONNECTION_STRING="mssql+pyodbc://..."
python run_etl.py --load-sql
```

## Important data limitations

- Socioeconomic source coverage ends in 2023, so 2024 is reported as a source gap rather than fabricated.
- The WITS product workbook is a 2023 snapshot. After UAE is removed, it covers 16 of the 19 target countries; Burundi, Ethiopia and Malawi are missing.
- Blank source values remain null. They are never converted to zero.
- Company and infrastructure records are curated web-research observations. The ETL filters them to source/signal years 2020–2024 and retains their citations.
