-- ============================================================
-- data.sql: Load CSV data into the schema created by schema.sql
-- Run schema.sql once before running this file.
-- ============================================================
USE indian_banking_tae2;

-- Update constraints if data.sql is run against an older schema version.
ALTER TABLE data_3
    DROP CHECK chk_data3_staff,
    DROP CHECK chk_data3_npa;

ALTER TABLE data_3
    ADD CONSTRAINT chk_data3_staff CHECK (total_staff >= 0),
    ADD CONSTRAINT chk_data3_npa CHECK (provision_npa IS NOT NULL);

-- Clear prior imported data so this file can be safely rerun.
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE data_3;
TRUNCATE TABLE data_2;
TRUNCATE TABLE data_1;
TRUNCATE TABLE banking_stage;
SET FOREIGN_KEY_CHECKS = 1;

-- QUERY TYPE: SESSION - Find the server-approved import directory.
-- Copy the CSV into the directory returned by this query before continuing.
SELECT @@secure_file_priv AS mysql_import_directory;

-- QUERY TYPE: DML - Import from the secure_file_priv directory.
-- Replace the filename below only if your copied file has a different name.
-- Active server destination used here:
-- C:/ProgramData/MySQL/MySQL Server 26.7/Uploads/Indian_Banking_Data_Cleaned (3).csv
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 26.7/Uploads/Indian_Banking_Data_Cleaned (3).csv'
INTO TABLE banking_stage
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

INSERT IGNORE INTO data_1 (bank_name, sector)
SELECT s.bank, MAX(s.sector) AS sector
FROM banking_stage s
JOIN (
    SELECT bank, MAX(report_year) AS latest_year
    FROM banking_stage
    GROUP BY bank
) latest
    ON latest.bank = s.bank
    AND latest.latest_year = s.report_year
GROUP BY s.bank;
-- Allows this statement to be rerun safely after a partial import.

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

-- Confirm row counts: data_1 has 100+ banks and data_3 has 100+ records.
SELECT 'data_1' AS table_name, COUNT(*) AS row_count FROM data_1
UNION ALL
SELECT 'data_2', COUNT(*) FROM data_2
UNION ALL
SELECT 'data_3', COUNT(*) FROM data_3;
