-- Create the BANK table
CREATE TABLE BANK (
    bank_id TEXT PRIMARY KEY,
    country TEXT
);

-- Create the CURRENCY table
CREATE TABLE CURRENCY (
    currency_code TEXT PRIMARY KEY
);

-- Create the PAYMENT_METHOD table
CREATE TABLE PAYMENT_METHOD (
    method_id INTEGER PRIMARY KEY AUTOINCREMENT,
    method_name TEXT UNIQUE
);

-- Create the LAUNDERING_PATTERN table
CREATE TABLE LAUNDERING_PATTERN (
    pattern_id INTEGER PRIMARY KEY AUTOINCREMENT,
    pattern_name TEXT,
    pattern_description TEXT
);

-- Create the ACCOUNT table (links accounts to banks)
CREATE TABLE ACCOUNT (
    account_id TEXT,
    bank_id TEXT,
    PRIMARY KEY (account_id, bank_id),
    FOREIGN KEY (bank_id) REFERENCES BANK(bank_id)
);

-- Create the FINANCIAL_TRANSACTION table (avoiding reserved keyword "TRANSACTION")
CREATE TABLE FINANCIAL_TRANSACTION (
    transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME,
    source_account_id TEXT,
    source_bank_id TEXT,
    dest_account_id TEXT,
    dest_bank_id TEXT,
    amount_received DECIMAL(20, 2),
    receiving_currency_code TEXT,
    amount_paid DECIMAL(20, 2),
    payment_currency_code TEXT,
    payment_method_id INTEGER,
    is_laundering INTEGER,
    FOREIGN KEY (source_account_id, source_bank_id) REFERENCES ACCOUNT(account_id, bank_id),
    FOREIGN KEY (dest_account_id, dest_bank_id) REFERENCES ACCOUNT(account_id, bank_id),
    FOREIGN KEY (receiving_currency_code) REFERENCES CURRENCY(currency_code),
    FOREIGN KEY (payment_currency_code) REFERENCES CURRENCY(currency_code),
    FOREIGN KEY (payment_method_id) REFERENCES PAYMENT_METHOD(method_id)
);

-- Create the TRANSACTION_PATTERN table (links transactions to specific laundering patterns)
CREATE TABLE TRANSACTION_PATTERN (
    transaction_id INTEGER,
    pattern_id INTEGER,
    PRIMARY KEY (transaction_id, pattern_id),
    FOREIGN KEY (transaction_id) REFERENCES FINANCIAL_TRANSACTION(transaction_id),
    FOREIGN KEY (pattern_id) REFERENCES LAUNDERING_PATTERN(pattern_id)
);

-- Create indexes for performance optimization
CREATE INDEX idx_transaction_timestamp ON FINANCIAL_TRANSACTION(timestamp);
CREATE INDEX idx_transaction_laundering ON FINANCIAL_TRANSACTION(is_laundering);
CREATE INDEX idx_transaction_source ON FINANCIAL_TRANSACTION(source_account_id, source_bank_id);
CREATE INDEX idx_transaction_dest ON FINANCIAL_TRANSACTION(dest_account_id, dest_bank_id);
CREATE INDEX idx_transaction_amounts ON FINANCIAL_TRANSACTION(amount_paid, amount_received);