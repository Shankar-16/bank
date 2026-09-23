-- trigger.sql: MySQL trigger and audit table
-- MySQL Workbench: run schema.sql and data.sql first.
USE indian_banking_tae2;

DROP TRIGGER IF EXISTS trg_data3_audit;
DROP TABLE IF EXISTS data3_audit;

CREATE TABLE data3_audit (
    audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bank_id INT UNSIGNED NOT NULL,
    report_year SMALLINT UNSIGNED NOT NULL,
    old_roa DECIMAL(12,4) NULL,
    new_roa DECIMAL(12,4) NULL,
    action_name ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_data3_bank FOREIGN KEY (bank_id) REFERENCES data_1 (bank_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER trg_data3_audit
AFTER UPDATE ON data_3
FOR EACH ROW
BEGIN
    IF OLD.roa <> NEW.roa THEN
        INSERT INTO data3_audit (bank_id, report_year, old_roa, new_roa, action_name)
        VALUES (NEW.bank_id, NEW.report_year, OLD.roa, NEW.roa, 'UPDATE');
    END IF;
END//
DELIMITER ;

-- Test the trigger. The transaction can be rolled back after inspection.
START TRANSACTION;
UPDATE data_3
SET roa = roa + 0.0100
WHERE bank_id = 1 AND report_year = 2020;
SELECT * FROM data3_audit ORDER BY audit_id DESC LIMIT 1;
ROLLBACK;
