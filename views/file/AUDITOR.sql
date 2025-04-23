
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

