/*
  FRAUD DETECTION ANALYTICS PROJECT
  STEP 1: EXPLORATORY DATA ANALYSIS (EDA)
  Database Platform: Microsoft SQL Server
  Table Name: Fraud

  Columns:
  step, type, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
  nameDest, oldbalanceDest, newbalanceDest, isFraud,
  isFlaggedFraud

  BUSINESS QUESTION 1:
  WHERE IS FRAUD OCCURRING MOST FREQUENTLY?

  Available dimensions:
  - Transaction step
  - Transaction type
  - Origin account
  - Destination account
*/

-- 1.1 Overall Fraud Dataset Analysis
SELECT
    COUNT_BIG(*) AS TotalRecords,
    COUNT(DISTINCT step) AS DistinctSteps,
    COUNT(DISTINCT type) AS DistinctTransactionTypes,
    COUNT(DISTINCT nameOrig) AS DistinctOriginAccounts,
    COUNT(DISTINCT nameDest) AS DistinctDestinationAccounts,
    SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS FraudRecords,
    SUM(CASE WHEN isFraud = 0 THEN 1 ELSE 0 END) AS NonFraudRecords,
    SUM(CASE WHEN isFraud IS NULL THEN 1 ELSE 0 END) AS RecordsWithUnknownFraudStatus,
    MIN(step) AS FirstStep,
    MAX(step) AS LastStep
FROM Fraud;


-- 1.2 Fraud Frequency by Transaction Type
SELECT
    type AS TransactionType,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS FraudTransactions,
    SUM(CASE WHEN isFraud = 0 THEN 1 ELSE 0 END) AS NonFraudTransactions,
    CAST(
        100.0 * SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10, 4)
    ) AS FraudRatePercent
FROM Fraud
GROUP BY type
ORDER BY FraudTransactions DESC;


-- 1.3 Fraud Frequency by Transaction Step

SELECT
    TRY_CONVERT(DECIMAL(18,2), oldbalanceOrg)
      - TRY_CONVERT(DECIMAL(18,2), newbalanceOrig)
        AS BalanceDifference,

    COUNT_BIG(*) AS TotalTransactions,

    SUM(
        CASE
            WHEN TRY_CONVERT(INT, isFraud) = 1 THEN 1
            ELSE 0
        END
    ) AS FraudTransactions,

    SUM(
        CASE
            WHEN TRY_CONVERT(INT, isFraud) = 1
            THEN TRY_CONVERT(DECIMAL(18,2), amount)
            ELSE 0
        END
    ) AS FraudAmount,

    CAST(
        100.0 * SUM(
            CASE
                WHEN TRY_CONVERT(INT, isFraud) = 1 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(10,4)
    ) AS FraudRatePercent

FROM Fraud

GROUP BY
    TRY_CONVERT(DECIMAL(18,2), oldbalanceOrg)
      - TRY_CONVERT(DECIMAL(18,2), newbalanceOrig)

ORDER BY
    FraudTransactions DESC,
    BalanceDifference DESC;


-- 1.4 Origin Accounts with the Most Fraudulent Transactions
SELECT TOP (50)
    nameOrig AS OriginAccount,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(INT, isFraud) = 1 THEN 1 ELSE 0 END) AS FraudTransactions,
    SUM(CASE WHEN TRY_CONVERT(INT, isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS TotalFraudAmount,
    MAX(TRY_CONVERT(DECIMAL(18,2), amount)) AS MaximumTransactionAmount
FROM Fraud
WHERE nameOrig IS NOT NULL
GROUP BY nameOrig
HAVING SUM(CASE WHEN TRY_CONVERT(INT, isFraud) = 1 THEN 1 ELSE 0 END) > 0
ORDER BY FraudTransactions DESC, TotalFraudAmount DESC;

-- 1.5 Destination Accounts Receiving Fraudulent Transactions
SELECT TOP (50)
    nameDest AS DestinationAccount,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(INT, isFraud) = 1 THEN 1 ELSE 0 END) AS FraudTransactions,
    SUM(CASE WHEN TRY_CONVERT(INT, isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudAmountReceived
FROM Fraud
WHERE nameDest IS NOT NULL
GROUP BY nameDest
HAVING SUM(CASE WHEN TRY_CONVERT(INT, isFraud) = 1 THEN 1 ELSE 0 END) > 0
ORDER BY FraudTransactions DESC, FraudAmountReceived DESC;


/*
  BUSINESS QUESTION 2:
  WHICH CUSTOMERS, ACCOUNTS, MERCHANTS, OR PAYMENT CHANNELS
  HAVE THE HIGHEST FRAUD EXPOSURE?
*/

-- 2.1 Highest Fraud Exposure by Origin Account
SELECT TOP (50)
    nameOrig AS OriginAccount,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(TRY_CONVERT(DECIMAL(18,2), amount)) AS TotalTransactionValue,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue,
    CAST(100.0 * SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,4)) AS AccountFraudRatePercent
FROM Fraud
WHERE nameOrig IS NOT NULL
GROUP BY nameOrig
ORDER BY FraudValue DESC, FraudCount DESC;


-- 2.2 Highest Fraud Exposure by Destination Account
SELECT TOP (50)
    nameDest AS DestinationAccount,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(TRY_CONVERT(DECIMAL(18,2), amount)) AS TotalTransactionValue,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue
FROM Fraud
WHERE nameDest IS NOT NULL
GROUP BY nameDest
ORDER BY FraudValue DESC, FraudCount DESC;


-- 2.3 Fraud Exposure by Transaction Type

SELECT type AS TransactionType, COUNT_BIG(*) AS TotalTransactions,
    SUM(TRY_CONVERT(DECIMAL(18,2), amount)) AS TotalTransactionValue,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue,
    CAST(100.0 * SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END)
        / NULLIF(SUM(TRY_CONVERT(DECIMAL(18,2), amount)), 0)
        AS DECIMAL(10,4)) AS FraudValuePercentOfTransactionValue
FROM Fraud
GROUP BY type
ORDER BY FraudValue DESC;


-- 2.4 Accounts with Repeated Fraud Activity


SELECT nameOrig AS OriginAccount,
    COUNT_BIG(*) AS FraudTransactionCount,
    SUM(TRY_CONVERT(DECIMAL(18,2), amount)) AS TotalFraudValue,
    MIN(TRY_CONVERT(INT, step)) AS FirstFraudStep,
    MAX(TRY_CONVERT(INT, step)) AS LatestFraudStep
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
  AND nameOrig IS NOT NULL
GROUP BY nameOrig
HAVING COUNT_BIG(*) > 1
ORDER BY FraudTransactionCount DESC, TotalFraudValue DESC;


/*
  BUSINESS QUESTION 3:
  ARE FRAUD LOSSES INCREASING OR DECREASING OVER TIME ('Step' in this dataset)?
.
*/


-- 3.1 Fraud Trend by Step


SELECT step, COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue,
    CAST(100.0 * SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,4)) AS FraudRatePercent
FROM Fraud
GROUP BY step
ORDER BY TRY_CONVERT(INT, step);


-- 3.2 Fraud Trend by Step Group (10-Step Intervals)

SELECT (TRY_CONVERT(INT, step) / 10) * 10 AS StepGroupStart,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue,
    CAST(100.0 * SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,4)) AS FraudRatePercent
FROM Fraud
WHERE TRY_CONVERT(INT, step) IS NOT NULL
GROUP BY (TRY_CONVERT(INT, step) / 10) * 10
ORDER BY StepGroupStart;



/*
  BUSINESS QUESTION 4:
  WHAT TRANSACTION CHARACTERISTICS ARE ASSOCIATED WITH
  FRAUDULENT ACTIVITY?
*/

-- 4.1 Compare Fraudulent and Non Fraudulent Transaction Amounts

SELECT CASE
    WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 'Fraud'
    WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 0 THEN 'Non-Fraud'
    ELSE 'Unknown' END AS FraudStatus,
    COUNT_BIG(*) AS TransactionCount,
    AVG(TRY_CONVERT(DECIMAL(38,4), amount)) AS AverageAmount,
    MIN(TRY_CONVERT(DECIMAL(18,2), amount)) AS MinimumAmount,
    MAX(TRY_CONVERT(DECIMAL(18,2), amount)) AS MaximumAmount,
    SUM(TRY_CONVERT(DECIMAL(38,4), amount)) AS TotalTransactionValue
FROM Fraud
GROUP BY CASE
    WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 'Fraud'
    WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 0 THEN 'Non-Fraud'
    ELSE 'Unknown' END
ORDER BY FraudStatus;


-- 4.2 Fraud Rate by Transaction Amount Band


WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(18,2), amount) AS amt,
           TRY_CONVERT(DECIMAL(10,2), isFraud) AS fraud
    FROM Fraud
)
SELECT CASE
    WHEN amt < 1000 THEN '01. Under 1,000'
    WHEN amt < 10000 THEN '02. 1,000 to 9,999.99'
    WHEN amt < 50000 THEN '03. 10,000 to 49,999.99'
    WHEN amt < 100000 THEN '04. 50,000 to 99,999.99'
    WHEN amt < 500000 THEN '05. 100,000 to 499,999.99'
    WHEN amt >= 500000 THEN '06. 500,000 and Above'
    ELSE 'Unknown' END AS AmountBand,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN fraud = 1 THEN amt ELSE 0 END) AS FraudValue,
    CAST(100.0 * SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END)
         / COUNT_BIG(*) AS DECIMAL(10,4)) AS FraudRatePercent
FROM F
GROUP BY CASE
    WHEN amt < 1000 THEN '01. Under 1,000'
    WHEN amt < 10000 THEN '02. 1,000 to 9,999.99'
    WHEN amt < 50000 THEN '03. 10,000 to 49,999.99'
    WHEN amt < 100000 THEN '04. 50,000 to 99,999.99'
    WHEN amt < 500000 THEN '05. 100,000 to 499,999.99'
    WHEN amt >= 500000 THEN '06. 500,000 and Above'
    ELSE 'Unknown' END
ORDER BY AmountBand;


-- 4.3 Fraud Rate by Transaction Type

SELECT type AS TransactionType, COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    AVG(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(38,4), amount) END) AS AverageFraudAmount,
    AVG(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 0
        THEN TRY_CONVERT(DECIMAL(38,4), amount) END) AS AverageNonFraudAmount,
    CAST(100.0 * SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,4)) AS FraudRatePercent
FROM Fraud
GROUP BY type
ORDER BY FraudRatePercent DESC;


-- 4.4 Origin Account Balance Changes for Fraudulent Transactions

SELECT COUNT_BIG(*) AS FraudTransactions,
    SUM(CASE WHEN oldbalanceOrg IS NULL THEN 1 ELSE 0 END) AS MissingOldOriginBalance,
    SUM(CASE WHEN newbalanceOrig IS NULL THEN 1 ELSE 0 END) AS MissingNewOriginBalance,
    AVG(TRY_CONVERT(DECIMAL(38,4), oldbalanceOrg)) AS AverageOldOriginBalance,
    AVG(TRY_CONVERT(DECIMAL(38,4), newbalanceOrig)) AS AverageNewOriginBalance,
    AVG(TRY_CONVERT(DECIMAL(38,4), oldbalanceOrg) -
        TRY_CONVERT(DECIMAL(38,4), newbalanceOrig)) AS AverageOriginBalanceDecrease,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(38,4), newbalanceOrig) >
        TRY_CONVERT(DECIMAL(38,4), oldbalanceOrg) THEN 1 ELSE 0 END) AS OriginBalanceIncreasedCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(38,4), newbalanceOrig) =
        TRY_CONVERT(DECIMAL(38,4), oldbalanceOrg) THEN 1 ELSE 0 END) AS OriginBalanceUnchangedCount
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1;


-- 4.5 Destination Account Balance Changes for Fraudulent Transactions

SELECT COUNT_BIG(*) AS FraudTransactions,
    SUM(CASE WHEN oldbalanceDest IS NULL THEN 1 ELSE 0 END) AS MissingOldDestinationBalance,
    SUM(CASE WHEN newbalanceDest IS NULL THEN 1 ELSE 0 END) AS MissingNewDestinationBalance,
    AVG(TRY_CONVERT(DECIMAL(38,4), oldbalanceDest)) AS AverageOldDestinationBalance,
    AVG(TRY_CONVERT(DECIMAL(38,4), newbalanceDest)) AS AverageNewDestinationBalance,
    AVG(TRY_CONVERT(DECIMAL(38,4), newbalanceDest) -
        TRY_CONVERT(DECIMAL(38,4), oldbalanceDest)) AS AverageDestinationBalanceIncrease,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(38,4), newbalanceDest) >
        TRY_CONVERT(DECIMAL(38,4), oldbalanceDest) THEN 1 ELSE 0 END) AS DestinationBalanceIncreasedCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(38,4), newbalanceDest) =
        TRY_CONVERT(DECIMAL(38,4), oldbalanceDest) THEN 1 ELSE 0 END) AS DestinationBalanceUnchangedCount
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1;


-- 4.6 Fraud Rate by Origin Balance Adequacy

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(18,2), oldbalanceOrg) AS bal,
           TRY_CONVERT(DECIMAL(18,2), amount) AS amt,
           TRY_CONVERT(DECIMAL(10,2), isFraud) AS fraud
    FROM Fraud
)
SELECT CASE
    WHEN bal IS NULL THEN 'Unknown Balance'
    WHEN bal = 0 THEN 'Zero Starting Balance'
    WHEN amt > bal THEN 'Amount Exceeds Starting Balance'
    ELSE 'Amount Within Starting Balance'
    END AS OriginBalanceCategory,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS FraudCount,
    CAST(100.0 * SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END)
        / COUNT_BIG(*) AS DECIMAL(10,4)) AS FraudRatePercent
FROM F
GROUP BY CASE
    WHEN bal IS NULL THEN 'Unknown Balance'
    WHEN bal = 0 THEN 'Zero Starting Balance'
    WHEN amt > bal THEN 'Amount Exceeds Starting Balance'
    ELSE 'Amount Within Starting Balance'
    END
ORDER BY FraudRatePercent DESC;


/*
  BUSINESS QUESTION 5:
  WHICH SEGMENTS CONTRIBUTE THE MOST TO TOTAL FRAUD LOSSES?
*/


-- 5.1 Fraud Losses by Transaction Type

WITH F AS (
    SELECT type, TRY_CONVERT(DECIMAL(10,2), isFraud) AS fraud,
           TRY_CONVERT(DECIMAL(18,2), amount) AS amt
    FROM Fraud
)
SELECT type AS TransactionType,
    SUM(CASE WHEN fraud = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN fraud = 1 THEN amt ELSE 0 END) AS FraudValue,
    CAST(100.0 * SUM(CASE WHEN fraud = 1 THEN amt ELSE 0 END)
        / NULLIF(SUM(SUM(CASE WHEN fraud = 1 THEN amt ELSE 0 END)) OVER (), 0)
        AS DECIMAL(10,4)) AS ShareOfFraudValuePercent
FROM F
GROUP BY type
ORDER BY FraudValue DESC;


-- 5.2 Fraud Losses by Transaction Step

SELECT step,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue
FROM Fraud
GROUP BY step
HAVING SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) > 0
ORDER BY FraudValue DESC;


-- 5.3 Fraud Losses by Origin Account

SELECT TOP (50) nameOrig AS OriginAccount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue,
    MIN(TRY_CONVERT(INT, step)) AS FirstFraudStep,
    MAX(TRY_CONVERT(INT, step)) AS LastFraudStep
FROM Fraud
WHERE nameOrig IS NOT NULL
GROUP BY nameOrig
HAVING SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) > 0
ORDER BY FraudValue DESC;


-- 5.4 Fraud Losses by Destination Account

SELECT TOP (50) nameDest AS DestinationAccount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue
FROM Fraud
WHERE nameDest IS NOT NULL
GROUP BY nameDest
HAVING SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) > 0
ORDER BY FraudValue DESC;


/*
  BUSINESS QUESTION 6:
  ARE THERE UNUSUAL TRANSACTION PATTERNS THAT REQUIRE
  INVESTIGATION?
*/

-- 6.1 Transactions Flagged by the System but Not Confirmed as Fraud

SELECT
    step,
    type,
    amount,
    nameOrig,
    nameDest,
    isFraud,
    isFlaggedFraud
FROM Fraud
WHERE isFlaggedFraud = 1
  AND (isFraud = 0 OR isFraud IS NULL)
ORDER BY amount DESC;


-- 6.2 Fraudulent Transactions Not Flagged by the System
SELECT
    step,
    type,
    amount,
    nameOrig,
    nameDest,
    isFraud,
    isFlaggedFraud
FROM Fraud
WHERE isFraud = 1
  AND (isFlaggedFraud = 0 OR isFlaggedFraud IS NULL)
ORDER BY amount DESC;


-- 6.3 High Value Transactions

WITH F AS (
    SELECT *, TRY_CONVERT(FLOAT, amount) AS amt
    FROM Fraud
)
SELECT step, type, amount, nameOrig, nameDest, oldbalanceOrg,
       newbalanceOrig, oldbalanceDest, newbalanceDest, isFraud, isFlaggedFraud
FROM F
WHERE amt >= (SELECT AVG(amt) + 3 * STDEV(amt) FROM F WHERE amt IS NOT NULL)
ORDER BY amt DESC;




-- 6.4 Transactions with Suspicious Destination Balance Changes

SELECT
    step,
    type,
    amount,
    nameOrig,
    nameDest,
    oldbalanceDest,
    newbalanceDest,
    newbalanceDest - oldbalanceDest AS DestinationBalanceIncrease,
    isFraud,
    isFlaggedFraud
FROM Fraud
WHERE oldbalanceDest IS NOT NULL
  AND newbalanceDest IS NOT NULL
  AND newbalanceDest = oldbalanceDest
  AND amount > 0
ORDER BY amount DESC;


-- 6.5 Multiple Transactions from the Same Origin Account within the Same Step

SELECT step, nameOrig AS OriginAccount, COUNT_BIG(*) AS TransactionsInStep,
    SUM(TRY_CONVERT(DECIMAL(18,2), amount)) AS TotalAmountInStep,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
        THEN TRY_CONVERT(DECIMAL(18,2), amount) ELSE 0 END) AS FraudValue
FROM Fraud
WHERE nameOrig IS NOT NULL
GROUP BY step, nameOrig
HAVING COUNT_BIG(*) > 1
ORDER BY TransactionsInStep DESC, TotalAmountInStep DESC;


-- 6.6 Repeated Destination Accounts within the Same Step

SELECT step, nameDest AS DestinationAccount, COUNT_BIG(*) AS IncomingTransactions,
    SUM(TRY_CONVERT(DECIMAL(18,2), amount)) AS TotalIncomingAmount,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(10,2), isFraud) = 1 THEN 1 ELSE 0 END) AS FraudCount
FROM Fraud
WHERE nameDest IS NOT NULL
GROUP BY step, nameDest
HAVING COUNT_BIG(*) > 1
ORDER BY IncomingTransactions DESC, TotalIncomingAmount DESC;


-- 6.7 Potential Duplicate Transaction Records

SELECT
    step,
    type,
    amount,
    nameOrig,
    nameDest,
    oldbalanceOrg,
    newbalanceOrig,
    oldbalanceDest,
    newbalanceDest,
    COUNT_BIG(*) AS MatchingRecordCount
FROM Fraud
GROUP BY
    step,
    type,
    amount,
    nameOrig,
    nameDest,
    oldbalanceOrg,
    newbalanceOrig,
    oldbalanceDest,
    newbalanceDest
HAVING COUNT_BIG(*) > 1
ORDER BY MatchingRecordCount DESC, amount DESC;


/*
  BUSINESS QUESTION 7:
  HOW MUCH FRAUD RELATED VALUE HAS BEEN RECOVERED,
  AND HOW MUCH REMAINS OUTSTANDING?
*/

-- 7.1 Recorded Fraudulent Transaction Value

SELECT COUNT_BIG(*) AS FraudulentTransactionCount,
    SUM(TRY_CONVERT(DECIMAL(38,4), amount)) AS TotalRecordedFraudValue,
    AVG(TRY_CONVERT(DECIMAL(38,4), amount)) AS AverageFraudTransactionValue,
    MIN(TRY_CONVERT(DECIMAL(38,4), amount)) AS SmallestFraudTransaction,
    MAX(TRY_CONVERT(DECIMAL(38,4), amount)) AS LargestFraudTransaction,
    CAST(NULL AS DECIMAL(38,4)) AS RecoveredAmount,
    CAST(NULL AS DECIMAL(38,4)) AS OutstandingAmount
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1;


/*
  BUSINESS QUESTION 8:
  WHICH FRAUD INDICATORS OR CONTROLS MAY NEED IMPROVEMENT?
*/


-- 8.1 Overall Fraud Detection and Flagging Performance

SELECT
    COUNT_BIG(*) AS TotalTransactions,

    SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) AS TruePositives,

    SUM(CASE
            WHEN isFraud = 0 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) AS FalsePositives,

    SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 0 THEN 1
            ELSE 0
        END) AS FalseNegatives,

    SUM(CASE
            WHEN isFraud = 0 AND isFlaggedFraud = 0 THEN 1
            ELSE 0
        END) AS TrueNegatives,

    CAST(
        100.0 * SUM(CASE
                        WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
                        ELSE 0
                    END)
        / NULLIF(SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(10, 4)
    ) AS FraudDetectionRecallPercent,

    CAST(
        100.0 * SUM(CASE
                        WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
                        ELSE 0
                    END)
        / NULLIF(SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(10, 4)
    ) AS FlagPrecisionPercent
FROM Fraud
WHERE isFraud IN (0, 1)
  AND isFlaggedFraud IN (0, 1);


-- 8.2 Flagging Performance by Transaction Type

SELECT
    type AS TransactionType,
    COUNT_BIG(*) AS TotalTransactions,
    SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS ActualFraudCount,
    SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END) AS FlaggedCount,
    SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) AS CorrectlyFlaggedFraud,
    SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 0 THEN 1
            ELSE 0
        END) AS MissedFraudCount,
    SUM(CASE
            WHEN isFraud = 0 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) AS FalseAlarmCount
FROM Fraud
WHERE isFraud IN (0, 1)
  AND isFlaggedFraud IN (0, 1)
GROUP BY type
ORDER BY MissedFraudCount DESC;


-- 8.3 Missed Fraud by Transaction Amount Band

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(18,2), amount) AS amt,
           TRY_CONVERT(DECIMAL(10,2), isFraud) AS fraud,
           TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) AS flagged
    FROM Fraud
)
SELECT CASE
    WHEN amt < 1000 THEN '01. Under 1,000'
    WHEN amt < 10000 THEN '02. 1,000 to 9,999.99'
    WHEN amt < 50000 THEN '03. 10,000 to 49,999.99'
    WHEN amt < 100000 THEN '04. 50,000 to 99,999.99'
    WHEN amt < 500000 THEN '05. 100,000 to 499,999.99'
    WHEN amt >= 500000 THEN '06. 500,000 and Above'
    ELSE 'Unknown' END AS AmountBand,
    COUNT_BIG(*) AS FraudTransactions,
    SUM(CASE WHEN flagged = 1 THEN 1 ELSE 0 END) AS FlaggedFraud,
    SUM(CASE WHEN flagged = 0 THEN 1 ELSE 0 END) AS MissedFraud,
    SUM(CASE WHEN flagged = 0 THEN amt ELSE 0 END) AS MissedFraudValue
FROM F
WHERE fraud = 1
GROUP BY CASE
    WHEN amt < 1000 THEN '01. Under 1,000'
    WHEN amt < 10000 THEN '02. 1,000 to 9,999.99'
    WHEN amt < 50000 THEN '03. 10,000 to 49,999.99'
    WHEN amt < 100000 THEN '04. 50,000 to 99,999.99'
    WHEN amt < 500000 THEN '05. 100,000 to 499,999.99'
    WHEN amt >= 500000 THEN '06. 500,000 and Above'
    ELSE 'Unknown' END
ORDER BY AmountBand;

/*
  BUSINESS QUESTION 9:
  HOW CAN THE ORGANIZATION PRIORITIZE INVESTIGATION RESOURCES?
*/


-- 9.1 Rank Origin Accounts by Investigation Priority

WITH F AS (
    SELECT nameOrig, TRY_CONVERT(DECIMAL(18,2), amount) AS amt,
           TRY_CONVERT(INT, step) AS st
    FROM Fraud
    WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
)
SELECT TOP (100) nameOrig AS OriginAccount, COUNT_BIG(*) AS FraudCount,
    SUM(amt) AS RecordedFraudValue, MAX(amt) AS LargestFraudTransaction,
    MIN(st) AS FirstFraudStep, MAX(st) AS LastFraudStep,
    CASE WHEN SUM(amt) >= 1000000 OR COUNT_BIG(*) >= 10 THEN 'High'
         WHEN SUM(amt) >= 100000 OR COUNT_BIG(*) >= 3 THEN 'Medium'
         ELSE 'Low' END AS SuggestedPriority
FROM F
WHERE nameOrig IS NOT NULL
GROUP BY nameOrig
ORDER BY CASE WHEN SUM(amt) >= 1000000 OR COUNT_BIG(*) >= 10 THEN 1
              WHEN SUM(amt) >= 100000 OR COUNT_BIG(*) >= 3 THEN 2 ELSE 3 END,
         RecordedFraudValue DESC, FraudCount DESC;


-- 9.2 Rank Fraudulent Transactions for Review

SELECT TOP (100) step, type, amount, nameOrig, nameDest, isFlaggedFraud,
    CASE
        WHEN TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) = 1
             AND TRY_CONVERT(DECIMAL(18,2), amount) >= 100000 THEN 'Urgent: Flagged High Value'
        WHEN TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) = 1 THEN 'High: System Flagged'
        WHEN TRY_CONVERT(DECIMAL(18,2), amount) >= 100000 THEN 'High: Unflagged High Value'
        ELSE 'Review: Fraudulent Transaction'
    END AS SuggestedReviewPriority
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
ORDER BY CASE
    WHEN TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) = 1
         AND TRY_CONVERT(DECIMAL(18,2), amount) >= 100000 THEN 1
    WHEN TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) = 1 THEN 2
    WHEN TRY_CONVERT(DECIMAL(18,2), amount) >= 100000 THEN 3
    ELSE 4 END,
    TRY_CONVERT(DECIMAL(18,2), amount) DESC;


/*
  BUSINESS QUESTION 10:
  WHAT MEASURABLE ACTIONS COULD REDUCE FUTURE FRAUD LOSSES?
*/


-- 10.1 Quantify Fraud Value Not Flagged by the Existing Control

SELECT COUNT_BIG(*) AS MissedFraudTransactions,
    SUM(TRY_CONVERT(DECIMAL(38,4), amount)) AS RecordedValueOfMissedFraud,
    AVG(TRY_CONVERT(DECIMAL(38,4), amount)) AS AverageMissedFraudAmount,
    MAX(TRY_CONVERT(DECIMAL(38,4), amount)) AS LargestMissedFraudAmount,
    COUNT(DISTINCT nameOrig) AS OriginAccountsInvolved,
    COUNT(DISTINCT nameDest) AS DestinationAccountsInvolved
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
  AND TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) = 0;


-- 10.2 Identify Transaction Types with High Missed Fraud Value

SELECT type AS TransactionType, COUNT_BIG(*) AS MissedFraudCount,
    SUM(TRY_CONVERT(DECIMAL(38,4), amount)) AS MissedFraudValue,
    AVG(TRY_CONVERT(DECIMAL(38,4), amount)) AS AverageMissedFraudAmount,
    MAX(TRY_CONVERT(DECIMAL(38,4), amount)) AS LargestMissedFraudAmount
FROM Fraud
WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
  AND TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) = 0
GROUP BY type
ORDER BY MissedFraudValue DESC;

-- 10.3 Measure the Potential Value of Reviewing High Value Fraud

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(38,4), amount) AS amount,
           TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) AS isFlaggedFraud
    FROM Fraud
    WHERE TRY_CONVERT(DECIMAL(10,2), isFraud) = 1
)
SELECT CASE
         WHEN amount < 10000 THEN 'Under 10,000'
         WHEN amount < 100000 THEN '10,000 to 99,999.99'
         WHEN amount < 500000 THEN '100,000 to 499,999.99'
         ELSE '500,000 and Above'
       END AS FraudAmountBand,
       COUNT_BIG(*) AS FraudCount,
       SUM(amount) AS RecordedFraudValue,
       SUM(CASE WHEN isFlaggedFraud = 0 THEN amount ELSE 0 END) AS UnflaggedFraudValue,
       SUM(CASE WHEN isFlaggedFraud = 1 THEN amount ELSE 0 END) AS FlaggedFraudValue
FROM F
GROUP BY CASE
           WHEN amount < 10000 THEN 'Under 10,000'
           WHEN amount < 100000 THEN '10,000 to 99,999.99'
           WHEN amount < 500000 THEN '100,000 to 499,999.99'
           ELSE '500,000 and Above'
         END
ORDER BY MIN(CASE
               WHEN amount < 10000 THEN 1
               WHEN amount < 100000 THEN 2
               WHEN amount < 500000 THEN 3
               ELSE 4
             END);

-- 10.4 Compare Fraud Rates Before and After a Candidate Amount Threshold

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(38,4), amount) AS amount,
           TRY_CONVERT(DECIMAL(10,2), isFraud) AS isFraud
    FROM Fraud
)
SELECT ThresholdAmount,
       COUNT_BIG(*) AS TransactionsAtOrAboveThreshold,
       SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS FraudCount,
       SUM(CASE WHEN isFraud = 1 THEN amount ELSE 0 END) AS FraudValue,
       CAST(100.0 * SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,4)) AS FraudRatePercent
FROM F
CROSS JOIN (SELECT 10000 AS ThresholdAmount UNION ALL SELECT 50000
            UNION ALL SELECT 100000 UNION ALL SELECT 500000) T
WHERE amount >= ThresholdAmount
GROUP BY ThresholdAmount
ORDER BY ThresholdAmount;


-- 10.5 Summarize Measurable Baseline Fraud KPIs

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(38,4), amount) AS amount,
           TRY_CONVERT(DECIMAL(10,2), isFraud) AS isFraud,
           TRY_CONVERT(DECIMAL(10,2), isFlaggedFraud) AS isFlaggedFraud
    FROM Fraud
)
SELECT COUNT_BIG(*) AS TotalTransactions,
       SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) AS TotalFraudTransactions,
       SUM(CASE WHEN isFraud = 1 THEN amount ELSE 0 END) AS TotalRecordedFraudValue,
       CAST(100.0 * SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END) / NULLIF(COUNT_BIG(*),0) AS DECIMAL(10,4)) AS OverallFraudRatePercent,
       SUM(CASE WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1 ELSE 0 END) AS FraudTransactionsFlagged,
       SUM(CASE WHEN isFraud = 1 AND isFlaggedFraud = 0 THEN 1 ELSE 0 END) AS FraudTransactionsNotFlagged,
       SUM(CASE WHEN isFraud = 1 AND isFlaggedFraud = 0 THEN amount ELSE 0 END) AS RecordedValueOfUnflaggedFraud,
       CAST(100.0 * SUM(CASE WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1 ELSE 0 END) / NULLIF(SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END),0) AS DECIMAL(10,4)) AS FraudDetectionRecallPercent,
       SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END) AS TotalFlaggedTransactions,
       SUM(CASE WHEN isFraud = 0 AND isFlaggedFraud = 1 THEN 1 ELSE 0 END) AS FalsePositiveCount
FROM F
WHERE isFraud IN (0,1) AND isFlaggedFraud IN (0,1);


-- 11. Transaction Amount Distribution Statistics

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(38,4), amount) AS amount
    FROM Fraud
)
SELECT COUNT_BIG(amount) AS NonNullAmountCount,
       AVG(amount) AS AverageAmount,
       MIN(amount) AS MinimumAmount,
       MAX(amount) AS MaximumAmount,
       STDEV(CAST(amount AS FLOAT)) AS StandardDeviationAmount,
       VAR(CAST(amount AS FLOAT)) AS VarianceAmount,
       SUM(CASE WHEN amount = 0 THEN 1 ELSE 0 END) AS ZeroAmountCount,
       SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END) AS NegativeAmountCount,
       SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS NullAmountCount
FROM F;


-- 12. Approximate Median Transaction Amount

WITH F AS (
    SELECT TRY_CONVERT(DECIMAL(38,4), amount) AS amount
    FROM Fraud
)
SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)
        OVER () AS MedianTransactionAmount
FROM F
WHERE amount IS NOT NULL;


-- 13. Distinct Customer/Account Analysis

SELECT
    COUNT(DISTINCT nameOrig) AS DistinctOriginAccounts,
    COUNT(DISTINCT nameDest) AS DistinctDestinationAccounts
FROM Fraud;

-- 14. Categorical Variable Distribution

SELECT type AS TransactionType, isFraud, isFlaggedFraud,
       COUNT_BIG(*) AS RecordCount,
       SUM(TRY_CONVERT(DECIMAL(38,4), amount)) AS TotalAmount
FROM Fraud
GROUP BY type, isFraud, isFlaggedFraud
ORDER BY type, isFraud, isFlaggedFraud;
