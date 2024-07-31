# Calculate Dividend and Export XML with SQL

## Overview

This project aims to calculate dividends received by clients for the last quarter. It exports all related data and stores the output in XML files to generate PDF files and send them to clients.

## Features

- Calculate dividends for the last quarter.
- Export data to XML files.
- Generate PDFs from XML files.
- Send generated PDFs to clients.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Author](#author)
- [License](#license)

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

### sp_generate_xml

This script generates XML files by batch. It splits the `table_contract` table into batches of 10,000 rows and creates XML files for each batch.

### Other SQL Scripts

- `01-document.sp_quartly_statement.representative_create.sql`
- `02-document.sp_quartly_statement.dividend_select.sql`
- `03-document.sp_quartly_statement.pei_select.sql`
- `04-document.sp_quartly_statement.pei_div_select.sql`
- `05-document.sp_quartly_statement.contracts_select.sql`
- `06-document.sp_quartly_statement.fulldata_select.sql`
- `07-document.sp_quartly_statement_xml_select.sql`
- `08-document.sp_quartly_statement_reporting_select.sql`

## Author

Thang Pham

