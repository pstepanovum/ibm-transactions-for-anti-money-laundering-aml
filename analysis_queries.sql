--1. Using the TELLER view, find when account 8000EC1E0 sent or received a check on September 2nd
SELECT *
FROM TELLER
WHERE (source_account = '8000EC1E0' or dest_account = '8000EC1E0') and (form_of_payment = 'Cheque') and (timestamp LIKE '%-09-02 %');


--2. Identify round number transactions (often indicate structured/artificial transactions)
SELECT
    T.transaction_id,
    T.timestamp,
    T.source_account,
    T.source_bank,
    T.dest_account,
    T.dest_bank,
    T.amount_sent,
    T.currency_sent,
    CASE
        WHEN T.amount_sent % 1000 = 0 THEN 'EXACT_THOUSAND'
        WHEN T.amount_sent % 500 = 0 THEN 'EXACT_500'
        WHEN T.amount_sent % 100 = 0 THEN 'EXACT_100'
        ELSE 'NOT_ROUND'
    END as round_amount_type
FROM
    FINANCIAL_TRANSACTION T
WHERE
    (T.amount_sent % 1000 = 0 or T.amount_sent % 500 = 0 or T.amount_sent % 100 = 0)
    and T.amount_sent > 1000  -- Focus on larger transactions
ORDER BY
    T.amount_sent DESC
LIMIT 50;



--3. Which bank has the highest rate of illicit activity in their transactions?
SELECT
    B.name AS bank_name,
    AggregatedRates.illicit_rate,
    AggregatedRates.illicit_transactions,
    AggregatedRates.total_transactions
FROM (
    SELECT
        bank_id,
        COUNT(*) AS total_transactions,
        SUM(is_illicit) AS illicit_transactions,
        -- Calculate rate as percentage
        CAST(SUM(is_illicit) AS REAL) * 100.0 / COUNT(*) AS illicit_rate
    FROM (
        -- list all banks
        SELECT
            source_bank AS bank_id,
            CASE
                WHEN pattern_id != 10 THEN 1 -- Illicit
                ELSE 0 
            END AS is_illicit
        FROM FINANCIAL_TRANSACTION

        UNION ALL -- Combine source and destination transactions

        SELECT
            dest_bank AS bank_id,
            CASE
                WHEN pattern_id != 10 THEN 1 -- Illicit
                ELSE 0
            END AS is_illicit
        FROM FINANCIAL_TRANSACTION
    ) AS BankParticipationData 
    
    GROUP BY bank_id

    HAVING COUNT(*) > 0
) AS AggregatedRates 
JOIN BANK B ON AggregatedRates.bank_id = B.bank_id
ORDER BY AggregatedRates.illicit_rate DESC
LIMIT 1;


--4. What type of accounts are more often implicated in laundering: individuals or companies?
WITH IllicitTransactionAccounts AS (
    -- Get a DISTINCT list of all account IDs involved in illicit transactions
    SELECT DISTINCT source_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE pattern_id != 10 AND source_account IS NOT NULL

    UNION -- removes duplicates

    SELECT DISTINCT dest_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE pattern_id != 10 AND dest_account IS NOT NULL

), AccountTypeStats AS (
    -- Calculate total accounts and implicated accounts for relevant types
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
-- Final SELECT to calculate and compare the implication rates
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



--5.List the three countries with the most launderers in alphabetical order
WITH LaunderingAccounts AS (
    SELECT DISTINCT source_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE pattern_id != 10 AND source_account IS NOT NULL

    UNION 

    SELECT DISTINCT dest_account AS account_id
    FROM FINANCIAL_TRANSACTION
    WHERE pattern_id != 10 AND dest_account IS NOT NULL

), CountryLaundererCounts AS (
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

), Top3CountriesByCount AS (
    SELECT
        country,
        unique_launderer_accounts
    FROM
        CountryLaundererCounts
    ORDER BY
        unique_launderer_accounts DESC
    LIMIT 3
)

SELECT
    country,
    unique_launderer_accounts
FROM
    Top3CountriesByCount
ORDER BY
    country ASC;



--6. On what day and at what time did the most laundering occur?
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
LIMIT 1;



--7. List the names of the laundering patterns in order of how often they occur from most to least
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


--8. What is the most common form of payment that launderers use?
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
LIMIT 1;


--9. What is the total amount of money sent between September 3rd and September 8th?
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



--10. List the currencies in order of how often they're used in illicit activity from most to least
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
