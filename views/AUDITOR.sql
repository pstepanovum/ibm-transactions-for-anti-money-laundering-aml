-- AUDITOR VIEW
-- This view is designed for auditors to review financial transactions and identify potential money laundering activities.
SELECT
    -- Transaction details
    T.transaction_id,
    T.timestamp,
    T.form_of_payment,
    T.amount_sent,
    T.currency_sent,
    T.amount_received,
    T.currency_received,

    -- checks if currency was exchanged. Important for an auditor 
    CASE
        WHEN T.currency_sent <> T.currency_received THEN 1
        ELSE 0
    END AS currency_switch,

    -- Source info
    T.source_account,
    SBA.type AS source_account_type,
    T.source_bank AS source_bank_id,
    SB.name AS source_bank_name,
    SB.country AS source_bank_country,

    -- Destination info
    T.dest_account,
    DBA.type AS dest_account_type,
    T.dest_bank AS dest_bank_id,
    DB.name AS dest_bank_name,
    DB.country AS dest_bank_country,

    -- Laundering pattern information (only an auditor can know about the laundering/illicit activity)
    T.pattern_id, 
    L.pattern_name,
 
    -- column that easily says whether illegal activity took place, makes the database more readable for a legal officer
    CASE
        WHEN T.pattern_id = 10 THEN 'LEGAL' 
        ELSE 'ILLICIT' 
    END AS legal_status
    
-- table with transaction info
FROM
    FINANCIAL_TRANSACTION T

-- joins to combine source and dest account transaction info with account and bank info
LEFT JOIN
    BANK_ACCOUNT SBA ON T.source_account = SBA.account_id
LEFT JOIN
    BANK SB ON T.source_bank = SB.bank_id
LEFT JOIN
    BANK_ACCOUNT DBA ON T.dest_account = DBA.account_id
LEFT JOIN
    BANK DB ON T.dest_bank = DB.bank_id

-- combine laundering pattern information with the rest of the tables
LEFT JOIN
    LAUNDERING_PATTERN L ON T.pattern_id = L.pattern_id