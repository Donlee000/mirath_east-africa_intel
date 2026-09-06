# Corporate Expansion & Real Estate Opportunity Intelligence System

## Project Objective

The objective of this project is to identify companies, industries and markets across East Africa that demonstrate strong economic, trade, investment, expansion and infrastructure signals, and determine where these signals may translate into future commercial and industrial real estate demand.

The system is designed around a core investment question:

> **Which companies and sectors are demonstrating the strongest expansion signals across East Africa, and where could this expansion create future commercial and industrial real estate opportunities?**

Rather than analysing economic indicators in isolation, the project combines macroeconomic, sector, trade, company, investment and infrastructure intelligence to identify markets where corporate activity and economic growth may generate future demand for:

- Industrial and logistics space
- Warehousing and distribution facilities
- Office space
- Retail and commercial property
- Manufacturing facilities
- Data centres and technology infrastructure
- Other specialised commercial real estate

## Key Questions

The platform is designed to answer questions such as:

- Which countries and regions are experiencing the strongest economic growth?
- Which industries are expanding most rapidly?
- Which markets are becoming increasingly important for regional and international trade?
- Which companies are expanding, investing or establishing new operations?
- Where are major infrastructure and industrial developments taking place?
- Which sectors are attracting investment?
- Which locations show the strongest combination of economic, corporate and infrastructure activity?
- Where could these expansion signals translate into future real estate demand?

## Methodology

The project combines multiple sources of economic and commercial intelligence into a single analytical framework.

The analysis considers:

1. **Macroeconomic Intelligence**
   - GDP growth
   - GDP per capita
   - Inflation
   - Population
   - Foreign direct investment

2. **Trade Intelligence**
   - Imports
   - Exports
   - Trade growth
   - Trade intensity
   - Trading partners
   - Product composition

3. **Sector Intelligence**
   - Sector contribution to GDP
   - Sector growth
   - Manufacturing
   - Construction
   - Wholesale and retail
   - Transport and logistics
   - ICT
   - Financial services
   - Other strategically relevant sectors

4. **Company Intelligence**
   - Company presence
   - Expansion activity
   - New facilities
   - Market entry
   - Corporate investment
   - Industry classification
   - Geographic location

5. **Investment Intelligence**
   - Investment announcements
   - New projects
   - Foreign investment
   - Industrial developments
   - Corporate capital expenditure

6. **Infrastructure Intelligence**
   - Industrial parks
   - Special Economic Zones
   - Ports
   - Airports
   - Logistics corridors
   - Roads and rail infrastructure
   - Energy and utility projects
   - Other strategic infrastructure

## Data Pipeline

The project uses an automated data pipeline to collect, process and analyse information from multiple data sources.

### Architecture

```text
External APIs & Data Sources
            ↓
          Dagster
            ↓
       Python ETL
            ↓
   Extract → Clean → Validate
            ↓
       Transform
            ↓
        Azure SQL
     Data Warehouse
            ↓
     SQL Analytics Layer
            ↓
   Opportunity Scoring
            ↓
         Power BI
            ↓
 Commercial Intelligence
