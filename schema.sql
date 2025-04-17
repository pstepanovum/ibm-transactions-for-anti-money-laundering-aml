-- Create the BANK table
CREATE TABLE BANK (
    bank_id TEXT PRIMARY KEY,
    name TEXT,
    country TEXT
);

-- Create the LAUNDERING_PATTERN table
CREATE TABLE LAUNDERING_PATTERN (
    pattern_id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    FOREIGN KEY (source_account) REFERENCES BANK_ACCOUNT(account_id),
    FOREIGN KEY (source_bank) REFERENCES BANK(bank_id),
    FOREIGN KEY (dest_account) REFERENCES BANK_ACCOUNT(account_id),
    FOREIGN KEY (dest_bank) REFERENCES BANK(bank_id)
);

-- Create the TRANSACTION_PATTERN junction table
CREATE TABLE TRANSACTION_PATTERN (
    transaction_id INTEGER,
    pattern_id INTEGER,
    PRIMARY KEY (transaction_id, pattern_id),
    FOREIGN KEY (transaction_id) REFERENCES FINANCIAL_TRANSACTION(transaction_id),
    FOREIGN KEY (pattern_id) REFERENCES LAUNDERING_PATTERN(pattern_id)
);

-- Create indexes for performance optimization
CREATE INDEX idx_transaction_timestamp ON FINANCIAL_TRANSACTION(timestamp);
CREATE INDEX idx_transaction_source ON FINANCIAL_TRANSACTION(source_account, source_bank);
CREATE INDEX idx_transaction_dest ON FINANCIAL_TRANSACTION(dest_account, dest_bank);
CREATE INDEX idx_transaction_amounts ON FINANCIAL_TRANSACTION(amount_sent, amount_received);