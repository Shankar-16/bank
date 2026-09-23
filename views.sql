-- views.sql: MySQL virtual views for reporting
-- MySQL Workbench: run schema.sql once before this file.
USE indian_banking_tae2;

-- Load the complete dataset for this standalone view file.
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

SELECT 'Loaded rows' AS check_name,
       (SELECT COUNT(*) FROM data_1) AS bank_rows,
       (SELECT COUNT(*) FROM data_3) AS performance_rows;

DROP VIEW IF EXISTS vw_data3_risk_report;
DROP VIEW IF EXISTS vw_sector_year_summary;

-- View 1: bank risk classification with macroeconomic context
CREATE VIEW vw_data3_risk_report AS
SELECT d1.bank_id,
       d1.bank_name,
       d1.sector,
       d3.report_year,
       d3.roa,
       d3.provision_npa,
       d3.roa_risk_5yr,
       d3.loan_ratio,
       d2.gdp_growth,
       CASE
           WHEN d3.roa_risk_5yr >= 3 OR d3.provision_npa >= 0.5 THEN 'HIGH'
           WHEN d3.roa_risk_5yr >= 2 OR d3.provision_npa >= 0.25 THEN 'MEDIUM'
           ELSE 'NORMAL'
       END AS risk_band
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
JOIN data_2 d2 ON d2.report_year = d3.report_year;

-- View 2: sector and year aggregate report
CREATE VIEW vw_sector_year_summary AS
SELECT d1.sector,
       d3.report_year,
       COUNT(*) AS bank_count,
       ROUND(AVG(d3.roa), 4) AS average_roa,
       ROUND(AVG(d3.loan_ratio), 4) AS average_loan_ratio,
       ROUND(MAX(d3.provision_npa), 4) AS maximum_npa,
       ROUND(AVG(d2.gdp_growth), 4) AS gdp_growth
FROM data_1 d1
JOIN data_3 d3 ON d3.bank_id = d1.bank_id
JOIN data_2 d2 ON d2.report_year = d3.report_year
GROUP BY d1.sector, d3.report_year;

-- View queries
SELECT * FROM vw_data3_risk_report
ORDER BY provision_npa DESC
LIMIT 20;

SELECT * FROM vw_sector_year_summary
WHERE average_roa >= 0
ORDER BY report_year, sector;

SELECT 'View rows' AS check_name,
       (SELECT COUNT(*) FROM vw_data3_risk_report) AS risk_report_rows,
       (SELECT COUNT(*) FROM vw_sector_year_summary) AS summary_rows;
