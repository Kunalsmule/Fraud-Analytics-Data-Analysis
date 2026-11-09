# Fraud Analytics: Data Analysis

**Tools:** SQL Server · Python · Power BI
**Project focus:** Fraud pattern analysis, transaction behavior, balance anomalies and fraud control performance

## 1. Executive Summary & Management Problem

This project investigates fraudulent financial transactions, examines transaction level balance behavior and evaluates the performance of an existing fraud flagging indicator. The objective is to help management understand where fraud is concentrated, identify patterns that warrant investigation and assess whether existing controls are capturing known fraudulent activity.

The central management problem is a potential gap between actual fraudulent transactions and transactions identified by the existing flagging mechanism.

**Management decisions supported by this analysis:**

- Which transaction types should receive greater investigative attention?
- Where does the existing flagging indicator fail to capture known fraud?
- Which transaction and balance patterns are useful for prioritising investigation?
- What control performance metrics should be monitored?
- What additional validation is required before proposed control changes are implemented?

## 2. Dataset, Preparation & Data Quality

The `Fraud` table contains transaction step and type, amount, origin and destination account identifiers, opening and closing balances, and the `isFraud` and `isFlaggedFraud` indicators.

SQL Server provided the structured reporting source, while a separate CSV copy was analysed in Google Colab. The original Python DataFrame was preserved, with numeric conversion and feature engineering performed on a separate analysis copy. Numeric fields and fraud indicators were standardised, account identifiers and transaction types remained text.

**Data quality controls and validation**

- **Missing values:** Check nulls in transaction amounts, balances, transaction types, account identifiers and fraud indicators. Quantify missingness by column and assess its impact before excluding or imputing records.
- **Duplicates:** Check exact duplicate rows and repeated transaction identifiers, where available. Distinguish genuine repeated activity from duplicate records.
- **Invalid values:** Identify failed numeric conversions, negative or implausible amounts, invalid fraud flags, unsupported transaction types and inconsistent balance values.
- **Referential and logical checks:** Review account identifiers, transaction type consistency and balance movements against applicable business rules.
- **Reconciliation:** Compare transaction and fraud counts across SQL Server, Python and Power BI.

Numeric conversion used SQL `TRY_CONVERT` and Python `pandas.to_numeric(errors="coerce")` to expose conversion failures rather than silently treating invalid values as valid numbers. A 0.01 tolerance was used for near zero balance comparisons.

**Validation status:** The Power BI fraud reconciliation check passed: flagged fraud (16) plus unflagged fraud (8,197) equals total fraud (8,213). Actual missing value, duplicate and invalid record counts, and full SQL to Python to Power BI reconciliation.

## 3. Analytical Approach

**SQL Server:** Structured data preparation, numeric type handling and reporting support.

**Python:** Fraud versus legitimate comparisons, transaction type segmentation, balance discrepancy analysis, zero destination balance movement analysis, high value outlier identification and visualization.

Derived features included:

- Origin balance movement = opening origin balance closing origin balance.
- Destination balance movement = closing destination balance opening destination balance.
- Origin and destination discrepancies = corresponding movement compared with transaction amount.
- Absolute discrepancies and transaction specific balance behaviors for exploratory investigation.

The IQR method, applied to legitimate transactions, produced a high value threshold of **500,859.31**. A total of **339,209 transactions**, including **3,862 fraud cases**, exceeded it. This defines a review population, not a fraud classification rule.

Balance discrepancies and zero movements were treated as investigation signals, not proof of fraud, because transaction types have different accounting behaviour.

## 4. Power BI Reporting

The four page interactive report provides:

1. **Fraud Overview:** Transaction and fraud KPIs, fraud by type, transaction volume by fraud status and fraud counts across the `step` time index.
2. **Transaction Behaviour:** Total, average and median transaction amounts; transaction type comparisons; transaction value and volume.
3. **Anomaly & Balance Analysis:** High value transactions, average balances, discrepancy rates and zero destination balance movement comparisons.
4. **Fraud Control & Monitoring:** Fraud, flagged and unflagged cases, fraud capture rate, unflagged cases by type, capture rate by type, unflagged fraud transaction value, flag precision and reconciliation.

Key measures:

- **Fraud capture rate:** Flagged fraud / all fraud.
- **Flag precision:** Flagged fraud / all flagged transactions.
- **Unflagged fraud:** Fraud cases where `isFlaggedFraud = 0`.
- **Fraud reconciliation:** Flagged fraud + unflagged fraud = total fraud.

## 5. Key Findings & Business Insights

- **8,213 fraudulent transactions** represented approximately **0.13%** of all transactions. Only **16** were flagged; **8,197** were unflagged. Fraud capture rate was approximately **0.19%**.
- Fraud was concentrated in **CASH_OUT and TRANSFER**. Unflagged fraud comprised 4,116 CASH_OUT and 4,081 TRANSFER cases. All 16 flagged fraud cases were TRANSFER.
- Median fraudulent transaction amount was **441,423.44**, compared with **74,684.72** for legitimate transactions.
- For TRANSFER, zero destination balance movement occurred in **99.29%** of fraud cases versus **0.02%** of legitimate cases. Destination discrepancy occurred in **99.95%** of fraud versus **21.83%** of legitimate transfers.
- For CASH_OUT, origin discrepancy was observed in **0.58%** of fraud versus **89.12%** of legitimate transactions. This reinforces the need for transaction specific interpretation.
- Unflagged fraudulent transaction value was approximately **6 billion** for each of CASH_OUT and TRANSFER. This is associated transaction value, **not confirmed realised financial loss**.

## 6. Management Recommendations, Benefits & Measurement

**Recommended actions**

1. Priorities investigative review of unflagged CASH_OUT and TRANSFER transactions.
2. Evaluate transaction type specific balance patterns as candidate risk indicators, subject to accounting rule validation.
3. Review why the existing flagging indicator captures so few known fraud cases.
4. Assess proposed control changes using a separate time based holdout sample before deployment.
5. Establish recurring monitoring of capture rate, flag precision, false positives and transaction type performance.

**Potential benefits:** Better allocation of investigation resources, improved visibility into control gaps, more consistent performance monitoring and the opportunity to improve fraud identification.

**Success measurement:** Establish a baseline and monitor fraud capture rate, flag precision, false positive rate, unflagged fraud count, investigation yield, review workload and processing time. Evaluate changes against a defined comparison period or controlled pilot, with thresholds agreed by business stakeholders.

## 7. Limitations & Next Steps

The `step` field is a transaction time index, not a calendar timestamp. IQR and balance checks are exploratory. The analysis does not establish causality, quantify realised losses or demonstrate a deployed predictive model.

Next steps are to complete the outstanding data quality counts, reconcile all analytical environments, validate balance expectations with business owners, assess flagged non fraud cases, test candidate controls on a time based holdout sample and establish a repeatable monitoring process.

**Conclusion:** The project identifies a substantial gap in the existing fraud flagging indicator and transaction specific patterns that can guide further investigation. It provides management with an evidence based starting point for reviewing fraud controls, while clearly distinguishing observed findings.
