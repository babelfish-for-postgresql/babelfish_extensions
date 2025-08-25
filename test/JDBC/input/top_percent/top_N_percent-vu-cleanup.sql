-- Cleanup script for TOP PERCENT test cases
-- Use the test database
USE jira_babel_1358;
GO

-- Drop dependent objects created in verify file
DROP VIEW IF EXISTS top_performers_view;
GO

DROP FUNCTION IF EXISTS get_top_sales;
GO

DROP PROCEDURE IF EXISTS get_top_percent_by_category;
GO

-- Drop test tables created in prepare file
DROP TABLE IF EXISTS test_percent_scores;
GO

DROP TABLE IF EXISTS test_percent_sales;
GO

DROP TABLE IF EXISTS test_percent_sales_large;
GO

-- Drop the test database
USE master;
GO

DROP DATABASE IF EXISTS jira_babel_1358;
GO