---------------------------------------------------------
-- STEP 1: CREATE DATA LAKE SCHEMAS
-- RAW     → Stores original data
-- STAGING → Cleaned data
-- PROCESSED → Analytics-ready data
---------------------------------------------------------

CREATE SCHEMA raw;
CREATE SCHEMA staging;
CREATE SCHEMA processed;


---------------------------------------------------------
-- STEP 2: DROP EXISTING TABLES (RESET ENVIRONMENT)
---------------------------------------------------------

DROP TABLE IF EXISTS raw.diabetic_data CASCADE;
DROP TABLE IF EXISTS staging.diabetic_clean CASCADE;
DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS processed.readmission_summary CASCADE;
DROP TABLE IF EXISTS processed.age_stay_analysis CASCADE;
DROP TABLE IF EXISTS processed.insulin_usage CASCADE;






---------------------------------------------------------
-- STEP 3: CREATE RAW TABLE
-- Stores data exactly as received from CSV
-- No transformation or cleaning
---------------------------------------------------------

CREATE TABLE raw.diabetic_data (
encounter_id BIGINT,
patient_nbr BIGINT,
race TEXT,
gender TEXT,
age TEXT,
weight TEXT,
admission_type_id INT,
discharge_disposition_id INT,
admission_source_id INT,
time_in_hospital INT,
payer_code TEXT,
medical_specialty TEXT,
num_lab_procedures INT,
num_procedures INT,
num_medications INT,
number_outpatient INT,
number_emergency INT,
number_inpatient INT,
diag_1 TEXT,
diag_2 TEXT,
diag_3 TEXT,
number_diagnoses INT,
max_glu_serum TEXT,
A1Cresult TEXT,
metformin TEXT,
repaglinide TEXT,
nateglinide TEXT,
chlorpropamide TEXT,
glimepiride TEXT,
acetohexamide TEXT,
glipizide TEXT,
glyburide TEXT,
tolbutamide TEXT,
pioglitazone TEXT,
rosiglitazone TEXT,
acarbose TEXT,
miglitol TEXT,
troglitazone TEXT,
tolazamide TEXT,
examide TEXT,
citoglipton TEXT,
insulin TEXT,
"glyburide-metformin" TEXT,
"glipizide-metformin" TEXT,
"glimepiride-pioglitazone" TEXT,
"metformin-rosiglitazone" TEXT,
"metformin-pioglitazone" TEXT,
change TEXT,
diabetesMed TEXT,
readmitted TEXT
);


---------------------------------------------------------
-- STEP 4: CREATE STAGING TABLE
-- Data Cleaning Layer
-- Convert '?' values into NULL
---------------------------------------------------------

CREATE TABLE staging.diabetic_clean AS
SELECT
    encounter_id,
    patient_nbr,
    NULLIF(race,'?') AS race,
    gender,
    age,
    NULLIF(weight,'?') AS weight,
    admission_type_id,
    time_in_hospital,
    num_lab_procedures,
    num_medications,
    number_diagnoses,
    NULLIF(A1Cresult,'?') AS A1Cresult,
    insulin,
    diabetesMed,
    readmitted
FROM raw.diabetic_data;


---------------------------------------------------------
-- STEP 5: REMOVE RECORDS WITH NULL RACE
---------------------------------------------------------

DELETE FROM staging.diabetic_clean
WHERE race IS NULL;


---------------------------------------------------------
-- STEP 6: DATA VALIDATION CHECK
-- Confirm NULL values removed
---------------------------------------------------------

SELECT COUNT(*)
FROM staging.diabetic_clean
WHERE race IS NULL;


---------------------------------------------------------
-- STEP 7: CHECK DUPLICATE ENCOUNTERS
---------------------------------------------------------

SELECT encounter_id, COUNT(*)
FROM staging.diabetic_clean
GROUP BY encounter_id
HAVING COUNT(*) > 1;


---------------------------------------------------------
-- STEP 8: REMOVE DUPLICATE RECORDS
---------------------------------------------------------

DELETE FROM staging.diabetic_clean a
USING staging.diabetic_clean b
WHERE a.ctid < b.ctid
AND a.encounter_id = b.encounter_id;


---------------------------------------------------------
-- STEP 9: PROCESSED LAYER
-- BUSINESS ANALYTICS TABLES
---------------------------------------------------------

-- Patient Readmission Summary
CREATE TABLE processed.readmission_summary AS
SELECT
    readmitted,
    COUNT(*) AS patient_count
FROM staging.diabetic_clean
GROUP BY readmitted;


-- Average Hospital Stay by Age Group
CREATE TABLE processed.age_stay_analysis AS
SELECT
    age,
    AVG(time_in_hospital) AS avg_hospital_days
FROM staging.diabetic_clean
GROUP BY age
ORDER BY age;


-- Insulin Usage Analysis
CREATE TABLE processed.insulin_usage AS
SELECT
    insulin,
    COUNT(*) AS total_patients
FROM staging.diabetic_clean
GROUP BY insulin;


---------------------------------------------------------
-- STEP 10: ANALYTICS VIEW FOR DASHBOARD
---------------------------------------------------------

CREATE VIEW processed.patient_dashboard AS
SELECT
    age,
    race,
    time_in_hospital,
    insulin,
    readmitted
FROM staging.diabetic_clean;


---------------------------------------------------------
-- STEP 11: DATA SECURITY IMPLEMENTATION
-- Restrict RAW data access
-- Allow analytics access only
---------------------------------------------------------

REVOKE ALL ON SCHEMA raw FROM PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA processed TO PUBLIC;