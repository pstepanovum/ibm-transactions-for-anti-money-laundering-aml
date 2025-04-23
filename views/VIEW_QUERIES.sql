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


-- TELLER
SELECT
    transaction_id,        
    timestamp,            
    amount_sent,         
    currency_sent,        
    amount_received,       
    currency_received,    
    source_account,       
    source_bank_name,     
    source_bank_country,   
    dest_account,          
    dest_bank_name,       
    dest_bank_country,
    type_of_transaction,
    fees,
    currency_switch      
FROM
    TELLER                 
WHERE
    -- transactions where the received amount was less than the sent amount
    -- and the currency was switched
    fees > 0 and currency_switch = 1
ORDER BY
    timestamp DESC        
LIMIT 50;

--AUDITOR
SELECT
    transaction_id,    
    timestamp,         
    amount_sent,       
    currency_sent,     
    amount_received,   
    currency_received, 
    source_bank_name,  
    source_bank_country,
    dest_bank_name,   
    dest_bank_country, 
    pattern_name,      
    legal_status
FROM
    AUDITOR            
WHERE
    -- where there was illicit activity and there was a currency_switch
    legal_status = 'ILLICIT'
    AND currency_switch = 1   
ORDER BY
    timestamp DESC     
LIMIT 50;

