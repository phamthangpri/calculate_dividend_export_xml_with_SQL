# Calculate Dividend and Export XML with SQL

## Overview

This project aims to calculate dividends received by clients for a given quarter. It exports all related data and stores the output in XML files to generate PDF files and send them to clients.

## Features

- Calculate dividends for a given quarter.
- Export data to XML files.
- Generate PDFs from XML files. (not in this script)
- Send generated PDFs to clients. (not in this script)

## Prerequisites

- SQL Server (or compatible RDBMS)
- A database with the necessary tables (e.g., `table_contract`)

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/phamthangpri/calculate_dividend_export_xml_with_SQL.git
    ```
2. Import the SQL scripts into your SQL Server.

## Usage

1. **Generate XML Files by Batch**: Run the stored procedure `sp_generate_xml` to generate XML files by batch.

    ```sql
    EXEC sp_generate_xml @quarter = 'Q1', @generation_date = '2024-06-30', @year = 2024;
    ```

2. **Calculate Dividends**: Use the provided SQL scripts in the repository to calculate dividends and generate necessary reports.

## SQL Scripts

- `01-document.sp_quartly_statement.representative_create.sql` : create a table for all people who will sign PDF files
- `02-document.sp_quartly_statement.dividend_select.sql` : calculate dividends received
- `03-document.sp_quartly_statement.pei_select.sql` :  : get PEI data
- `04-document.sp_quartly_statement.pei_div_select.sql` : consolidate dividend and pei data for each client
- `05-document.sp_quartly_statement.contracts_select.sql` : get contract information
- `06-document.sp_quartly_statement.fulldata_select.sql` : consolidate all datas
- `07-document.sp_quartly_statement_xml_select.sql` : export to XML files
- `08-document.sp_quartly_statement_reporting_select.sql` : check the coherence between XML generated and the raw data from the dataHub to make sure that we don't have any discrepancies.

## Author

Thang Pham

