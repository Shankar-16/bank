-- ============================================================
-- schema.sql: MySQL schema for the Indian banking dataset
-- ============================================================

CREATE DATABASE IF NOT EXISTS indian_banking_tae2
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE indian_banking_tae2;

-- Remove only the objects owned by this three-table dataset.
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS data_3;
DROP TABLE IF EXISTS data_2;
DROP TABLE IF EXISTS data_1;
DROP TABLE IF EXISTS banking_stage;
SET FOREIGN_KEY_CHECKS = 1;

-- data_1: bank master data, one row per bank
CREATE TABLE data_1 (
    bank_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bank_name VARCHAR(150) NOT NULL UNIQUE,
    sector VARCHAR(20) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_data1_sector
        CHECK (sector IN ('Foreign', 'Private', 'Public'))
) ENGINE = InnoDB;

-- data_2: macroeconomic data, one row per reporting year
CREATE TABLE data_2 (
    report_year SMALLINT UNSIGNED PRIMARY KEY,
    inflation DECIMAL(12,4) NOT NULL,
    gdp_growth DECIMAL(12,4) NOT NULL,
    gfce DECIMAL(12,4) NOT NULL,
    government_expenditure DECIMAL(12,4) NOT NULL,
    repo_rate DECIMAL(12,4) NOT NULL,
    CONSTRAINT chk_data2_year
        CHECK (report_year BETWEEN 1900 AND 2100),
    CONSTRAINT chk_data2_repo
        CHECK (repo_rate >= 0)
) ENGINE = InnoDB;

-- data_3: bank performance data, one row per bank and year
CREATE TABLE data_3 (
    bank_id INT UNSIGNED NOT NULL,
    report_year SMALLINT UNSIGNED NOT NULL,
    nii DECIMAL(12,4) NOT NULL,
    roa DECIMAL(12,4) NOT NULL,
    deposit_ratio DECIMAL(12,4) NOT NULL,
    provision_npa DECIMAL(12,4) NOT NULL,
    total_staff INT UNSIGNED NOT NULL,
    roa_risk DECIMAL(12,4) NOT NULL,
    nii_operating_income DECIMAL(12,4) NOT NULL,
    loan_ratio DECIMAL(12,4) NOT NULL,
    equity_ratio DECIMAL(12,4) NOT NULL,
    log_total_assets DECIMAL(12,4) NOT NULL,
    total_assets_growth DECIMAL(12,4) NOT NULL,
    roa_risk_5yr DECIMAL(12,4) NOT NULL,
    hhi_nii DECIMAL(12,4) NOT NULL,
    diversity_index DECIMAL(14,4) NOT NULL,
    PRIMARY KEY (bank_id, report_year),
    CONSTRAINT fk_data3_bank
        FOREIGN KEY (bank_id) REFERENCES data_1 (bank_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_data3_year
        FOREIGN KEY (report_year) REFERENCES data_2 (report_year)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_data3_staff
        CHECK (total_staff >= 0),
    CONSTRAINT chk_data3_ratios
        CHECK (
            deposit_ratio BETWEEN 0 AND 100
            AND loan_ratio BETWEEN 0 AND 100
            AND equity_ratio BETWEEN 0 AND 100
        ),
    CONSTRAINT chk_data3_npa
        CHECK (provision_npa IS NOT NULL)
) ENGINE = InnoDB;

-- Raw CSV staging table used by data.sql before normalization.
CREATE TABLE banking_stage (
    sector VARCHAR(20) NOT NULL,
    bank VARCHAR(150) NOT NULL,
    report_year SMALLINT NOT NULL,
    nii DECIMAL(12,4),
    roa DECIMAL(12,4),
    dep_ratio DECIMAL(12,4),
    prov_npa DECIMAL(12,4),
    total_staff INT,
    inflation DECIMAL(12,4),
    roa_risk DECIMAL(12,4),
    nii_opinc DECIMAL(12,4),
    loanratio DECIMAL(12,4),
    equityratio DECIMAL(12,4),
    log_ta DECIMAL(12,4),
    tagr DECIMAL(12,4),
    gdp_grth DECIMAL(12,4),
    gfce DECIMAL(12,4),
    roa_risk_5yr DECIMAL(12,4),
    govt_exp DECIMAL(12,4),
    repo DECIMAL(12,4),
    hhi_nii DECIMAL(12,4),
    diverse DECIMAL(14,4)
) ENGINE = InnoDB;

-- Optional indexes for the most common joins and filters.
CREATE INDEX idx_data1_sector ON data_1 (sector);
CREATE INDEX idx_data3_year_roa ON data_3 (report_year, roa);
CREATE INDEX idx_data3_npa ON data_3 (provision_npa);

-- Schema verification
SHOW TABLES;
DESCRIBE data_1;
DESCRIBE data_2;
DESCRIBE data_3;
