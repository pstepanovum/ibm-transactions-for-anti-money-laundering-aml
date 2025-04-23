-- SOURCE_CUSTOMER

SELECT
    timestamp,             
    type_of_transaction,   
    amount_sent,           
    currency_sent,        
    sent_to,               
    form_of_payment,      
    your_account_type,
    your_bank,             
    transaction_status     
FROM
    SOURCE_CUSTOMER        
WHERE
    -- filter by account, assuming same person owns both
    your_account = '8000EBD30' or your_account = '80012FE00'
ORDER BY
    timestamp DESC         
LIMIT 10;  