SELECT

    -- Transaction details
    T.transaction_id,
    T.timestamp,
    T.form_of_payment,
    T.amount_sent,
    T.currency_sent,
    T.amount_received,
    T.currency_received,
    
    -- checks for fees (is amount_sent greater than amount_received?)
    ROUND(
    CASE
        WHEN T.amount_received < T.amount_sent THEN T.amount_sent - T.amount_received
        ELSE 0
    END, 2) AS fees,
    
    -- was there a currency exchange (ex: from USD to Yuan). Another detail relevant to Tellers, but not Customers
    CASE
        WHEN T.currency_sent <> T.currency_received THEN 1
        ELSE 0
    END AS currency_switch,
    
    -- source and dest information
    T.source_account,
    SBA.type AS source_account_type, 
    T.source_bank AS source_bank_id, 
    SB.name AS source_bank_name,  
    SB.country AS source_bank_country, 
    
    T.dest_account,
    DBA.type AS dest_account_type, 
    T.dest_bank AS dest_bank_id,   
    DB.name AS dest_bank_name,  
    DB.country AS dest_bank_country,
    
    -- Was the transaction a deposit or transfer?
    CASE
        WHEN T.source_account = T.dest_account THEN 'Deposit'
        ELSE 'Transfer'
    END AS type_of_transaction

-- table with all the transaction information
FROM
    FINANCIAL_TRANSACTION T
    
-- joins to combine source and dest with general account and bank information rather than just transaction info
LEFT JOIN
    BANK_ACCOUNT SBA ON T.source_account = SBA.account_id -- Join to get source account details
LEFT JOIN
    BANK SB ON T.source_bank = SB.bank_id             -- Join to get source bank details
LEFT JOIN
    BANK_ACCOUNT DBA ON T.dest_account = DBA.account_id   -- Join to get destination account details
LEFT JOIN
    BANK DB ON T.dest_bank = DB.bank_id