
SELECT
    DB_NAME() AS database_name,
    GETUTCDATE() AS connection_time;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'audit'
)
BEGIN
    EXEC('CREATE SCHEMA audit');
END;
GO

SELECT name AS schema_name
FROM sys.schemas
WHERE name IN ('stg', 'analytics', 'audit')
ORDER BY name;
GO


IF OBJECT_ID('analytics.dim_country', 'U') IS NULL
BEGIN
    CREATE TABLE analytics.dim_country (
        country_key INT IDENTITY(1,1) PRIMARY KEY,
        country_code CHAR(3) NOT NULL,
        country_name NVARCHAR(100) NOT NULL,
        capital NVARCHAR(100) NULL,
        investment_region NVARCHAR(100) NOT NULL,

        CONSTRAINT uq_dim_country_code
            UNIQUE (country_code),

        CONSTRAINT uq_dim_country_name
            UNIQUE (country_name)
    );
END;
GO

MERGE analytics.dim_country AS target
USING (
    VALUES
        ('BDI', 'Burundi',     'Gitega',        'East and Central Africa'),
        ('COM', 'Comoros',     'Moroni',        'East and Central Africa'),
        ('COD', 'DRC Congo',   'Kinshasa',      'East and Central Africa'),
        ('DJI', 'Djibouti',    'Djibouti City', 'East and Central Africa'),
        ('ERI', 'Eritrea',     'Asmara',        'East and Central Africa'),
        ('ETH', 'Ethiopia',    'Addis Ababa',   'East and Central Africa'),
        ('KEN', 'Kenya',       'Nairobi',        'East and Central Africa'),
        ('MDG', 'Madagascar',  'Antananarivo',  'East and Central Africa'),
        ('MWI', 'Malawi',      'Lilongwe',       'East and Central Africa'),
        ('MUS', 'Mauritius',   'Port Louis',     'East and Central Africa'),
        ('MOZ', 'Mozambique',  'Maputo',         'East and Central Africa'),
        ('RWA', 'Rwanda',      'Kigali',         'East and Central Africa'),
        ('SYC', 'Seychelles',  'Victoria',       'East and Central Africa'),
        ('SOM', 'Somalia',     'Mogadishu',      'East and Central Africa'),
        ('SSD', 'South Sudan', 'Juba',           'East and Central Africa'),
        ('TZA', 'Tanzania',    'Dodoma',         'East and Central Africa'),
        ('UGA', 'Uganda',      'Kampala',        'East and Central Africa'),
        ('ZMB', 'Zambia',      'Lusaka',         'East and Central Africa'),
        ('ZWE', 'Zimbabwe',    'Harare',         'East and Central Africa')
) AS source (
    country_code,
    country_name,
    capital,
    investment_region
)
ON target.country_code = source.country_code

WHEN MATCHED THEN
    UPDATE SET
        target.country_name = source.country_name,
        target.capital = source.capital,
        target.investment_region = source.investment_region

WHEN NOT MATCHED THEN
    INSERT (
        country_code,
        country_name,
        capital,
        investment_region
    )
    VALUES (
        source.country_code,
        source.country_name,
        source.capital,
        source.investment_region
    );
GO

SELECT *
FROM analytics.dim_country
ORDER BY country_name;
GO


IF OBJECT_ID('stg.fact_macro', 'U') IS NULL
BEGIN
    CREATE TABLE stg.fact_macro (
        country NVARCHAR(100) NOT NULL,
        [year] SMALLINT NOT NULL,

        gdp_current_usd DECIMAL(28,6) NULL,
        gdp_growth_pct_annual DECIMAL(18,6) NULL,
        gdp_per_capita_current_usd DECIMAL(28,6) NULL,
        inflation_consumer_prices_pct_annual DECIMAL(18,6) NULL,
        fdi_net_inflows_pct_of_gdp DECIMAL(18,6) NULL,

        loaded_at DATETIME2 NOT NULL
            CONSTRAINT df_fact_macro_loaded_at
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT pk_fact_macro
            PRIMARY KEY (country, [year]),

        CONSTRAINT ck_fact_macro_year
            CHECK ([year] BETWEEN 2020 AND 2024),

        CONSTRAINT fk_fact_macro_country
            FOREIGN KEY (country)
            REFERENCES analytics.dim_country(country_name)
    );
END;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_macro'
ORDER BY ORDINAL_POSITION;
GO



IF OBJECT_ID('stg.fact_demographic', 'U') IS NULL
BEGIN
    CREATE TABLE stg.fact_demographic (
        country NVARCHAR(100) NOT NULL,
        [year] SMALLINT NOT NULL,

        fertility_rate_total_births_per_woman DECIMAL(18,6) NULL,
        life_expectancy_at_birth_total_years DECIMAL(18,6) NULL,
        mortality_rate_infant_per_1_000_live_births DECIMAL(18,6) NULL,
        prevalence_of_hiv_total_pct_of_population_ages_15_49
            DECIMAL(18,6) NULL,
        population_growth_annual_pct DECIMAL(18,6) NULL,
        population_aged_15_24_years_thousands DECIMAL(28,6) NULL,
        population_aged_25_64_years_thousands DECIMAL(28,6) NULL,
        population_aged_65_years_or_older_thousands DECIMAL(28,6) NULL,
        rural_population_pct_of_total_population DECIMAL(18,6) NULL,

        loaded_at DATETIME2 NOT NULL
            CONSTRAINT df_fact_demographic_loaded_at
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT pk_fact_demographic
            PRIMARY KEY (country, [year]),

        CONSTRAINT ck_fact_demographic_year
            CHECK ([year] BETWEEN 2020 AND 2024),

        CONSTRAINT fk_fact_demographic_country
            FOREIGN KEY (country)
            REFERENCES analytics.dim_country(country_name)
    );
END;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_demographic'
ORDER BY ORDINAL_POSITION;
GO



IF OBJECT_ID('stg.fact_socioeconomic', 'U') IS NULL
BEGIN
    CREATE TABLE stg.fact_socioeconomic (
        country NVARCHAR(100) NOT NULL,
        [year] SMALLINT NOT NULL,

        gdp_current_usd DECIMAL(28,6) NULL,
        gdp_current_lcu DECIMAL(28,6) NULL,
        gdp_growth_annual_pct DECIMAL(18,6) NULL,
        gdp_ppp_current_international_usd DECIMAL(28,6) NULL,
        gdp_at_market_prices_constant_2010_usd DECIMAL(28,6) NULL,
        gdp_constant_lcu DECIMAL(28,6) NULL,
        gdp_ppp_constant_2011_international_usd DECIMAL(28,6) NULL,
        gdp_deflator_base_year_varies_by_country DECIMAL(28,6) NULL,
        gdp_per_capita_current_usd DECIMAL(28,6) NULL,
        gdp_per_capita_current_lcu DECIMAL(28,6) NULL,
        gdp_per_capita_ppp_current_international_usd DECIMAL(28,6) NULL,
        gdp_per_capita_ppp_constant_2011_international_usd
            DECIMAL(28,6) NULL,
        gni_per_capita_atlas_method_current_usd DECIMAL(28,6) NULL,
        gni_per_capita_ppp_current_international_usd DECIMAL(28,6) NULL,
        gni_per_capita_current_lcu DECIMAL(28,6) NULL,
        gni_current_lcu DECIMAL(28,6) NULL,
        poverty_headcount_ratio_at_usd_3_20_a_day_ppp_pct_of_population
            DECIMAL(18,6) NULL,
        total_debt_service_pct_of_gni DECIMAL(18,6) NULL,
        general_government_total_expenditure_current_lcu
            DECIMAL(28,6) NULL,
        ppp_conversion_factor_gdp_lcu_per_international_usd
            DECIMAL(28,6) NULL,
        dec_alternative_conversion_factor_lcu_per_usd
            DECIMAL(28,6) NULL,
        official_exchange_rate_lcu_per_usd_period_average
            DECIMAL(28,6) NULL,
        price_level_ratio_of_ppp_conversion_factor_gdp_to_market_exchange_rate
            DECIMAL(18,6) NULL,
        ppp_conversion_factor_private_consumption_lcu_per_international_usd
            DECIMAL(28,6) NULL,

        loaded_at DATETIME2 NOT NULL
            CONSTRAINT df_fact_socioeconomic_loaded_at
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT pk_fact_socioeconomic
            PRIMARY KEY (country, [year]),

        CONSTRAINT ck_fact_socioeconomic_year
            CHECK ([year] BETWEEN 2020 AND 2024),

        CONSTRAINT fk_fact_socioeconomic_country
            FOREIGN KEY (country)
            REFERENCES analytics.dim_country(country_name)
    );
END;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_socioeconomic'
ORDER BY ORDINAL_POSITION;
GO



IF OBJECT_ID('stg.fact_trade_product', 'U') IS NULL
BEGIN
    CREATE TABLE stg.fact_trade_product (
        trade_product_key BIGINT IDENTITY(1,1) PRIMARY KEY,

        country NVARCHAR(100) NOT NULL,
        [year] SMALLINT NOT NULL,
        product_group NVARCHAR(500) NOT NULL,
        grouping_level NVARCHAR(100) NOT NULL,

        export_usd_thousand DECIMAL(28,6) NULL,
        import_usd_thousand DECIMAL(28,6) NULL,
        trade_balance_usd_thousand DECIMAL(28,6) NULL,
        export_product_share_pct DECIMAL(18,6) NULL,
        import_product_share_pct DECIMAL(18,6) NULL,

        ahs_simple_average_pct DECIMAL(18,6) NULL,
        ahs_weighted_average_pct DECIMAL(18,6) NULL,
        ahs_total_tariff_lines DECIMAL(28,6) NULL,
        ahs_dutiable_tariff_lines_share_pct DECIMAL(18,6) NULL,
        ahs_duty_free_tariff_lines_share_pct DECIMAL(18,6) NULL,
        ahs_specific_tariff_lines_share_pct DECIMAL(18,6) NULL,
        ahs_ave_tariff_lines_share_pct DECIMAL(18,6) NULL,
        ahs_maxrate_pct DECIMAL(18,6) NULL,
        ahs_minrate_pct DECIMAL(18,6) NULL,
        ahs_specificduty_imports_usd_thousand DECIMAL(28,6) NULL,
        ahs_dutiable_imports_usd_thousand DECIMAL(28,6) NULL,
        ahs_duty_free_imports_usd_thousand DECIMAL(28,6) NULL,

        mfn_simple_average_pct DECIMAL(18,6) NULL,
        mfn_weighted_average_pct DECIMAL(18,6) NULL,
        mfn_total_tariff_lines DECIMAL(28,6) NULL,
        mfn_dutiable_tariff_lines_share_pct DECIMAL(18,6) NULL,
        mfn_duty_free_tariff_lines_share_pct DECIMAL(18,6) NULL,
        mfn_specific_tariff_lines_share_pct DECIMAL(18,6) NULL,
        mfn_ave_tariff_lines_share_pct DECIMAL(18,6) NULL,
        mfn_maxrate_pct DECIMAL(18,6) NULL,
        mfn_minrate_pct DECIMAL(18,6) NULL,
        mfn_specificduty_imports_usd_thousand DECIMAL(28,6) NULL,
        mfn_dutiable_imports_usd_thousand DECIMAL(28,6) NULL,
        mfn_duty_free_imports_usd_thousand DECIMAL(28,6) NULL,

        loaded_at DATETIME2 NOT NULL
            CONSTRAINT df_fact_trade_product_loaded_at
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT ck_fact_trade_product_year
            CHECK ([year] BETWEEN 2020 AND 2024),

        CONSTRAINT fk_fact_trade_product_country
            FOREIGN KEY (country)
            REFERENCES analytics.dim_country(country_name),

        CONSTRAINT uq_fact_trade_product
            UNIQUE (
                country,
                [year],
                product_group,
                grouping_level
            )
    );
END;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_trade_product'
ORDER BY ORDINAL_POSITION;
GO



IF OBJECT_ID('stg.fact_company', 'U') IS NULL
BEGIN
    CREATE TABLE stg.fact_company (
        company_key BIGINT IDENTITY(1,1) PRIMARY KEY,

        country NVARCHAR(100) NOT NULL,
        company NVARCHAR(250) NOT NULL,
        industry NVARCHAR(250) NULL,
        hq NVARCHAR(250) NULL,
        east_africa_presence NVARCHAR(1000) NULL,
        expansion_signal NVARCHAR(2000) NULL,
        signal_year SMALLINT NOT NULL,
        investment_as_disclosed NVARCHAR(1000) NULL,
        investment_est_usd_million DECIMAL(28,6) NULL,
        facility_type NVARCHAR(250) NULL,

        investment_score DECIMAL(18,6) NULL,
        recency_score DECIMAL(18,6) NULL,
        facility_type_score DECIMAL(18,6) NULL,
        infrastructure_synergy_score DECIMAL(18,6) NULL,
        opportunity_score DECIMAL(18,6) NULL,

        opportunity_tier NVARCHAR(100) NULL,
        source_title NVARCHAR(1000) NULL,
        source_url NVARCHAR(2048) NULL,
        source_date DATE NULL,

        loaded_at DATETIME2 NOT NULL
            CONSTRAINT df_fact_company_loaded_at
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT ck_fact_company_signal_year
            CHECK (signal_year BETWEEN 2020 AND 2024),

        CONSTRAINT fk_fact_company_country
            FOREIGN KEY (country)
            REFERENCES analytics.dim_country(country_name)
    );
END;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_company'
ORDER BY ORDINAL_POSITION;
GO


IF OBJECT_ID('stg.fact_infrastructure', 'U') IS NULL
BEGIN
    CREATE TABLE stg.fact_infrastructure (
        infrastructure_key BIGINT IDENTITY(1,1) PRIMARY KEY,

        country NVARCHAR(100) NOT NULL,
        project_name NVARCHAR(500) NOT NULL,
        [type] NVARCHAR(150) NULL,
        [location] NVARCHAR(500) NULL,
        operator_developer NVARCHAR(1000) NULL,
        [status] NVARCHAR(2000) NULL,
        scale_capacity NVARCHAR(1000) NULL,
        source_title NVARCHAR(1000) NULL,
        source_url NVARCHAR(2048) NULL,
        source_date DATE NULL,
        source_year SMALLINT NOT NULL,

        loaded_at DATETIME2 NOT NULL
            CONSTRAINT df_fact_infrastructure_loaded_at
            DEFAULT SYSUTCDATETIME(),

        CONSTRAINT ck_fact_infrastructure_year
            CHECK (source_year BETWEEN 2020 AND 2024),

        CONSTRAINT fk_fact_infrastructure_country
            FOREIGN KEY (country)
            REFERENCES analytics.dim_country(country_name)
    );
END;
GO

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_infrastructure'
ORDER BY ORDINAL_POSITION;
GO



SELECT
    TABLE_SCHEMA AS schema_name,
    TABLE_NAME AS table_name
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_SCHEMA IN ('stg', 'analytics')
ORDER BY
    TABLE_SCHEMA,
    TABLE_NAME;
GO



ALTER TABLE stg.fact_infrastructure
ALTER COLUMN project_name NVARCHAR(500) NOT NULL;
GO

ALTER TABLE stg.fact_infrastructure
ALTER COLUMN [location] NVARCHAR(500) NULL;
GO

ALTER TABLE stg.fact_infrastructure
ALTER COLUMN operator_developer NVARCHAR(1000) NULL;
GO

ALTER TABLE stg.fact_infrastructure
ALTER COLUMN [status] NVARCHAR(2000) NULL;
GO

ALTER TABLE stg.fact_infrastructure
ALTER COLUMN scale_capacity NVARCHAR(1000) NULL;
GO

ALTER TABLE stg.fact_infrastructure
ALTER COLUMN source_title NVARCHAR(1000) NULL;
GO

ALTER TABLE stg.fact_infrastructure
ALTER COLUMN source_url NVARCHAR(2048) NULL;
GO

SELECT
    COLUMN_NAME,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'fact_infrastructure'
  AND DATA_TYPE IN ('nvarchar', 'varchar')
ORDER BY ORDINAL_POSITION;
GO



SELECT
    'fact_demographic' AS table_name,
    COUNT(*) AS row_count
FROM stg.fact_demographic

UNION ALL

SELECT
    'fact_macro',
    COUNT(*)
FROM stg.fact_macro

UNION ALL

SELECT
    'fact_socioeconomic',
    COUNT(*)
FROM stg.fact_socioeconomic

UNION ALL

SELECT
    'fact_trade_product',
    COUNT(*)
FROM stg.fact_trade_product

UNION ALL

SELECT
    'fact_company',
    COUNT(*)
FROM stg.fact_company

UNION ALL

SELECT
    'fact_infrastructure',
    COUNT(*)
FROM stg.fact_infrastructure;
GO



SELECT
    'fact_demographic' AS table_name,
    MIN([year]) AS first_year,
    MAX([year]) AS last_year,
    COUNT(DISTINCT [year]) AS number_of_years
FROM stg.fact_demographic

UNION ALL

SELECT
    'fact_macro',
    MIN([year]),
    MAX([year]),
    COUNT(DISTINCT [year])
FROM stg.fact_macro

UNION ALL

SELECT
    'fact_socioeconomic',
    MIN([year]),
    MAX([year]),
    COUNT(DISTINCT [year])
FROM stg.fact_socioeconomic

UNION ALL

SELECT
    'fact_trade_product',
    MIN([year]),
    MAX([year]),
    COUNT(DISTINCT [year])
FROM stg.fact_trade_product;
GO



CREATE OR ALTER VIEW analytics.vw_country_year_indicators
AS

WITH years AS (
    SELECT 2020 AS [year]
    UNION ALL SELECT 2021
    UNION ALL SELECT 2022
    UNION ALL SELECT 2023
    UNION ALL SELECT 2024
)

SELECT
    country.country_key,
    country.country_code,
    country.country_name,
    country.capital,
    country.investment_region,
    years.[year],

    macro.gdp_current_usd,
    macro.gdp_growth_pct_annual,
    macro.gdp_per_capita_current_usd,
    macro.inflation_consumer_prices_pct_annual,
    macro.fdi_net_inflows_pct_of_gdp,

    demographic.fertility_rate_total_births_per_woman,
    demographic.life_expectancy_at_birth_total_years,
    demographic.mortality_rate_infant_per_1_000_live_births,
    demographic.prevalence_of_hiv_total_pct_of_population_ages_15_49,
    demographic.population_growth_annual_pct,
    demographic.population_aged_15_24_years_thousands,
    demographic.population_aged_25_64_years_thousands,
    demographic.population_aged_65_years_or_older_thousands,
    demographic.rural_population_pct_of_total_population,

    socioeconomic.gdp_ppp_current_international_usd,
    socioeconomic.gni_per_capita_atlas_method_current_usd,
    socioeconomic.gni_per_capita_ppp_current_international_usd,
    socioeconomic.poverty_headcount_ratio_at_usd_3_20_a_day_ppp_pct_of_population,
    socioeconomic.total_debt_service_pct_of_gni,
    socioeconomic.official_exchange_rate_lcu_per_usd_period_average,
    socioeconomic.price_level_ratio_of_ppp_conversion_factor_gdp_to_market_exchange_rate

FROM analytics.dim_country AS country

CROSS JOIN years

LEFT JOIN stg.fact_macro AS macro
    ON macro.country = country.country_name
    AND macro.[year] = years.[year]

LEFT JOIN stg.fact_demographic AS demographic
    ON demographic.country = country.country_name
    AND demographic.[year] = years.[year]

LEFT JOIN stg.fact_socioeconomic AS socioeconomic
    ON socioeconomic.country = country.country_name
    AND socioeconomic.[year] = years.[year];
GO

SELECT TOP (100) *
FROM analytics.vw_country_year_indicators
ORDER BY country_name, [year];
GO


CREATE OR ALTER VIEW analytics.vw_country_investment_summary
AS

WITH company_summary AS (
    SELECT
        country,
        COUNT(*) AS company_signal_count,
        SUM(investment_est_usd_million)
            AS estimated_investment_usd_million,
        AVG(opportunity_score)
            AS average_opportunity_score,
        MAX(opportunity_score)
            AS highest_opportunity_score,
        MAX(signal_year)
            AS latest_company_signal_year
    FROM stg.fact_company
    GROUP BY country
),

infrastructure_summary AS (
    SELECT
        country,
        COUNT(*) AS infrastructure_project_count,
        MAX(source_year) AS latest_infrastructure_year
    FROM stg.fact_infrastructure
    GROUP BY country
)

SELECT
    country.country_key,
    country.country_code,
    country.country_name,
    country.capital,
    country.investment_region,

    COALESCE(company.company_signal_count, 0)
        AS company_signal_count,

    COALESCE(company.estimated_investment_usd_million, 0)
        AS estimated_investment_usd_million,

    company.average_opportunity_score,
    company.highest_opportunity_score,
    company.latest_company_signal_year,

    COALESCE(infrastructure.infrastructure_project_count, 0)
        AS infrastructure_project_count,

    infrastructure.latest_infrastructure_year

FROM analytics.dim_country AS country

LEFT JOIN company_summary AS company
    ON company.country = country.country_name

LEFT JOIN infrastructure_summary AS infrastructure
    ON infrastructure.country = country.country_name;
GO

SELECT *
FROM analytics.vw_country_investment_summary
ORDER BY
    highest_opportunity_score DESC,
    estimated_investment_usd_million DESC;
GO



CREATE OR ALTER VIEW analytics.vw_investment_opportunities
AS

SELECT
    company.company_key,
    company.country,
    country.country_code,
    country.capital,

    company.company,
    company.industry,
    company.hq,
    company.east_africa_presence,
    company.expansion_signal,
    company.signal_year,
    company.investment_as_disclosed,
    company.investment_est_usd_million,
    company.facility_type,

    company.investment_score,
    company.recency_score,
    company.facility_type_score,
    company.infrastructure_synergy_score,
    company.opportunity_score,
    company.opportunity_tier,

    country_summary.infrastructure_project_count,

    indicators.gdp_current_usd,
    indicators.gdp_growth_pct_annual,
    indicators.gdp_per_capita_current_usd,
    indicators.inflation_consumer_prices_pct_annual,
    indicators.fdi_net_inflows_pct_of_gdp,
    indicators.population_growth_annual_pct,

    company.source_title,
    company.source_url,
    company.source_date

FROM stg.fact_company AS company

INNER JOIN analytics.dim_country AS country
    ON country.country_name = company.country

LEFT JOIN analytics.vw_country_investment_summary AS country_summary
    ON country_summary.country_name = company.country

LEFT JOIN analytics.vw_country_year_indicators AS indicators
    ON indicators.country_name = company.country
    AND indicators.[year] = 2024;
GO

SELECT *
FROM analytics.vw_investment_opportunities
ORDER BY
    opportunity_score DESC,
    investment_est_usd_million DESC;
GO



CREATE OR ALTER VIEW analytics.vw_trade_opportunities
AS

SELECT
    trade.country,
    country.country_code,
    country.capital,
    trade.[year],
    trade.product_group,
    trade.grouping_level,

    trade.export_usd_thousand,
    trade.import_usd_thousand,
    trade.trade_balance_usd_thousand,
    trade.export_product_share_pct,
    trade.import_product_share_pct,

    trade.ahs_simple_average_pct,
    trade.ahs_weighted_average_pct,
    trade.mfn_simple_average_pct,
    trade.mfn_weighted_average_pct,

    DENSE_RANK() OVER (
        PARTITION BY trade.country, trade.grouping_level
        ORDER BY trade.export_usd_thousand DESC
    ) AS export_rank,

    DENSE_RANK() OVER (
        PARTITION BY trade.country, trade.grouping_level
        ORDER BY trade.import_usd_thousand DESC
    ) AS import_rank

FROM stg.fact_trade_product AS trade

INNER JOIN analytics.dim_country AS country
    ON country.country_name = trade.country;
GO

SELECT *
FROM analytics.vw_trade_opportunities
ORDER BY
    country,
    grouping_level,
    export_rank,
    product_group;
GO



CREATE OR ALTER VIEW analytics.vw_infrastructure_opportunities
AS

SELECT
    infrastructure.infrastructure_key,
    infrastructure.country,
    country.country_code,
    country.capital,

    infrastructure.project_name,
    infrastructure.[type],
    infrastructure.[location],
    infrastructure.operator_developer,
    infrastructure.[status],
    infrastructure.scale_capacity,
    infrastructure.source_year,

    indicators.gdp_current_usd,
    indicators.gdp_growth_pct_annual,
    indicators.gdp_per_capita_current_usd,
    indicators.fdi_net_inflows_pct_of_gdp,
    indicators.population_growth_annual_pct,

    country_summary.company_signal_count,
    country_summary.estimated_investment_usd_million,
    country_summary.highest_opportunity_score,

    infrastructure.source_title,
    infrastructure.source_url,
    infrastructure.source_date

FROM stg.fact_infrastructure AS infrastructure

INNER JOIN analytics.dim_country AS country
    ON country.country_name = infrastructure.country

LEFT JOIN analytics.vw_country_year_indicators AS indicators
    ON indicators.country_name = infrastructure.country
    AND indicators.[year] = 2024

LEFT JOIN analytics.vw_country_investment_summary AS country_summary
    ON country_summary.country_name = infrastructure.country;
GO

SELECT *
FROM analytics.vw_infrastructure_opportunities
ORDER BY
    highest_opportunity_score DESC,
    source_year DESC,
    country,
    project_name;
GO




CREATE OR ALTER VIEW analytics.vw_country_investment_ranking
AS

SELECT
    summary.country_key,
    summary.country_code,
    summary.country_name,
    summary.capital,

    summary.company_signal_count,
    summary.estimated_investment_usd_million,
    summary.average_opportunity_score,
    summary.highest_opportunity_score,
    summary.infrastructure_project_count,

    indicators.gdp_current_usd,
    indicators.gdp_growth_pct_annual,
    indicators.gdp_per_capita_current_usd,
    indicators.inflation_consumer_prices_pct_annual,
    indicators.fdi_net_inflows_pct_of_gdp,
    indicators.population_growth_annual_pct,

    DENSE_RANK() OVER (
        ORDER BY summary.highest_opportunity_score DESC
    ) AS opportunity_rank,

    DENSE_RANK() OVER (
        ORDER BY summary.estimated_investment_usd_million DESC
    ) AS investment_value_rank,

    DENSE_RANK() OVER (
        ORDER BY summary.infrastructure_project_count DESC
    ) AS infrastructure_rank,

    DENSE_RANK() OVER (
        ORDER BY indicators.gdp_growth_pct_annual DESC
    ) AS economic_growth_rank,

    DENSE_RANK() OVER (
        ORDER BY indicators.fdi_net_inflows_pct_of_gdp DESC
    ) AS fdi_rank

FROM analytics.vw_country_investment_summary AS summary

LEFT JOIN analytics.vw_country_year_indicators AS indicators
    ON indicators.country_name = summary.country_name
    AND indicators.[year] = 2024;
GO

SELECT *
FROM analytics.vw_country_investment_ranking
ORDER BY
    opportunity_rank,
    investment_value_rank,
    infrastructure_rank;
GO




SELECT
    'vw_country_year_indicators' AS view_name,
    COUNT(*) AS row_count
FROM analytics.vw_country_year_indicators

UNION ALL

SELECT
    'vw_country_investment_summary',
    COUNT(*)
FROM analytics.vw_country_investment_summary

UNION ALL

SELECT
    'vw_investment_opportunities',
    COUNT(*)
FROM analytics.vw_investment_opportunities

UNION ALL

SELECT
    'vw_trade_opportunities',
    COUNT(*)
FROM analytics.vw_trade_opportunities

UNION ALL

SELECT
    'vw_infrastructure_opportunities',
    COUNT(*)
FROM analytics.vw_infrastructure_opportunities

UNION ALL

SELECT
    'vw_country_investment_ranking',
    COUNT(*)
FROM analytics.vw_country_investment_ranking;
GO
