-- correlated.sql: MySQL correlated subquery demonstrations
-- MySQL Workbench: run schema.sql once before this file.
USE indian_banking_tae2;

-- Load the complete dataset for this standalone query file.
ALTER TABLE data_3
    DROP CHECK chk_data3_staff,
    DROP CHECK chk_data3_npa;

ALTER TABLE data_3
    ADD CONSTRAINT chk_data3_staff CHECK (total_staff >= 0),
    ADD CONSTRAINT chk_data3_npa CHECK (provision_npa IS NOT NULL);

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE data_3;
TRUNCATE TABLE data_2;
TRUNCATE TABLE data_1;
TRUNCATE TABLE banking_stage;
SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 26.7/Uploads/Indian_Banking_Data_Cleaned (3).csv'
INTO TABLE banking_stage
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

INSERT INTO data_1 (bank_name, sector)
SELECT s.bank, MAX(s.sector) AS sector
FROM banking_stage s
JOIN (
    SELECT bank, MAX(report_year) AS latest_year
    FROM banking_stage
    GROUP BY bank
) latest ON latest.bank = s.bank AND latest.latest_year = s.report_year
GROUP BY s.bank;

INSERT INTO data_2 (report_year, inflation, gdp_growth, gfce, government_expenditure, repo_rate)
SELECT report_year, MAX(inflation), MAX(gdp_grth), MAX(gfce), MAX(govt_exp), MAX(repo)
FROM banking_stage
GROUP BY report_year;

INSERT INTO data_3 (
    bank_id, report_year, nii, roa, deposit_ratio, provision_npa, total_staff, roa_risk,
    nii_operating_income, loan_ratio, equity_ratio, log_total_assets, total_assets_growth,
    roa_risk_5yr, hhi_nii, diversity_index
)
SELECT d1.bank_id, s.report_year, s.nii, s.roa, s.dep_ratio, s.prov_npa, s.total_staff, s.roa_risk,
       s.nii_opinc, s.loanratio, s.equityratio, s.log_ta, s.tagr, s.roa_risk_5yr, s.hhi_nii, s.diverse
FROM banking_stage s
JOIN data_1 d1 ON d1.bank_name = s.bank;

-- Data check: this must show data_1 = 106 and data_3 = 1367.
SELECT 'Loaded rows' AS check_name,
       (SELECT COUNT(*) FROM data_1) AS bank_rows,
       (SELECT COUNT(*) FROM data_3) AS performance_rows;

-- If performance_rows is 0, run data.sql successfully before continuing.
SELECT bank_id, report_year, roa, provision_npa
FROM data_3
ORDER BY report_year, bank_id
LIMIT 10;

SELECT CASE
           WHEN (SELECT COUNT(*) FROM data_3) = 0
               THEN 'ERROR: data_3 is empty. Execute data.sql first.'
           ELSE 'OK: correlated queries have data to process.'
       END AS data_status;

-- 1. Banks whose yearly ROA is above the average ROA for that same year
SELECT d1.bank_name, d3.report_year, d3.roa
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
WHERE d3.roa >= (
    SELECT AVG(d3_inner.roa)
    FROM data_3 d3_inner
    WHERE d3_inner.report_year = d3.report_year
)
ORDER BY d3.report_year, d3.roa DESC;

-- 2. Highest NPA bank in each sector and year
SELECT d1.sector, d1.bank_name, d3.report_year, d3.provision_npa
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
WHERE d3.provision_npa >= (
    SELECT MAX(d3_inner.provision_npa)
    FROM data_1 d1_inner
    JOIN data_3 d3_inner ON d3_inner.bank_id = d1_inner.bank_id
    WHERE d1_inner.sector = d1.sector
      AND d3_inner.report_year = d3.report_year
)
ORDER BY d3.report_year, d1.sector;

-- 3. Banks with at least one year above their own long-term average ROA
SELECT d1.bank_name, d3.report_year, d3.roa
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
WHERE d3.roa >= (
    SELECT AVG(d3_inner.roa)
    FROM data_3 d3_inner
    WHERE d3_inner.bank_id = d3.bank_id
)
ORDER BY d1.bank_name, d3.report_year;
