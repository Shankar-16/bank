-- ============================================================
-- run_all.sql: Run all SQL demonstrations against populated tables.
-- MySQL Workbench: run schema.sql and data.sql first, then run this file.
-- ============================================================

USE indian_banking_tae2;

-- Run join.sql, correlated.sql, trigger.sql, stored.sql, and views.sql
-- separately before running the final verification below.
SELECT 'data_1' AS table_name, COUNT(*) AS row_count FROM data_1
UNION ALL
SELECT 'data_2', COUNT(*) FROM data_2
UNION ALL
SELECT 'data_3', COUNT(*) FROM data_3;
