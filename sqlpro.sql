-- Delete table if already exists
-- Used to avoid error while recreating table
DROP TABLE IF EXISTS retailsalespro;


-- Create table structure to store retail sales dataset
-- Datatypes selected based on CSV data
CREATE TABLE retailsalespro (
    id SERIAL PRIMARY KEY,      -- Unique auto-generated ID
    invoice TEXT,               -- Invoice number
    stockcode TEXT,             -- Product code
    description TEXT,           -- Product name/description
    quantity INT,               -- Number of items purchased
    invoicedate TIMESTAMP,      -- Date & time of purchase
    price NUMERIC(10,2),        -- Product price
    customer_id INT,            -- Customer unique ID
    country TEXT                -- Customer country
);


-- Check for NULL values in dataset
-- Helps in data cleaning before analysis
SELECT *
FROM retailsalespro
WHERE
invoice IS NULL OR
stockcode IS NULL OR
description IS NULL OR
quantity IS NULL OR
invoicedate IS NULL OR
price IS NULL OR
customer_id IS NULL OR
country IS NULL;


-- Delete rows where ALL columns are NULL
-- Removes completely empty records
DELETE FROM retailsalespro
WHERE
invoice IS NULL AND
stockcode IS NULL AND
description IS NULL AND
quantity IS NULL AND
invoicedate IS NULL AND
price IS NULL AND
customer_id IS NULL AND
country IS NULL;


-- Count total number of records
-- Used to understand dataset size
SELECT COUNT(*) AS total_records
FROM retailsalespro;


-- Count total unique customers
-- Helps analyze customer base
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM retailsalespro;


-- Count number of unique products sold
-- Used for product diversity analysis
SELECT COUNT(DISTINCT stockcode) AS total_products
FROM retailsalespro;


-- Display list of countries where sales occurred
-- Helps understand geographical distribution
SELECT DISTINCT country
FROM retailsalespro
ORDER BY country;


-- Count total orders per country
-- Used to identify top-performing regions
SELECT country, COUNT(*) AS total_orders
FROM retailsalespro
GROUP BY country
ORDER BY total_orders DESC;


-- Calculate total revenue generated
-- Revenue = Quantity × Price
SELECT SUM(quantity * price) AS total_revenue
FROM retailsalespro;


-- Find top 10 most sold products
-- Helps identify best-selling items
SELECT description, SUM(quantity) AS total_quantity
FROM retailsalespro
GROUP BY description
ORDER BY total_quantity DESC
LIMIT 10;


-- Find sales time range
-- Shows dataset start and end period
SELECT 
MIN(invoicedate) AS start_date,
MAX(invoicedate) AS end_date
FROM retailsalespro;


-- Total records (quick validation check)
SELECT COUNT(*) FROM retailsalespro;


-- Total revenue check again
-- Used for verification
SELECT SUM(quantity * price) FROM retailsalespro;


-- List unique countries again
-- Used for quick reference
SELECT DISTINCT country FROM retailsalespro;


-- Total unique customers again
-- Business growth indicator
SELECT COUNT(DISTINCT customer_id) FROM retailsalespro;


-- Dataset duration check
SELECT MIN(invoicedate), MAX(invoicedate)
FROM retailsalespro;