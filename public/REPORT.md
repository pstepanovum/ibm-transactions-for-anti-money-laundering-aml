# Financial Transaction and Money Laundering Detection System

## Database Schema

The schema includes the following tables:

### 1. BANK Table

- **bank_id** (primary key)
- **name**
- **country**

### 2. LAUNDERING_PATTERN Table

- **pattern_id** (primary key)
- **pattern_name**

### 3. BANK_ACCOUNT Table

- **account_id** (primary key)
- **type**
- **bank_id** (foreign key referencing BANK table)

### 4. TRANSACTION Table

- **transaction_id** (primary key)
- **timestamp**
- **form_of_payment**
- **source_account** (foreign key referencing BANK_ACCOUNT.account_id)
- **source_bank** (foreign key referencing BANK_ACCOUNT.bank_id)
- **dest_account** (foreign key referencing BANK_ACCOUNT.account_id)
- **dest_bank** (foreign key referencing BANK_ACCOUNT.bank_id)
- **amount_sent**
- **currency_sent**
- **amount_received**
- **currency_received**

## Entity-Relationship (ER) Diagram

The ER diagram represents the system with the following entities and relationships:

### Entities:

#### 1. BANK entity with attributes:

- bank_id (primary key)
- name
- country

#### 2. BANK ACCOUNT entity with attributes:

- account_id (primary key)
- type

#### 3. TRANSACTION entity with attributes:

- transaction_id (primary key)
- timestamp
- form_of_payment
- amount_sent
- currency_sent
- amount_received
- currency_received

#### 4. LAUNDERING PATTERN entity with attributes:

- pattern_id (primary key)
- pattern_name

### Relationships:

- **MAINTAINED BY**: Connects BANK ACCOUNT to BANK (accounts are maintained by a specific bank)
- **IN**: Connects TRANSACTION to BANK ACCOUNT (many-to-one, for destination accounts)
- **OUT**: Connects TRANSACTION to BANK ACCOUNT (many-to-one, for source accounts)
- **HAS PATTERN**: Connects TRANSACTION to LAUNDERING PATTERN (many-to-one)
