-- Query 1: Identify fan-out patterns (one account sending to many others in short timeframe)
-- This is a common money laundering technique to obfuscate the source of funds
SELECT 
    t.source_account,
    t.source_bank,
    strftime('%Y-%m-%d', t.timestamp) as transaction_date,
    COUNT(DISTINCT t.dest_account) as recipient_count,
    SUM(t.amount_sent) as total_sent,
    GROUP_CONCAT(DISTINCT t.dest_account) as recipient_accounts
FROM 
    FINANCIAL_TRANSACTION t
GROUP BY 
    t.source_account, t.source_bank, transaction_date
HAVING 
    recipient_count > 5  -- Threshold for fan-out pattern
ORDER BY 
    recipient_count DESC, total_sent DESC
LIMIT 50;


-- Query 2: Identify cyclic transactions (A→B→C→A) within 48 hours
-- Circular money flow is often used to obscure the trail
WITH TransactionChain AS (
    SELECT 
        t1.source_account as account_A,
        t1.source_bank as bank_A,
        t1.dest_account as account_B,
        t1.dest_bank as bank_B,
        t2.dest_account as account_C,
        t2.dest_bank as bank_C,
        t3.dest_account as final_account,
        t3.dest_bank as final_bank,
        t1.timestamp as first_timestamp,
        t3.timestamp as last_timestamp,
        julianday(t3.timestamp) - julianday(t1.timestamp) as cycle_duration_days,
        t1.amount_sent as initial_amount,
        t3.amount_received as final_amount
    FROM 
        FINANCIAL_TRANSACTION t1
    JOIN 
        FINANCIAL_TRANSACTION t2 ON t1.dest_account = t2.source_account
                        AND t1.dest_bank = t2.source_bank
                        AND t2.timestamp > t1.timestamp
                        AND (julianday(t2.timestamp) - julianday(t1.timestamp)) <= 2
    JOIN 
        FINANCIAL_TRANSACTION t3 ON t2.dest_account = t3.source_account
                        AND t2.dest_bank = t3.source_bank
                        AND t3.timestamp > t2.timestamp
                        AND (julianday(t3.timestamp) - julianday(t1.timestamp)) <= 2
)
SELECT * 
FROM TransactionChain
WHERE 
    account_A = final_account AND bank_A = final_bank
    AND cycle_duration_days <= 2
ORDER BY cycle_duration_days
LIMIT 50;


-- Query 3: Detect structuring patterns (multiple small transactions to avoid reporting thresholds)
WITH DailyAccountActivity AS (
    SELECT 
        source_account,
        source_bank,
        dest_account,
        dest_bank,
        strftime('%Y-%m-%d', timestamp) as transaction_date,
        COUNT(*) as transaction_count,
        SUM(amount_sent) as total_amount
    FROM 
        FINANCIAL_TRANSACTION
    GROUP BY 
        source_account, source_bank, dest_account, dest_bank, transaction_date
    HAVING 
        transaction_count >= 3 
        AND total_amount > 9000  -- Just under common 10K reporting threshold
        AND MAX(amount_sent) < 3500  -- All transactions small
)
SELECT 
    source_account, 
    source_bank,
    dest_account,
    dest_bank,
    transaction_date,
    transaction_count,
    total_amount,
    (total_amount / transaction_count) as average_transaction_size
FROM 
    DailyAccountActivity
ORDER BY 
    transaction_count DESC, total_amount DESC
LIMIT 50;


-- Query 4: Identify accounts with unusual dormancy patterns followed by high activity
-- (inactive accounts suddenly becoming active is suspicious)
WITH AccountActivitySummary AS (
    SELECT 
        account_id,
        bank_id,
        transaction_date,
        LAG(transaction_date, 1, NULL) OVER (
            PARTITION BY account_id, bank_id 
            ORDER BY transaction_date
        ) as previous_active_date,
        julianday(transaction_date) - julianday(LAG(transaction_date, 1, NULL) OVER (
            PARTITION BY account_id, bank_id 
            ORDER BY transaction_date
        )) as days_dormant,
        transaction_count,
        transaction_amount
    FROM (
        SELECT 
            source_account as account_id,
            source_bank as bank_id,
            strftime('%Y-%m-%d', timestamp) as transaction_date,
            COUNT(*) as transaction_count,
            SUM(amount_sent) as transaction_amount
        FROM 
            FINANCIAL_TRANSACTION
        GROUP BY 
            source_account, source_bank, transaction_date
        
        UNION ALL
        
        SELECT 
            dest_account as account_id,
            dest_bank as bank_id,
            strftime('%Y-%m-%d', timestamp) as transaction_date,
            COUNT(*) as transaction_count,
            SUM(amount_received) as transaction_amount
        FROM 
            FINANCIAL_TRANSACTION
        GROUP BY 
            dest_account, dest_bank, transaction_date
    )
    GROUP BY account_id, bank_id, transaction_date
)
SELECT 
    account_id,
    bank_id,
    transaction_date as activity_date,
    previous_active_date,
    days_dormant,
    transaction_count,
    transaction_amount
FROM 
    AccountActivitySummary
WHERE 
    days_dormant > 30  -- Dormant for over a month
    AND transaction_amount > 5000  -- Followed by significant activity
    AND days_dormant IS NOT NULL
ORDER BY 
    days_dormant DESC, transaction_amount DESC
LIMIT 50;


-- Query 5: Find transactions with unusual exchange rates
-- (unusual rates can indicate value manipulation or layering)
WITH CurrencyPairStats AS (
    SELECT 
        currency_sent,
        currency_received,
        AVG(amount_received / amount_sent) as avg_exchange_rate,
        STDDEV(amount_received / amount_sent) as stddev_exchange_rate
    FROM 
        FINANCIAL_TRANSACTION
    WHERE 
        currency_sent != currency_received
        AND amount_sent > 0
    GROUP BY 
        currency_sent, currency_received
    HAVING 
        COUNT(*) >= 5  -- Only include common currency pairs
)
SELECT 
    t.transaction_id,
    t.timestamp,
    t.source_account,
    t.source_bank,
    t.dest_account,
    t.dest_bank,
    t.currency_sent,
    t.currency_received,
    t.amount_sent,
    t.amount_received,
    (t.amount_received / t.amount_sent) as transaction_rate,
    c.avg_exchange_rate,
    c.stddev_exchange_rate,
    ((t.amount_received / t.amount_sent) - c.avg_exchange_rate) / c.stddev_exchange_rate as z_score
FROM 
    FINANCIAL_TRANSACTION t
JOIN 
    CurrencyPairStats c ON t.currency_sent = c.currency_sent 
                        AND t.currency_received = c.currency_received
WHERE 
    ABS(((t.amount_received / t.amount_sent) - c.avg_exchange_rate) / c.stddev_exchange_rate) > 2
    AND t.currency_sent != t.currency_received
    AND t.amount_sent > 0
ORDER BY 
    ABS(((t.amount_received / t.amount_sent) - c.avg_exchange_rate) / c.stddev_exchange_rate) DESC
LIMIT 50;


-- Query 6: Detect rapid movement of funds (money entering and leaving accounts quickly)
-- (rapid movement often indicates laundering)
WITH AccountDailyFlows AS (
    SELECT 
        a.account_id,
        a.bank_id,
        strftime('%Y-%m-%d', t_in.timestamp) as flow_date,
        SUM(t_in.amount_received) as inflow,
        SUM(t_out.amount_sent) as outflow,
        (SUM(t_out.amount_sent) / NULLIF(SUM(t_in.amount_received), 0)) * 100 as outflow_percentage,
        COUNT(DISTINCT t_in.transaction_id) as inflow_count,
        COUNT(DISTINCT t_out.transaction_id) as outflow_count,
        MIN(julianday(t_out.timestamp) - julianday(t_in.timestamp)) as min_turnaround_days
    FROM 
        BANK_ACCOUNT a
    JOIN 
        FINANCIAL_TRANSACTION t_in ON a.account_id = t_in.dest_account AND a.bank_id = t_in.dest_bank
    JOIN 
        FINANCIAL_TRANSACTION t_out ON a.account_id = t_out.source_account AND a.bank_id = t_out.source_bank
                         AND strftime('%Y-%m-%d', t_out.timestamp) = strftime('%Y-%m-%d', t_in.timestamp)
    GROUP BY 
        a.account_id, a.bank_id, flow_date
    HAVING 
        inflow > 1000  -- Only consider significant flows
        AND outflow_percentage > 80  -- Most money received is sent out same day
)
SELECT *
FROM AccountDailyFlows
ORDER BY 
    outflow_percentage DESC, inflow DESC
LIMIT 50;


-- Query 7: Identify round number transactions (often indicate structured/artificial transactions)
SELECT 
    t.transaction_id,
    t.timestamp,
    t.source_account,
    t.source_bank,
    t.dest_account,
    t.dest_bank,
    t.amount_sent,
    t.currency_sent,
    CASE 
        WHEN t.amount_sent % 1000 = 0 THEN 'EXACT_THOUSAND'
        WHEN t.amount_sent % 500 = 0 THEN 'EXACT_500'
        WHEN t.amount_sent % 100 = 0 THEN 'EXACT_100' 
        ELSE 'NOT_ROUND'
    END as round_amount_type
FROM 
    FINANCIAL_TRANSACTION t
WHERE 
    (t.amount_sent % 1000 = 0 OR t.amount_sent % 500 = 0 OR t.amount_sent % 100 = 0)
    AND t.amount_sent > 1000  -- Focus on larger transactions
ORDER BY 
    t.amount_sent DESC
LIMIT 50;


-- Query 8: Calculate risk scores for accounts based on multiple risk factors
-- This implements a simplified AML risk scoring algorithm
WITH AccountRiskFactors AS (
    SELECT 
        a.account_id,
        a.bank_id,
        -- Transaction volume factors
        COUNT(DISTINCT t.transaction_id) as transaction_count,
        
        -- Amount factors
        SUM(t.amount_sent) as total_amount,
        MAX(t.amount_sent) as max_transaction,
        
        -- Network factors
        COUNT(DISTINCT t.dest_account) as unique_recipients,
        
        -- Currency factors
        COUNT(DISTINCT t.currency_sent) as currency_count,
        SUM(CASE WHEN t.currency_sent != t.currency_received THEN 1 ELSE 0 END) as currency_exchange_count,
        
        -- Pattern factors
        COUNT(DISTINCT tp.pattern_id) as matched_patterns
    FROM 
        BANK_ACCOUNT a
    LEFT JOIN 
        FINANCIAL_TRANSACTION t ON a.account_id = t.source_account AND a.bank_id = t.source_bank
    LEFT JOIN 
        TRANSACTION_PATTERN tp ON t.transaction_id = tp.transaction_id
    GROUP BY 
        a.account_id, a.bank_id
)
SELECT 
    account_id,
    bank_id,
    transaction_count,
    total_amount,
    max_transaction,
    unique_recipients,
    currency_count,
    currency_exchange_count,
    matched_patterns,
    -- Risk score calculation (weights would be tuned in a real system)
    (CASE WHEN transaction_count > 100 THEN 20 ELSE transaction_count / 5 END) +
    (CASE WHEN total_amount > 1000000 THEN 30 ELSE total_amount / 33333 END) +
    (CASE WHEN max_transaction > 50000 THEN 25 ELSE max_transaction / 2000 END) +
    (CASE WHEN unique_recipients > 50 THEN 15 ELSE unique_recipients / 3.33 END) +
    (currency_count * 5) +
    (currency_exchange_count * 10) +
    (matched_patterns * 25) as risk_score
FROM 
    AccountRiskFactors
ORDER BY 
    risk_score DESC
LIMIT 50;


-- Query 9: Find smurfing patterns (multiple accounts sending to same destination)
-- Common technique to fragment money trails
SELECT 
    t.dest_account,
    t.dest_bank,
    strftime('%Y-%m-%d', t.timestamp) as transaction_date,
    COUNT(DISTINCT t.source_account) as unique_senders,
    GROUP_CONCAT(DISTINCT t.source_bank || ':' || t.source_account) as sender_accounts,
    SUM(t.amount_received) as total_received,
    AVG(t.amount_received) as avg_amount,
    COUNT(t.transaction_id) as transaction_count
FROM 
    FINANCIAL_TRANSACTION t
GROUP BY 
    t.dest_account, t.dest_bank, transaction_date
HAVING 
    unique_senders >= 5  -- At least 5 different source accounts
    AND COUNT(t.transaction_id) >= unique_senders  -- At least one transaction per sender
    AND MAX(t.amount_received) < 10000  -- All transactions below reporting threshold
ORDER BY 
    unique_senders DESC, total_received DESC
LIMIT 50;


-- Query 10: Identify unusual transaction timing patterns
-- Transactions at odd hours can indicate automated or suspicious activity
WITH HourlyStats AS (
    SELECT
        strftime('%H', timestamp) as hour_of_day,
        COUNT(*) as total_transactions,
        AVG(amount_sent) as avg_amount,
        STDDEV(amount_sent) as stddev_amount
    FROM
        FINANCIAL_TRANSACTION
    GROUP BY
        hour_of_day
)
SELECT
    t.transaction_id,
    t.timestamp,
    strftime('%H', t.timestamp) as hour_of_day,
    t.source_account,
    t.source_bank,
    t.dest_account,
    t.dest_bank,
    t.amount_sent,
    t.currency_sent,
    h.avg_amount as typical_hour_amount,
    h.total_transactions as typical_hour_volume,
    (t.amount_sent - h.avg_amount) / h.stddev_amount as amount_z_score
FROM
    FINANCIAL_TRANSACTION t
JOIN
    HourlyStats h ON strftime('%H', t.timestamp) = h.hour_of_day
WHERE
    -- Unusual amounts for the time of day
    ABS((t.amount_sent - h.avg_amount) / h.stddev_amount) > 3
    -- Focus on overnight hours (midnight to 5am)
    AND strftime('%H', t.timestamp) BETWEEN '00' AND '05'
    AND t.amount_sent > 10000  -- Significant transactions
ORDER BY
    ABS((t.amount_sent - h.avg_amount) / h.stddev_amount) DESC,
    t.amount_sent DESC
LIMIT 50;