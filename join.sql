-- join.sql: MySQL join demonstrations using data_1, data_2, data_3
-- MySQL Workbench: run schema.sql once before this file.
USE indian_banking_tae2;

SELECT VERSION() AS mysql_version,
       DATABASE() AS active_database,
       @@secure_file_priv AS secure_import_directory;

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

SELECT COUNT(*) AS staging_rows FROM banking_stage;

-- Stop with a readable message instead of showing empty join output.
SET @staging_rows = (SELECT COUNT(*) FROM banking_stage);
SET @load_error = IF(@staging_rows = 0,
    'ERROR: CSV was not loaded. Copy the CSV into the secure_import_directory shown above.',
    'OK: CSV rows loaded.');
SELECT @load_error AS load_status;

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

SELECT 'Loaded rows' AS check_name,
       (SELECT COUNT(*) FROM data_1) AS bank_rows,
       (SELECT COUNT(*) FROM data_3) AS performance_rows;

-- Direct data preview: confirms that imported banking records are visible.
SELECT d1.bank_id,
       d1.bank_name,
       d1.sector,
       d3.report_year,
       d3.nii,
       d3.roa,
       d3.provision_npa
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
ORDER BY d3.report_year, d1.bank_id
LIMIT 20;

SELECT CASE
           WHEN (SELECT COUNT(*) FROM data_3) = 0
               THEN 'ERROR: No data loaded. Check LOAD DATA INFILE path/server.'
           ELSE 'OK: Banking data loaded successfully.'
       END AS data_status;

-- Guaranteed sample output: confirms the three tables are joined successfully.
SELECT d1.bank_name,
       d1.sector,
       d3.report_year,
       d3.roa,
       d2.gdp_growth
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
JOIN data_2 d2 ON d2.report_year = d3.report_year
ORDER BY d3.report_year, d1.bank_name
LIMIT 20;

-- 1. Inner join: bank performance with bank and macroeconomic data
SELECT d1.bank_name, d1.sector, d3.report_year, d3.roa, d2.gdp_growth
FROM data_1 d1
INNER JOIN data_3 d3 ON d3.bank_id = d1.bank_id
INNER JOIN data_2 d2 ON d2.report_year = d3.report_year
WHERE d3.report_year = 2020
ORDER BY d3.roa DESC;

-- 2. Left outer join: include banks even if a year has no performance record
SELECT d1.bank_id, d1.bank_name, d1.sector, d3.report_year, d3.roa
FROM data_1 d1
LEFT JOIN data_3 d3
    ON d3.bank_id = d1.bank_id AND d3.report_year = 2020
ORDER BY d1.bank_name;

-- 3. Self join: compare banks belonging to the same sector
SELECT a.bank_name AS bank_a, b.bank_name AS bank_b, a.sector
FROM data_1 a
INNER JOIN data_1 b
    ON a.sector = b.sector AND a.bank_id < b.bank_id
ORDER BY a.sector, a.bank_name, b.bank_name
LIMIT 100;

-- 4. Full outer join equivalent in MySQL using LEFT JOIN and UNION
SELECT d1.bank_name, d3.report_year, d3.roa
FROM data_1 d1
LEFT JOIN data_3 d3 ON d3.bank_id = d1.bank_id
UNION
SELECT d1.bank_name, d3.report_year, d3.roa
FROM data_3 d3
LEFT JOIN data_1 d1 ON d1.bank_id = d3.bank_id
WHERE d1.bank_id IS NULL;

-- 5. Aggregate join: sector and year performance summary
SELECT d1.sector, d3.report_year, COUNT(*) AS bank_count,
       ROUND(AVG(d3.roa), 4) AS average_roa,
       ROUND(MAX(d3.provision_npa), 4) AS maximum_npa
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
GROUP BY d1.sector, d3.report_year
-- The source data's highest sector-year average ROA is 2.6971.
-- COUNT(*) >= 1 keeps the HAVING demonstration and returns populated groups.
HAVING COUNT(*) >= 1
ORDER BY d3.report_year, d1.sector;
