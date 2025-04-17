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

The database is implemented according to the following schema:

```sql
-- Create the BANK table
CREATE TABLE BANK (
    bank_id TEXT PRIMARY KEY,
    name TEXT,
    country TEXT
);

-- Create the LAUNDERING_PATTERN table
CREATE TABLE LAUNDERING_PATTERN (
    pattern_id INTEGER PRIMARY KEY,
    pattern_name TEXT
);

-- Create the BANK_ACCOUNT table
CREATE TABLE BANK_ACCOUNT (
    account_id TEXT PRIMARY KEY,
    type TEXT,
    bank_id TEXT,
    FOREIGN KEY (bank_id) REFERENCES BANK(bank_id)
);

-- Create the FINANCIAL_TRANSACTION table
CREATE TABLE FINANCIAL_TRANSACTION (
    transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME,
    form_of_payment TEXT,
    source_account TEXT,
    source_bank TEXT,
    dest_account TEXT,
    dest_bank TEXT,
    amount_sent DECIMAL(20, 2),
    currency_sent TEXT,
    amount_received DECIMAL(20, 2),
    currency_received TEXT,
    pattern_id INTEGER,
    FOREIGN KEY (source_account) REFERENCES BANK_ACCOUNT(account_id),
    FOREIGN KEY (source_bank) REFERENCES BANK(bank_id),
    FOREIGN KEY (dest_account) REFERENCES BANK_ACCOUNT(account_id),
    FOREIGN KEY (dest_bank) REFERENCES BANK(bank_id),
    FOREIGN KEY (pattern_id) REFERENCES LAUNDERING_PATTERN(pattern_id)
);

-- Create indexes for performance optimization
CREATE INDEX idx_transaction_timestamp ON FINANCIAL_TRANSACTION(timestamp);
CREATE INDEX idx_transaction_source ON FINANCIAL_TRANSACTION(source_account, source_bank);
CREATE INDEX idx_transaction_dest ON FINANCIAL_TRANSACTION(dest_account, dest_bank);
CREATE INDEX idx_transaction_amounts ON FINANCIAL_TRANSACTION(amount_sent, amount_received);
```

### Core Tables

#### BANK (bank_id, name, country)

- **Role**: Stores bank information.
- **Keys**: Primary Key (bank_id).
- **Attributes**: name (name of the bank), country (bank's location).
- **Indexes**: N/A.

#### LAUNDERING_PATTERN (pattern_id, pattern_name)

- **Role**: Stores known money laundering patterns.
- **Keys**: Primary Key (pattern_id).
- **Attributes**: pattern_name (pattern type).
- **Indexes**: N/A.

#### BANK_ACCOUNT (account_id, type, bank_id)

- **Role**: Links accounts to their banks.
- **Keys**: Primary Key (account_id), Foreign Key (bank_id → BANK).
- **Attributes**: type (type of account).
- **Indexes**: N/A.

#### FINANCIAL_TRANSACTION (transaction_id, timestamp, form_of_payment, source_account, source_bank, dest_account, dest_bank, amount_sent, currency_sent, amount_received, currency_received)

- **Role**: Stores transaction details.
- **Keys**: Primary Key (transaction_id), Foreign Keys (source_account, dest_account → BANK_ACCOUNT, source_bank, dest_bank → BANK).
- **Attributes**: timestamp (transaction time), form_of_payment (payment method), amount_sent/received (transaction values), currency_sent/received (currency types).
- **Indexes**: Indexes on timestamp, source_account and source_bank, dest_account and dest_bank, amount_sent and amount_received.

#### TRANSACTION_PATTERN (transaction_id, pattern_id)

- **Role**: Links transactions to detected laundering patterns.
- **Keys**: Primary Key (transaction_id, pattern_id), Foreign Keys (transaction_id → FINANCIAL_TRANSACTION, pattern_id → LAUNDERING_PATTERN).
- **Attributes**: None beyond keys.
- **Indexes**: Composite primary key serves as index.

### Schema Advantages

- **Normalization**: Reduces redundancy and ensures data consistency.
- **Foreign Keys**: Enforces referential integrity.
- **Indexes**: Optimizes query performance for frequent joins and filters.
- **Scalability**: Supports complex pattern detection for money laundering.

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
- Extract unique accounts → BANK_ACCOUNT records.
- Import transactions → FINANCIAL_TRANSACTION records.

```bash
python extract.py
```

### Step 3: Import Laundering Patterns

The HI-Small_Patterns.txt file is processed to:

- Extract pattern types → LAUNDERING_PATTERN records.
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
- **Details**: Focuses on FINANCIAL_TRANSACTION to detect abnormal exchange rates.
- **Why Interesting**: Critical for identifying layering in money laundering schemes.

## SQL Queries

Ten complex SQL queries should be implemented in analysis_queries.sql, each involving joins, aggregates, and returning ≤50 tuples. Examples include:

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

Each query will be documented with a .www prefix in SQL.sqlite to display results in browser tabs. Run:

```bash
sqlite3 aml_detection.db
.read analysis_queries.sql
```

## Database Optimization

Indexes are created on:

- FINANCIAL_TRANSACTION: timestamp, source_account and source_bank (composite), dest_account and dest_bank (composite), amount_sent and amount_received (composite).
- TRANSACTION_PATTERN: Composite primary key (transaction_id, pattern_id) serves as an index.

Periodically analyze query performance to adjust indexes.

## System Maintenance

### Index Optimization

The current schema includes the following indexes for optimized query performance:

```sql
CREATE INDEX idx_transaction_timestamp ON FINANCIAL_TRANSACTION(timestamp);
CREATE INDEX idx_transaction_source ON FINANCIAL_TRANSACTION(source_account, source_bank);
CREATE INDEX idx_transaction_dest ON FINANCIAL_TRANSACTION(dest_account, dest_bank);
CREATE INDEX idx_transaction_amounts ON FINANCIAL_TRANSACTION(amount_sent, amount_received);
```

These indexes improve performance for:

- Time-based queries (timestamp index)
- Source account lookups (source composite index)
- Destination account lookups (destination composite index)
- Amount-based filtering (amounts composite index)
