

DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS retailsalespro CASCADE;


/* ============================================================
   STEP 2 — CREATE RAW STAGING TABLE
   ============================================================ */

CREATE TABLE retailsalespro (
    id SERIAL PRIMARY KEY,
    invoice TEXT,
    stockcode TEXT,
    description TEXT,
    quantity INT,
    invoicedate TIMESTAMP,
    price NUMERIC(10,2),
    customer_id INT,
    country TEXT
);

/* ============================================================
   STEP 3 — DATA CLEANING
   ============================================================ */

-- Remove rows with NULL customer (anonymous purchases)
DELETE FROM retailsalespro
WHERE customer_id IS NULL;

-- Remove cancelled transactions (Invoices starting with 'C')
DELETE FROM retailsalespro
WHERE invoice LIKE 'C%';

-- Remove invalid quantity or price
DELETE FROM retailsalespro
WHERE quantity <= 0 OR price <= 0;

-- Validate clean dataset count
SELECT COUNT(*) AS clean_row_count
FROM retailsalespro;


/* ============================================================
   STEP 4 — ADD REVENUE COLUMN
   ============================================================ */

ALTER TABLE retailsalespro
ADD COLUMN revenue NUMERIC(12,2);

UPDATE retailsalespro
SET revenue = quantity * price;




/* ============================================================
   STEP 5 — CREATE DIMENSION TABLES
   ============================================================ */

-- 5.1 Customer Dimension
DROP TABLE dim_customer;

CREATE TABLE dim_customer AS
SELECT
    customer_id,
    MIN(country) AS country
FROM retailsalespro
GROUP BY customer_id;

ALTER TABLE dim_customer
ADD PRIMARY KEY (customer_id);




-- 5.2 Product Dimension
DROP TABLE dim_product;

CREATE TABLE dim_product AS
SELECT
    stockcode,
    MIN(description) AS description
FROM retailsalespro
GROUP BY stockcode;

ALTER TABLE dim_product
ADD PRIMARY KEY (stockcode);

-- 5.3 Date Dimension
CREATE TABLE dim_date AS
SELECT DISTINCT
    invoicedate::DATE AS date,
    EXTRACT(YEAR FROM invoicedate) AS year,
    EXTRACT(MONTH FROM invoicedate) AS month,
    EXTRACT(QUARTER FROM invoicedate) AS quarter
FROM retailsalespro;

ALTER TABLE dim_date
ADD PRIMARY KEY (date);


/* ============================================================
   STEP 6 — CREATE FACT TABLE
   ============================================================ */

CREATE TABLE fact_sales AS
SELECT
    invoice,
    customer_id,
    stockcode,
    invoicedate::DATE AS date,
    quantity,
    price,
    revenue
FROM retailsalespro;


/* ============================================================
   STEP 7 — ADD FOREIGN KEY CONSTRAINTS
   ============================================================ */

ALTER TABLE fact_sales
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES dim_customer(customer_id);

ALTER TABLE fact_sales
ADD CONSTRAINT fk_product
FOREIGN KEY (stockcode)
REFERENCES dim_product(stockcode);

ALTER TABLE fact_sales
ADD CONSTRAINT fk_date
FOREIGN KEY (date)
REFERENCES dim_date(date);


/* ============================================================
   STEP 8 — ADD PERFORMANCE INDEXES
   (Critical for <2 second query requirement)
   ============================================================ */

CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_product ON fact_sales(stockcode);
CREATE INDEX idx_fact_date ON fact_sales(date);
CREATE INDEX idx_fact_invoice ON fact_sales(invoice);


/* ============================================================
   STEP 9 — PERFORMANCE VALIDATION CHECK
   ============================================================ */

EXPLAIN ANALYZE
SELECT customer_id, SUM(revenue) AS total_revenue
FROM fact_sales
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;


/* If execution is slow, run: */
-- VACUUM ANALYZE fact_sales;


/* ============================================================
   STEP 10 — CORE BUSINESS VALIDATION QUERIES
   ============================================================ */

-- Total Revenue
SELECT SUM(revenue) AS total_revenue
FROM fact_sales;

-- Total Customers
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM fact_sales;

-- Monthly Revenue
SELECT d.year, d.month, SUM(f.revenue) AS monthly_revenue
FROM fact_sales f
JOIN dim_date d ON f.date = d.date
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Top 10 Products by Quantity
SELECT p.description, SUM(f.quantity) AS total_quantity
FROM fact_sales f
JOIN dim_product p ON f.stockcode = p.stockcode
GROUP BY p.description
ORDER BY total_quantity DESC
LIMIT 10;

-- Revenue by Country
SELECT c.country, SUM(f.revenue) AS country_revenue
FROM fact_sales f
JOIN dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.country
ORDER BY country_revenue DESC;