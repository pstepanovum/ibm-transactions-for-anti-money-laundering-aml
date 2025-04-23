-- SQL.sqlite file
-- Contains documented queries that display results in browser tabs when run with SQLite .read command

.www
-- 1. List the deposit history of the customers with account_ids 8000EBD30, 8016BBF90, and 800128AC0
-- Purpose: Track deposit transactions for specific customer accounts for auditing or customer service
-- Techniques: Using a custom view (SOURCE_CUSTOMER), filtering with OR conditions, ordering by timestamp
-- Business Logic: Assumes these three accounts belong to the same entity, shows only deposit transactions
SELECT
    timestamp, 
    your_account,
    your_account_type, 
    your_bank,
    type_of_transaction,
    amount_sent,
    currency_sent,
    form_of_payment,
    sent_to,
    transaction_status
FROM
    SOURCE_CUSTOMER
WHERE
    (your_account = '8000EBD30' or your_account = '8016BBF90' or your_account = '800128AC0') 
    and type_of_transaction = 'Deposit'
ORDER BY
    timestamp DESC;

.www
-- 2. Which bank has the most illicit_transactions?
-- Purpose: Identify banks that may require enhanced compliance monitoring or investigation
-- Techniques: Nested queries, UNION ALL, CASE statements, JOINs, aggregation with percentage calculation
-- Business Logic: Considers both source and destination transactions, excludes pattern_id = 10 (normal transactions)
SELECT
    B.name AS bank_name,
    AggregatedRates.illicit_transactions,
    AggregatedRates.total_transactions
FROM (
    SELECT
        bank_id,
        COUNT(*) AS total_transactions,
        SUM(is_illicit) AS illicit_transactions
    FROM (
        SELECT
            source_bank AS bank_id,
            CASE
                WHEN pattern_id != 10 THEN 1
                ELSE 0
            END AS is_illicit
        FROM FINANCIAL_TRANSACTION

        UNION ALL

        SELECT
            dest_bank AS bank_id,
            CASE
                WHEN pattern_id != 10 THEN 1
                ELSE 0
            END AS is_illicit
        FROM FINANCIAL_TRANSACTION
    ) AS BankParticipationData
    GROUP BY bank_id
    HAVING COUNT(*) > 0
) AS AggregatedRates
JOIN BANK B ON AggregatedRates.bank_id = B.bank_id
ORDER BY AggregatedRates.illicit_transactions DESC
LIMIT 5;

.www
-- 3. What type of accounts are more often implicated in laundering: individuals or companies?
-- Purpose: Understand which account types are more vulnerable to money laundering activities
-- Techniques: CTEs (Common Table Expressions), UNION for combining results, LEFT JOIN, percentage calculation
-- Business Logic: Compares individual vs corporate accounts' involvement in suspicious transactions
WITH IllicitTransactionAccounts AS (
    SELECT DISTINCT source_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE (pattern_id = 11 or pattern_id = 12 or pattern_id = 13 or pattern_id = 14 or pattern_id = 15 or pattern_id = 16 or pattern_id = 17 or pattern_id = 18) AND source_account IS NOT NULL

    UNION

    SELECT DISTINCT dest_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE (pattern_id = 11 or pattern_id = 12 or pattern_id = 13 or pattern_id = 14 or pattern_id = 15 or pattern_id = 16 or pattern_id = 17 or pattern_id = 18) AND dest_account IS NOT NULL

), AccountTypeStats AS (
    SELECT
        BA.type,
        COUNT(DISTINCT BA.account_id) AS total_accounts,
        COUNT(DISTINCT I.account_id) AS implicated_accounts
    FROM
        BANK_ACCOUNT BA
    LEFT JOIN
        IllicitTransactionAccounts I ON BA.account_id = I.account_id
    WHERE
        BA.type IN ('Individual', 'Corporate')
    GROUP BY
        BA.type
)
SELECT
    type,
    total_accounts,
    implicated_accounts,
    CASE
        WHEN total_accounts > 0 THEN
            CAST(implicated_accounts AS REAL) * 100.0 / total_accounts
        ELSE
            0.0
    END AS implication_rate_percent
FROM
    AccountTypeStats
ORDER BY
    implication_rate_percent DESC;

.www
-- 4. List the five countries with the most launderers in alphabetical order
-- Purpose: Identify geographic hotspots for money laundering activity
-- Techniques: Multiple CTEs, DISTINCT to avoid duplicates, UNION, multiple JOINs, sorting and limiting
-- Business Logic: Counts unique accounts involved in laundering per country, then finds top 5
WITH LaunderingAccounts AS (
    SELECT source_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE (pattern_id = 11 or pattern_id = 12 or pattern_id = 13 or pattern_id = 14 or pattern_id = 15 or pattern_id = 16 or pattern_id = 17 or pattern_id = 18) AND source_account IS NOT NULL

    UNION -- combine all source and dest accounts involved in laundering (pattern_id != 10)

    SELECT dest_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE (pattern_id = 11 or pattern_id = 12 or pattern_id = 13 or pattern_id = 14 or pattern_id = 15 or pattern_id = 16 or pattern_id = 17 or pattern_id = 18) AND dest_account IS NOT NULL

), CountryLaundererCounts AS ( -- counting unique laundering accounts by country
    SELECT
        B.country,
        COUNT(DISTINCT BA.account_id) AS unique_launderer_accounts
    FROM
        LaunderingAccounts L
    JOIN
        BANK_ACCOUNT BA ON L.account_id = BA.account_id
    JOIN
        BANK B ON BA.bank_id = B.bank_id
    WHERE
        B.country IS NOT NULL
    GROUP BY
        B.country

)
-- ordering
SELECT
    country,
    unique_launderer_accounts
FROM
    CountryLaundererCounts
ORDER BY
    unique_launderer_accounts DESC    
LIMIT 5;

.www
-- 5. On what day and at what time did the most laundering occur?
-- Purpose: Identify temporal patterns in money laundering activities
-- Techniques: Simple aggregation with GROUP BY, filtering, and sorting
-- Business Logic: Finds the single timestamp with the highest concentration of suspicious transactions
SELECT
    timestamp,
    COUNT(*) AS launderingInstanceCounter
FROM
    FINANCIAL_TRANSACTION
WHERE
    pattern_id IS NOT NULL
    AND timestamp IS NOT NULL
GROUP BY
    timestamp
ORDER BY
    launderingInstanceCounter DESC
LIMIT 20;

.www
-- 6. List the names of the laundering patterns in order of how often they occur from most to least
-- Purpose: Understand which money laundering methods are most frequently used
-- Techniques: INNER JOIN, aggregation, grouping and sorting
-- Business Logic: Counts occurrences of each laundering pattern to identify trends
SELECT
    L.pattern_name,
    COUNT(T.transaction_id) AS rate
FROM
    FINANCIAL_TRANSACTION T
INNER JOIN
    LAUNDERING_PATTERN L ON T.pattern_id = L.pattern_id
GROUP BY
    L.pattern_name
ORDER BY
    rate DESC;

.www
-- 7. What is the most common form of payment that launderers use?
-- Purpose: Identify which payment channels are most vulnerable to money laundering
-- Techniques: Filtering, grouping, aggregation, and limiting
-- Business Logic: Counts payment methods used in suspicious transactions to find the most common
SELECT
    form_of_payment,
    COUNT(*) AS rate
FROM
    FINANCIAL_TRANSACTION
WHERE
    pattern_id IS NOT NULL
    AND form_of_payment IS NOT NULL
GROUP BY
    form_of_payment
ORDER BY
    rate DESC
LIMIT 5;

.www
-- 8. What is the total amount of money sent between September 3rd and September 8th?
-- Purpose: Monitor transaction volumes for a specific date range across currencies
-- Techniques: Date filtering, aggregation (SUM), grouping by currency
-- Business Logic: Calculates total transaction amounts per currency for the specified period
SELECT
    currency_sent,
    SUM(amount_sent) AS totalCurrencyValue
FROM
    FINANCIAL_TRANSACTION
WHERE
    DATE(timestamp) >= '2022-09-03'
    AND DATE(timestamp) <= '2022-09-08'
    AND amount_sent IS NOT NULL
    AND currency_sent IS NOT NULL
GROUP BY
    currency_sent
ORDER BY
    currency_sent;

.www
-- 9. List the currencies in order of how often they're used in illicit activity from most to least
-- Purpose: Identify which currencies are most commonly used in money laundering
-- Techniques: CTE with UNION ALL, grouping, aggregation, and sorting
-- Business Logic: Combines source and destination currencies to count total usage in suspicious transactions
WITH ImplicatedCurrency AS (
    SELECT currency_sent AS currency FROM FINANCIAL_TRANSACTION
    WHERE pattern_id IS NOT NULL AND currency_sent IS NOT NULL
    UNION ALL
    SELECT currency_received AS currency FROM FINANCIAL_TRANSACTION
    WHERE pattern_id IS NOT NULL AND currency_received IS NOT NULL
)
SELECT
    currency,
    COUNT(*) AS rate
FROM
    ImplicatedCurrency
GROUP BY
    currency
ORDER BY
    rate DESC;

.www
-- 10. Track the total transaction count and total illicit transaction count of source-destination pairs
-- Purpose: Analyze transaction patterns between account pairs to identify high-risk relationships
-- Techniques: Aggregation, conditional counting, and sorting
-- Business Logic: Counts total and illicit transactions for each source-destination pair to assess risk
-- Note: transSADAPID(source_account, dest_account, pattern_id) 

SELECT
    source_account,
    dest_account,
    COUNT(*) AS transaction_count,
    SUM(CASE
            WHEN (pattern_id = 11 or pattern_id = 12 or pattern_id = 13 
            or pattern_id = 14 or pattern_id = 15 or pattern_id = 16 or pattern_id = 17 or pattern_id = 18) THEN 1
            ELSE 0                                                
        END) AS illicit_transaction_count  
FROM
    FINANCIAL_TRANSACTION
WHERE
    source_account IS NOT NULL        
    AND dest_account IS NOT NULL      
GROUP BY
    source_account,
    dest_account                      
ORDER BY
    illicit_transaction_count  DESC            
LIMIT 20;    