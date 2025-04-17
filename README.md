# Financial Transaction and Money Laundering Detection System

**ECE467 / CSC423 – Database Systems, Spring 2025**  
**University of Miami**

## Team Members

- Pavel Stepanov
- Sean McHale
- Alexander Niejadlik

## Project Overview

This project, developed for ECE467 / CSC423 – Database Systems, implements a relational database system in SQLite to detect money laundering patterns in financial transaction data. The system adheres to the course requirements, including a 3NF schema, three user-specific views, ten complex SQL queries, and database optimization. The database is derived from the HI-Small dataset.

## Project Objectives

This project fulfills the requirements of the ECE467 / CSC423 Term Project (Stage 3) by:

- Constructing a 3NF relational database in SQLite with optimized indexes.
- Creating three distinct views for different user roles.
- Developing ten complex SQL queries involving joins and aggregates.
- Simplifying the database by removing unused attributes.
- Preparing a comprehensive report and deliverables for submission.

## Database Schema Overview

The database is designed in Third Normal Form (3NF) to ensure data integrity and eliminate redundancy. Below is the final relational schema (post-simplification) with roles, keys, and attributes:

### Core Tables

#### BANK (bank_id, bank_name, country)

- **Role**: Stores bank information.
- **Keys**: Primary Key (bank_id), Unique (bank_name, country).
- **Attributes**: bank_name (name of the bank), country (bank's location).
- **Size**: ~100 tuples.
- **Indexes**: Index on bank_name for query performance.

#### CURRENCY (currency_id, currency_code)

- **Role**: Stores currency types (e.g., USD, EUR).
- **Keys**: Primary Key (currency_id), Unique (currency_code).
- **Attributes**: currency_code (ISO currency code).
- **Size**: ~20 tuples.
- **Indexes**: None.

#### PAYMENT_METHOD (method_id, method_name)

- **Role**: Stores transaction payment methods (e.g., wire, cash).
- **Keys**: Primary Key (method_id), Unique (method_name).
- **Attributes**: method_name (payment method description).
- **Size**: ~10 tuples.
- **Indexes**: None.

#### ACCOUNT (account_id, bank_id, account_number)

- **Role**: Links accounts to their banks.
- **Keys**: Primary Key (account_id), Foreign Key (bank_id → BANK).
- **Attributes**: account_number (unique account identifier).
- **Size**: ~10,000 tuples.
- **Indexes**: Index on account_number for transaction lookups.

#### FINANCIAL_TRANSACTION (transaction_id, source_account_id, dest_account_id, currency_id, method_id, amount, timestamp, is_laundering)

- **Role**: Stores transaction details.
- **Keys**: Primary Key (transaction_id), Foreign Keys (source_account_id, dest_account_id → ACCOUNT, currency_id → CURRENCY, method_id → PAYMENT_METHOD).
- **Attributes**: amount (transaction value), timestamp (transaction time), is_laundering (flag for suspicious activity).
- **Size**: ~500,000 tuples.
- **Indexes**: Indexes on timestamp, is_laundering, source_account_id, dest_account_id.

#### LAUNDERING_PATTERN (pattern_id, pattern_name, description)

- **Role**: Stores known money laundering patterns.
- **Keys**: Primary Key (pattern_id), Unique (pattern_name).
- **Attributes**: pattern_name (pattern type), description (pattern details).
- **Size**: ~50 tuples.
- **Indexes**: None.

#### TRANSACTION_PATTERN (transaction_id, pattern_id)

- **Role**: Links transactions to detected laundering patterns.
- **Keys**: Primary Key (transaction_id, pattern_id), Foreign Keys (transaction_id → FINANCIAL_TRANSACTION, pattern_id → LAUNDERING_PATTERN).
- **Attributes**: None beyond keys.
- **Size**: ~1,000 tuples.
- **Indexes**: Composite index on (transaction_id, pattern_id).

### Schema Advantages

- **Normalization**: Eliminates redundancy and ensures data consistency.
- **Foreign Keys**: Enforces referential integrity.
- **Indexes**: Optimizes query performance for frequent joins and filters.
- **Scalability**: Supports complex pattern detection for money laundering.

## Entity-Relationship (ER) Diagram

The final ER diagram (post-simplification) is included in REPORT.pdf. Entities (e.g., BANK, ACCOUNT) are in UPPER CASE, relationships in UPPER CASE, and attributes in lower case. The diagram is provided in vector PDF format for clarity.


## Quick Start

```bash

chmod +x setup.sh
./setup.sh

```

## Data Import Process

### Step 1: Create the Database

```bash
sqlite3 aml_detection.db < schema.sql
```

### Step 2: Import Transaction Data

The HI-Small_Trans.csv dataset is processed to:

- Extract unique banks → BANK records.
- Extract unique currencies → CURRENCY records.
- Extract unique payment methods → PAYMENT_METHOD records.
- Extract unique accounts → ACCOUNT records.
- Import transactions → FINANCIAL_TRANSACTION records.

```bash
python extract.py
```

### Step 3: Import Laundering Patterns

The HI-Small_Patterns.txt file is processed to:

- Extract pattern types and descriptions → LAUNDERING_PATTERN records.
- Link transactions to patterns → TRANSACTION_PATTERN records.

## User Views

Three views are designed for distinct user roles, each providing tailored insights:

### RiskAnalystView

- **Purpose**: Identifies suspicious transactions and laundering patterns.
- **Details**: Joins FINANCIAL_TRANSACTION, TRANSACTION_PATTERN, and LAUNDERING_PATTERN to highlight high-risk transactions.
- **Why Interesting**: Enables analysts to prioritize investigations based on pattern severity.

### ComplianceOfficerView

- **Purpose**: Monitors accounts and assesses overall risk.
- **Details**: Aggregates transaction data by account, including total volume and laundering flags.
- **Why Interesting**: Helps officers ensure regulatory compliance and detect account-level risks.

### FIUCurrencyExchangeView

- **Purpose**: Analyzes currency exchanges for potential value manipulation.
- **Details**: Focuses on FINANCIAL_TRANSACTION and CURRENCY to detect abnormal exchange rates.
- **Why Interesting**: Critical for identifying layering in money laundering schemes.

## SQL Queries

Ten complex SQL queries are implemented in analysis_queries.sql, each involving joins, aggregates, and returning ≤50 tuples. Examples include:

1. **Fan-out Pattern Detection**: Identifies accounts sending to multiple recipients in a short timeframe.
2. **Cyclic Transaction Detection**: Detects circular money flows (A→B→C→A).
3. **Structuring Detection**: Finds multiple small transactions under reporting thresholds.
4. **Dormancy Pattern Analysis**: Flags inactive accounts with sudden activity.
5. **Unusual Exchange Rate Detection**: Identifies transactions with abnormal currency rates.
6. **Rapid Movement of Funds**: Detects quick in-and-out transactions.
7. **Round Number Transaction Analysis**: Flags even-amount transactions.
8. **Account Risk Scoring**: Computes composite risk scores for accounts.
9. **Smurfing Pattern Detection**: Identifies multiple sources sending to one destination.
10. **Unusual Transaction Timing Analysis**: Detects transactions at odd hours.

Each query is documented with a .www prefix in SQL.sqlite to display results in browser tabs. Run:

```bash
sqlite3 aml_detection.db
.read analysis_queries.sql
```

## Database Simplification

Unused attributes (e.g., redundant account details) were removed post-query finalization to optimize storage and performance. The final schema reflects only attributes used in views and queries.

## System Maintenance

### Index Optimization

Indexes are created on:

- FINANCIAL_TRANSACTION: timestamp, is_laundering, source_account_id, dest_account_id.
- ACCOUNT: account_number.
- TRANSACTION_PATTERN: Composite (transaction_id, pattern_id).

Periodically analyze query performance to adjust indexes.

### Backup Strategy

Regular backups of aml_detection.db are recommended to prevent data loss.

## Deliverables

Submitted on Blackboard by 4/18/2025:

- **/REPORT.md**: Includes database description, final ER diagram, relational schema, view descriptions, query documentation, and dataset URL.
- **DATABASE.db**: SQLite database with tables, indexes, and views.
- **SQL.sqlite**: Documented SQL code with .www prefixes for browser display.

## Demo Preparation

The team is prepared for a 10-minute interactive demo on 4/17/2025 (3:30pm–6:10pm) in MEB 419. The database and queries will be showcased live. A slot is reserved at https://gotsman.youcanbook.me.
