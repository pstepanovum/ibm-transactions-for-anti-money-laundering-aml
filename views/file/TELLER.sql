
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