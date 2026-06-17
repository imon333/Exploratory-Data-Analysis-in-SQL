-- ============================================================
-- Exploratory Data Analysis in SQL
-- Chapter 1: What's in the Database?
-- DataCamp Course | Author: Imon | June 2026
-- ============================================================
-- HOW TO USE:
-- Run these queries against a PostgreSQL database that has:
-- fortune500, company, tag_company, tag_type tables
-- Dummy data is provided at the bottom of this file
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- EXERCISE 1: Explore Table Sizes
-- Goal: Count how many rows are in the fortune500 table
-- ────────────────────────────────────────────────────────────

-- Count total rows in fortune500
SELECT COUNT(*) AS total_rows
  FROM fortune500;

-- Output:
-- total_rows
-- ----------
-- 500


-- ────────────────────────────────────────────────────────────
-- EXERCISE 2: Count Missing Values
-- Goal: Find how many NULL values exist in each column
-- Formula: COUNT(*) - COUNT(column) = missing values
-- Reason: COUNT(*) counts all rows, COUNT(col) skips NULLs
-- ────────────────────────────────────────────────────────────

-- Count missing values in ticker column
SELECT COUNT(*) - COUNT(ticker) AS missing_ticker
  FROM fortune500;

-- Count missing values in industry column
SELECT COUNT(*) - COUNT(industry) AS missing_industry
  FROM fortune500;

-- Count missing values for multiple columns at once
SELECT COUNT(*) - COUNT(ticker)   AS missing_ticker,
       COUNT(*) - COUNT(industry) AS missing_industry,
       COUNT(*) - COUNT(sector)   AS missing_sector
  FROM fortune500;

-- Output (example):
-- missing_ticker | missing_industry | missing_sector
-- ---------------+------------------+---------------
--      32        |       139        |       0


-- ────────────────────────────────────────────────────────────
-- EXERCISE 3: Join Tables
-- Goal: Join company and fortune500 tables using ticker column
-- Both tables share the ticker column with compatible values
-- ────────────────────────────────────────────────────────────

-- INNER JOIN: only companies that appear in BOTH tables
SELECT company.name
  FROM company
       INNER JOIN fortune500
       ON company.ticker = fortune500.ticker;

-- LEFT JOIN: all companies, revenue NULL if not in fortune500
SELECT company.name,
       fortune500.revenues
  FROM company
       LEFT JOIN fortune500
       ON company.ticker = fortune500.ticker;

-- Output (INNER JOIN example):
-- name
-- -------
-- Apple
-- Walmart
-- Exxon Mobil
-- ...


-- ────────────────────────────────────────────────────────────
-- EXERCISE 4: Read an Entity Relationship Diagram
-- Goal: Join 3 tables to find companies with cloud tags
-- Tables: company → tag_company → tag_type
-- ────────────────────────────────────────────────────────────

-- Step 1: Find the most common tag type
SELECT type, COUNT(*) AS count
  FROM tag_type
 GROUP BY type
 ORDER BY count DESC;

-- Output:
-- type  | count
-- ------+------
-- cloud |  152  <- most common!
-- ...

-- Step 2: Find companies with cloud tags (3-table join)
SELECT company.name,
       tag_type.tag,
       tag_type.type
  FROM company
       INNER JOIN tag_company
       ON company.id = tag_company.company_id
       INNER JOIN tag_type
       ON tag_company.tag = tag_type.tag
 WHERE tag_type.type = 'cloud';

-- Output:
-- name   | tag                   | type
-- -------+-----------------------+------
-- Amazon | amazon-cloudformation | cloud
-- Amazon | amazon-cloudfront     | cloud
-- ...


-- ────────────────────────────────────────────────────────────
-- EXERCISE 5: COALESCE Function
-- Goal: Fill NULL industry values with sector, then 'Unknown'
-- COALESCE returns the first non-NULL value in order
-- ────────────────────────────────────────────────────────────

-- Use COALESCE to fill missing industry with sector or Unknown
SELECT COALESCE(industry, sector, 'Unknown') AS industry2,
       COUNT(*) AS count
  FROM fortune500
 GROUP BY industry2
 ORDER BY count DESC
 LIMIT 1;

-- How COALESCE works:
-- COALESCE(industry, sector, 'Unknown')
-- → if industry is NOT NULL → use industry
-- → if industry IS NULL → check sector
-- → if sector is also NULL → use 'Unknown'

-- Output:
-- industry2  | count
-- -----------+------
-- Technology |  52   <- most common industry


-- ────────────────────────────────────────────────────────────
-- EXERCISE 6: Effects of Casting
-- Goal: Convert data between types using CAST() or ::
-- Two syntax options work identically in PostgreSQL
-- ────────────────────────────────────────────────────────────

-- Cast profits_change to integer (removes decimal part)
SELECT profits_change,
       CAST(profits_change AS integer) AS profits_change_int
  FROM fortune500;

-- Output:
-- profits_change | profits_change_int
-- ---------------+------------------
--    10.7        |    10             <- decimal lost!
--    -3.2        |    -3             <- decimal lost!
--     5.9        |     5             <- decimal lost!

-- Integer division vs Numeric division
SELECT 10/3            AS integer_division,
       10::numeric/3   AS numeric_division;

-- Output:
-- integer_division | numeric_division
-- -----------------+-----------------
--        3         | 3.3333333333333  <- decimal kept!

-- Cast text strings to numeric
SELECT '3.2'::numeric,
       '-123'::numeric,
       '1e3'::numeric,
       '1e-3'::numeric,
       '02314'::numeric,
       '0002'::numeric;

-- Output:
-- 3.2 | -123 | 1000 | 0.001 | 2314 | 2
-- Note: 1e3 = scientific notation = 1 x 10^3 = 1000


-- ────────────────────────────────────────────────────────────
-- EXERCISE 7: Summarize Distribution of Numeric Values
-- Goal: See how revenue changed across all fortune500 companies
-- SQL execution order: FROM → WHERE → GROUP BY → SELECT → ORDER BY → LIMIT
-- ────────────────────────────────────────────────────────────

-- Distribution of revenues_change (cast to integer for grouping)
SELECT revenues_change::integer AS change_bucket,
       COUNT(*) AS count
  FROM fortune500
 GROUP BY revenues_change::integer
 ORDER BY revenues_change::integer;

-- Why cast in BOTH SELECT and GROUP BY?
-- GROUP BY runs BEFORE SELECT
-- GROUP BY needs ::integer to group similar decimals together
-- (e.g. 0.8 and 0.9 both become 0 → same group → count = 2)
-- SELECT needs ::integer to show clean integer in result

-- Output (example):
-- change_bucket | count
-- --------------+------
--    -16        |   5
--     -7        |  12
--      0        |  18
--      6        |  23
--     10        |  31

-- Count companies where revenue INCREASED in 2017
SELECT COUNT(*) AS companies_increased
  FROM fortune500
 WHERE revenues_change > 0;

-- Output:
-- companies_increased
-- -------------------
--        298


-- ============================================================
-- DUMMY DATA FOR PRACTICE
-- Run this first to create and populate test tables
-- ============================================================

-- Create fortune500 dummy table
CREATE TABLE IF NOT EXISTS fortune500 (
    rank        INTEGER,
    company     TEXT,
    ticker      TEXT,
    sector      TEXT,
    industry    TEXT,
    revenues    NUMERIC,
    revenues_change NUMERIC,
    profits     NUMERIC,
    profits_change  NUMERIC
);

INSERT INTO fortune500 VALUES
(1,  'Walmart',            'WMT',  'Retailing',  'General Merchandisers', 485873,   0.8,  13643,  -7.2),
(2,  'Berkshire Hathaway', 'BRKA', 'Financials',  'Insurance',            223604,   6.1,  24074,   0.0),
(3,  'Apple',              'AAPL', 'Technology',  'Computers',            215639,  -7.7,  45687, -14.4),
(4,  'Exxon Mobil',        'XOM',  'Energy',      'Petroleum Refining',   205004, -16.7,   7840, -51.5),
(5,  'McKesson',           'MCK',  'Health Care', NULL,                   198015,   3.4,   4045,  -3.2),
(6,  'UnitedHealth',       'UNH',  'Health Care', 'Health Care',          184840,  19.7,   7017,  35.5),
(7,  'CVS Health',         'CVS',  'Health Care', 'Health Care',          177526,  15.8,   5317,  18.2),
(8,  'General Motors',     'GM',   'Motor Vehicles', 'Motor Vehicles',    166380,   9.0,   9427,  -6.3),
(9,  'AT&T',               NULL,   'Telecommunications', NULL,            163786,  11.6,  13333,  -1.5),
(10, 'Ford Motor',         'F',    'Motor Vehicles', 'Motor Vehicles',    151800,   -1.0,  4596, -38.9);

-- Create company dummy table
CREATE TABLE IF NOT EXISTS company (
    id        INTEGER PRIMARY KEY,
    exchange  TEXT,
    ticker    TEXT,
    name      TEXT,
    parent_id INTEGER
);

INSERT INTO company VALUES
(1, 'nyse',   'WMT',  'Walmart Inc.',              NULL),
(2, 'nasdaq', 'AAPL', 'Apple Inc.',                NULL),
(3, 'nyse',   'XOM',  'Exxon Mobil Corporation',   NULL),
(4, 'nasdaq', 'PYPL', 'PayPal Holdings Inc.',      NULL),
(5, 'nasdaq', 'GOOGL','Alphabet Inc.',              NULL);

-- Create tag_type dummy table
CREATE TABLE IF NOT EXISTS tag_type (
    id  INTEGER PRIMARY KEY,
    tag TEXT,
    type TEXT
);

INSERT INTO tag_type VALUES
(1, 'amazon-cloudformation', 'cloud'),
(2, 'amazon-cloudfront',     'cloud'),
(3, 'amazon-ec2',            'cloud'),
(4, 'paypal',                'payments'),
(5, 'google-maps',           'location');

-- Create tag_company dummy table
CREATE TABLE IF NOT EXISTS tag_company (
    company_id INTEGER,
    tag        TEXT
);

INSERT INTO tag_company VALUES
(4, 'paypal'),
(5, 'google-maps'),
(3, 'amazon-cloudformation'),
(3, 'amazon-cloudfront'),
(3, 'amazon-ec2');

-- ============================================================
-- END OF FILE
-- ============================================================
