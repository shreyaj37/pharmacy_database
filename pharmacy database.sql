create database EMR;
USE EMR;

CREATE TABLE dim_members (
    member_id INT PRIMARY KEY,
    member_first_name VARCHAR(100),
    member_last_name VARCHAR(100),
    member_birth_date DATE,
    member_age INT,
    member_gender CHAR(1)
);

CREATE TABLE dim_drugs (
    drug_ndc INT PRIMARY KEY,
    drug_name VARCHAR(100),
    drug_form_code VARCHAR(2),
    drug_form_desc VARCHAR(50),
    drug_brand_generic_code INT,
    drug_brand_generic_desc VARCHAR(100)
);

CREATE TABLE fact_prescriptions (
    member_id INT,
    drug_ndc INT,
    fill_date DATE,
    copay DECIMAL(10, 2),
    insurance_paid DECIMAL(10, 2),
    FOREIGN KEY (member_id) REFERENCES dim_members(member_id),
    FOREIGN KEY (drug_ndc) REFERENCES dim_drugs(drug_ndc)
);


-- Load data into dim_members table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Data/EMR/dim_members.csv' 
INTO TABLE dim_members 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(member_id, member_first_name, member_last_name, @member_birth_date, member_age, member_gender) 
SET member_birth_date = STR_TO_DATE(@member_birth_date, '%m/%d/%Y');


-- Load data into dim_drugs table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Data/EMR/dim_drugs.csv' 
INTO TABLE dim_drugs 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(drug_ndc, drug_name, drug_form_code, drug_form_desc, drug_brand_generic_code, drug_brand_generic_desc);


-- Load data into fact_prescriptions table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Data/EMR/fact_prescriptions.csv' 
INTO TABLE fact_prescriptions 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(member_id, drug_ndc, @fill_date, copay, insurance_paid) 
SET fill_date = STR_TO_DATE(@fill_date, '%m/%d/%Y');

select * from dim_drugs;

-- Number of prescriptions grouped by drug name:
SELECT drug_name, COUNT(*) AS num_prescriptions
FROM dim_drugs d
JOIN fact_prescriptions f ON d.drug_ndc = f.drug_ndc
GROUP BY drug_name;

-- Total prescriptions, unique members, and total copay by age group:
SELECT
    CASE WHEN m.member_age >= 65 THEN 'age 65+' ELSE '< 65' END AS age_group,
    COUNT(*) AS total_prescriptions,
    COUNT(DISTINCT f.member_id) AS unique_members,
    SUM(f.copay) AS total_copay
FROM
    fact_prescriptions f
JOIN
    dim_members m ON f.member_id = m.member_id
GROUP BY
    age_group
LIMIT
    0, 1000;
    
-- Amount paid by insurance for the most recent prescription fill date:
SELECT 
    f.member_id,
    m.member_first_name,
    m.member_last_name,
    d.drug_name,
    f.fill_date,
    f.insurance_paid
FROM fact_prescriptions f
JOIN dim_members m ON f.member_id = m.member_id
JOIN dim_drugs d ON f.drug_ndc = d.drug_ndc
WHERE (f.member_id, f.fill_date) IN (
    SELECT member_id, MAX(fill_date)
    FROM fact_prescriptions
    GROUP BY member_id
);

-- For member ID 10003, what was the drug name listed on their most recent fill date?
-- How much did their insurance pay for that medication?


SELECT
    d.drug_name,
    f.insurance_paid
FROM
    fact_prescriptions f
JOIN
    dim_drugs d ON f.drug_ndc = d.drug_ndc
WHERE
    f.member_id = 10003
ORDER BY
    f.fill_date DESC
LIMIT
    1;
