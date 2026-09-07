# Azure SQL Data Warehouse

This folder contains the Azure SQL implementation for the East Africa Investment Intelligence project. The SQL pipeline creates the database schemas, staging tables, country dimension, validation queries, analytical views, and country-ranking outputs used for investment analysis and Power BI reporting.

## Purpose

The Azure SQL database provides a structured analytical layer for evaluating economic growth, demographic trends, trade activity, corporate expansion, infrastructure development, and potential real estate demand across 19 East African countries.

## Data Pipeline

The project follows this process:

1. Source data is collected and stored in Excel workbooks.
2. Python extracts, cleans, standardises, and validates the data.
3. The ETL pipeline loads the transformed data into Azure SQL staging tables.
4. SQL views combine the datasets into analysis-ready outputs.
5. Power BI connects to the analytical views for reporting and visualisation.

## Database Structure

The database uses three schemas:

- `stg` — stores cleaned data loaded by the Python ETL pipeline.
- `analytics` — contains the country dimension and analytical views.
- `audit` — reserved for future pipeline monitoring and audit records.

## Staging Tables

| Table | Description | Loaded rows |
|---|---|---:|
| `stg.fact_demographic` | Population and demographic indicators | 95 |
| `stg.fact_macro` | GDP, inflation, economic growth and FDI | 95 |
| `stg.fact_socioeconomic` | Income, poverty, debt and socioeconomic indicators | 76 |
| `stg.fact_trade_product` | Product-level trade and tariff information | 336 |
| `stg.fact_company` | Corporate expansion and investment signals | 47 |
| `stg.fact_infrastructure` | Infrastructure and industrial development projects | 17 |

## Data Coverage

- Macro indicators: 2020–2024
- Demographic indicators: 2020–2024
- Socioeconomic indicators: 2020–2023
- Trade information: 2023 snapshot
- Company and infrastructure signals: source-dependent records within the project scope

## Analytical Views

| View | Description | Rows |
|---|---|---:|
| `analytics.vw_country_year_indicators` | Combined economic, demographic and socioeconomic indicators by country and year | 95 |
| `analytics.vw_country_investment_summary` | Country-level company and infrastructure summary | 19 |
| `analytics.vw_investment_opportunities` | Detailed company investment and expansion opportunities | 47 |
| `analytics.vw_trade_opportunities` | Export, import and product-level trade rankings | 336 |
| `analytics.vw_infrastructure_opportunities` | Infrastructure projects combined with country indicators | 17 |
| `analytics.vw_country_investment_ranking` | Country comparison across investment, infrastructure, growth and FDI | 19 |

## SQL Script

The complete SQL implementation is available in:

`azure_sql_pipeline.sql`

The script contains Queries 01–20, covering:

- Database connection validation
- Schema creation
- Country dimension creation
- Staging-table creation
- Data validation
- Year-range validation
- Analytical-view creation
- Country and opportunity rankings
- Final row-count validation

## Validation Results

The final validation confirmed that all six analytical views were created successfully and returned the expected number of records. The database is therefore ready to serve as the data source for the Power BI dashboard.

## Security

Database usernames, passwords, connection strings, and other credentials are not stored in this repository. Azure SQL credentials are supplied through environment variables during the ETL process.
