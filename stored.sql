-- stored.sql: MySQL stored procedure with parameters
-- MySQL Workbench: run schema.sql and data.sql first.
USE indian_banking_tae2;

DROP PROCEDURE IF EXISTS sp_bank_performance_report;

DELIMITER //
CREATE PROCEDURE sp_bank_performance_report (
    IN p_sector VARCHAR(20),
    IN p_start_year SMALLINT,
    IN p_end_year SMALLINT
)
BEGIN
    IF p_start_year > p_end_year THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Start year cannot be greater than end year';
    END IF;

    SELECT d1.sector,
           d1.bank_name,
           d3.report_year,
           ROUND(d3.roa, 4) AS roa,
           ROUND(d3.provision_npa, 4) AS provision_npa,
           ROUND(d3.loan_ratio, 4) AS loan_ratio
    FROM data_1 d1
    JOIN data_3 d3 ON d3.bank_id = d1.bank_id
    WHERE d1.sector = p_sector
      AND d3.report_year BETWEEN p_start_year AND p_end_year
    ORDER BY d3.report_year, d3.roa DESC;
END//
DELIMITER ;

-- Procedure execution example
CALL sp_bank_performance_report('Private', 2015, 2020);
