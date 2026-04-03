create database if not exists finance;
use finance;

select * from user;
select * from card;
select * from transaction;


-- SECTION 1: DEBT-TO-INCOME ANALYSIS

-- 1.1 View all customers with their income and debt
SELECT
    Client_id,
    Gender,
    Age_group,
    Yearly_income,
    Total_debt
FROM user
ORDER BY total_debt DESC;


-- 1.2 Calculate DTI ratio for each customer
SELECT
    Client_id,
    Yearly_income,
    Total_debt,
    ROUND(total_debt / NULLIF(yearly_income, 0) * 100, 2) AS dti_ratio
FROM user
ORDER BY dti_ratio DESC;


-- 1.3 Label each customer as High, Moderate or Low risk
SELECT
    Client_id,
    Yearly_income,
    Total_debt,
    ROUND(total_debt / NULLIF(yearly_income, 0) * 100, 2) AS dti_ratio,
    CASE
        WHEN total_debt / NULLIF(yearly_income, 0) * 100 >= 50 THEN 'High_Risk'
        WHEN total_debt / NULLIF(yearly_income, 0) * 100 BETWEEN 35 AND 49.99 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_label
FROM user
ORDER BY dti_ratio DESC;


-- 1.4 Count how many customers fall in each risk category
SELECT
    CASE
        WHEN total_debt / NULLIF(yearly_income, 0) * 100 >= 50 THEN 'High Risk'
        WHEN total_debt / NULLIF(yearly_income, 0) * 100 BETWEEN 35 AND 49.99 THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category,
    COUNT(*) AS total_customers
FROM user
GROUP BY risk_category
ORDER BY total_customers DESC;


-- 1.5 Average income and debt by gender
SELECT
    Gender,
    COUNT(*)                        AS total_customers,
    ROUND(AVG(yearly_income), 2)    AS avg_income,
    ROUND(AVG(total_debt), 2)       AS avg_debt,
    ROUND(AVG(total_debt / NULLIF(yearly_income, 0) * 100), 2) AS avg_dti
FROM user
GROUP BY gender
ORDER BY avg_dti DESC;


-- SECTION 2: SPENDING BEHAVIOR ANALYSIS

-- 2.1 Total and average spend per customer
SELECT
    Client_id,
    COUNT(*)                AS total_transactions,
    ROUND(SUM(amount), 2)   AS total_spent,
    ROUND(AVG(amount), 2)   AS avg_spent
FROM transaction
WHERE amount > 0
GROUP BY client_id
ORDER BY total_spent DESC;


-- 2.2 Total transactions and spend by month
SELECT
    DATE_FORMAT(date, '%Y-%m')  AS month,
    COUNT(*)                     AS total_transactions,
    ROUND(SUM(amount), 2)        AS total_spent
FROM transaction
WHERE amount > 0
GROUP BY DATE_FORMAT(date, '%Y-%m')
ORDER BY month;


-- 2.3 Top 10 customers by total spend
SELECT
    Client_id,
    COUNT(*)                AS total_transactions,
    ROUND(SUM(amount), 2)   AS total_spent
FROM transaction
WHERE amount > 0
GROUP BY client_id
ORDER BY total_spent DESC
LIMIT 10;


-- 2.4 Daily spending trend overall
SELECT
    DATE(date)              AS txn_date,
    COUNT(*)                AS total_transactions,
    ROUND(SUM(amount), 2)   AS daily_total,
    ROUND(AVG(amount), 2)   AS daily_avg
FROM transaction
WHERE amount > 0
GROUP BY DATE(date)
ORDER BY txn_date;

-- SECTION 3: CARD PORTFOLIO AND CREDIT MANAGEMENT

-- 3.1 Customers with the highest combined credit limits
SELECT u.client_id, u.gender, u.credit_score,
       SUM(c.credit_limit) AS total_credit_limit
FROM user u
JOIN card c ON u.client_id = c.client_id
GROUP BY u.client_id, u.gender, u.credit_score
ORDER BY total_credit_limit DESC
LIMIT 10;


-- 3.2 Cards that have never been used (no transactions)
SELECT c.card_id AS card_id, c.client_id, 
       c.card_brand, c.card_type, c.credit_limit
FROM card c
LEFT JOIN transaction t ON c.card_id = t.card_id
WHERE t.card_id IS NULL;


-- 3.3 Card brand with the highest total spend volume
SELECT c.card_brand,
       COUNT(t.transaction_id) AS total_transactions,
       SUM(t.amount) AS total_spend
FROM card c
JOIN transaction t ON c.card_id = t.card_id
GROUP BY c.card_brand
ORDER BY total_spend DESC;


-- 3.4 Do high credit limit cards belong to high or low credit score customers?
SELECT 
  CASE 
    WHEN u.credit_score >= 750 THEN 'High (750+)'
    WHEN u.credit_score >= 650 THEN 'Medium (650-749)'
    ELSE 'Low (<650)'
  END AS credit_score_band,
  ROUND(AVG(c.credit_limit), 2) AS avg_credit_limit,
  COUNT(c.card_id) AS num_cards
FROM user u
JOIN card c ON u.client_id = c.client_id
GROUP BY credit_score_band
ORDER BY avg_credit_limit DESC;


-- 3.5 Customers holding more than 3 cards simultaneously
SELECT u.client_id, u.gender, u.age_group,
       u.credit_score, COUNT(c.card_id) AS num_cards
FROM user u
JOIN card c ON u.client_id = c.client_id
GROUP BY u.client_id, u.gender, u.age_group, u.credit_score
HAVING COUNT(c.card_id) > 3
ORDER BY num_cards DESC;
