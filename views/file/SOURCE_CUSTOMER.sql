SELECT
    -- Pull columns that are relevant to a source account (excludes laundering, bank, and dest information, as well as transaction_id)
    T.timestamp,
    T.source_account AS your_account, -- aliasing for personalization     
    T.amount_sent,
    T.currency_sent,
    T.form_of_payment,
    T.dest_account AS sent_to, -- simpler and more natural way of saying where the money went
    BA.type AS your_account_type,
    BA.bank_id AS your_bank, 
    
    CASE
        WHEN T.source_account = T.dest_account THEN 'Deposit' -- Was the transaction a deposit or transfer?
        ELSE 'Transfer'
    END AS type_of_transaction,
    
    'Sent Successfully' AS transaction_status -- notification about whether the transaction went through or not (original)

-- table with all transaction information
FROM
    FINANCIAL_TRANSACTION T

-- LEFT JOIN (matches source accounts with all accounts to get account type and bank_id)
LEFT JOIN
    BANK_ACCOUNT BA ON T.source_account = BA.account_id