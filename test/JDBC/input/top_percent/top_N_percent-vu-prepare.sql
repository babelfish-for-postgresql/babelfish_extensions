/*
 * TOP PERCENT Test Cases Summary
 * JIRA-BABEL-1358
 *
 * |  #  |                    Test Case                     |        Type         |                    Remark                     |
 * |-----|--------------------------------------------------|---------------------|-----------------------------------------------|
 * |  1  | Basic TOP PERCENT                                | Basic               | Tests 50%, 0%                                 |
 * |  2  | TOP PERCENT with ties                            | Error Case          | WITH TIES not supported - should throw error  |
 * |  3  | TOP PERCENT with WHERE                           | Filtering           | Tests 25% and 20.4% with WHERE clause         |
 * |  4  | TOP PERCENT with NULL values                     | NULL Handling       | Tests 40% with NULL data                      |
 * |  5  | TOP PERCENT with money data type                 | Data Types          | Tests 50% with money/revenue data             |
 * |  6  | TOP PERCENT in subquery                          | Subquery            | Tests 50% in nested SELECT                    |
 * |  7  | TOP PERCENT with GROUP BY                        | Aggregation         | Tests 50% with GROUP BY clause                |
 * | 7a  | TOP PERCENT with GROUP BY and HAVING             | Aggregation+Filter  | Tests 50% with GROUP BY and HAVING clause     |
 * |  8  | TOP PERCENT with decimal percentage              | Precision           | Tests 33.33% decimal precision                |
 * |  9  | TOP PERCENT with DISTINCT                        | Distinct Values     | Tests 50% with DISTINCT                       |
 * | 10  | TOP PERCENT with JOIN                            | Joins               | Tests 50% with LEFT JOIN                      |
 * | 11  | TOP 100 PERCENT                                  | Edge Case           | Should return all rows                        |
 * | 12  | TOP 1 PERCENT                                    | Minimum Case        | Tests minimum percentage                      |
 * | 13  | TOP 0 PERCENT                                    | Extreme Edge        | Tests zero percentage                         |
 * | 14  | TOP 0.5 PERCENT                                  | Extreme Decimal     | Tests very small decimal percentage           |
 * | 15  | TOP PERCENT with PIVOT                           | Advanced            | Tests 50% with PIVOT operation                |
 * | 16  | TOP PERCENT with UNPIVOT                         | Advanced            | Tests nested 50% and 30% with UNPIVOT         |
 * | 17  | TOP PERCENT with Window Functions                | Window Functions    | Tests 50% with ROW_NUMBER() and AVG() OVER    |
 * | 18  | TOP PERCENT with CTEs                            | CTEs                | Tests 50% with Common Table Expressions       |
 * | 19  | TOP PERCENT with CROSS APPLY                     | Advanced Joins      | Tests 30% with CROSS APPLY                    |
 * | 20  | TOP PERCENT with Window Functions and Filtering  | Complex Window      | Tests 40% with multiple window functions      |
 * | 21  | Nested TOP PERCENT                               | Nested              | Tests 25% of 50% (nested percentages)         |
 * | 22  | TOP PERCENT with Revenue Analysis                | Complex CTE         | Tests 50% with revenue analysis CTE           |
 * | 23  | TOP PERCENT with Running Totals                  | Running Calculations| Tests 30% with SUM() OVER                     |
 * | 24  | TOP PERCENT with Complex Joins                   | Complex Joins       | Tests 40% with LEFT JOIN and window functions |
 * | 25  | Performance test with large table                | Performance         | Tests 10% with large dataset (10K rows)       |
 * | 26  | Complex performance test with large table        | Complex Performance | Tests 5% with GROUP BY, HAVING, window funcs  |
 * | 27  | TOP PERCENT with variables and reuse             | Variables           | Tests table variable storage and reuse        |
 * | 28  | TOP PERCENT with variable percentage             | Variable Percentage | Tests dynamic percentage with @percent_value  |
 * | 29  | TOP PERCENT in VIEW                              | Dependent Objects   | Tests TOP PERCENT within VIEW definition      |
 * | 30  | TOP PERCENT in FUNCTION                          | Dependent Objects   | Tests TOP PERCENT in table-valued function    |
 * | 31  | TOP PERCENT in STORED PROCEDURE                  | Dependent Objects   | Tests TOP PERCENT in stored procedure         |
 */

-- Create database for TOP PERCENT testing
CREATE DATABASE jira_babel_1358;
GO

USE jira_babel_1358;
GO

 -- Create test tables for TOP N PERCENT testing
CREATE TABLE test_percent_scores (
    id INT IDENTITY(1,1) PRIMARY KEY,
    student_name VARCHAR(50),
    score DECIMAL(5,2),
    class_name VARCHAR(50),
    year INT
);

CREATE TABLE test_percent_sales (
    id INT IDENTITY(1,1) PRIMARY KEY,
    product_name VARCHAR(50),
    revenue MONEY,
    region VARCHAR(50),
    quarter VARCHAR(2)
);
GO

-- Insert test data for scores
INSERT INTO test_percent_scores (student_name, score, class_name, year) VALUES
('John Doe', 95.5, 'Math', 2023),
('Jane Smith', 87.3, 'Math', 2023),
('Bob Wilson', 92.0, 'Math', 2023),
('Alice Brown', 78.5, 'Math', 2023),
('Charlie Davis', 88.9, 'Math', 2023),
('Eva White', 100.0, 'Physics', 2023),
('Frank Black', 100.0, 'Physics', 2023),
('George Grey', 0.0, 'Physics', 2023),
('Helen Green', NULL, 'Physics', 2023);

-- Insert test data for sales
INSERT INTO test_percent_sales (product_name, revenue, region, quarter) VALUES
('Product A', 10000.00, 'North', 'Q1'),
('Product B', 15000.50, 'North', 'Q1'),
('Product C', 20000.75, 'North', 'Q1'),
('Product D', 5000.25, 'South', 'Q1'),
('Product E', 7500.50, 'South', 'Q1'),
('Product F', NULL, 'South', 'Q1');
GO

-- Create a simple large table
CREATE TABLE test_percent_sales_large (
    id INT IDENTITY(1,1) PRIMARY KEY,
    product_name VARCHAR(20),
    category VARCHAR(20),
    sales_amount DECIMAL(10,2)
);
GO

-- Insert sample data (10,000 rows)
WITH Numbers AS (
    SELECT TOP 10000 
        ROW_NUMBER() OVER (ORDER BY a.object_id) AS RowNum
    FROM 
        sys.all_columns a
        CROSS JOIN sys.all_columns b
)
INSERT INTO test_percent_sales_large (product_name, category, sales_amount)
SELECT 
    'Product' + CAST((ABS(CHECKSUM(NEWID())) % 10 + 1) AS VARCHAR),
    CASE (ABS(CHECKSUM(NEWID())) % 3)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        WHEN 2 THEN 'Food'
    END,
    CAST((ABS(CHECKSUM(NEWID())) % 1000) + 100 AS DECIMAL(10,2))
FROM 
    Numbers;
GO


/*
 * ======================================================================================================================
 *                                          DEPENDENT OBJECTS TESTS
 * ======================================================================================================================
 */

 -- View 
CREATE VIEW top_performers_view AS
    SELECT TOP 20 PERCENT student_name, score, class_name
    FROM test_percent_scores
    WHERE score IS NOT NULL
    ORDER BY score DESC;
GO


-- Function
CREATE FUNCTION get_top_sales(@percentage FLOAT)
RETURNS TABLE
AS
RETURN (
    SELECT TOP (@percentage) PERCENT id, product_name, sales_amount
    FROM test_percent_sales_large
    ORDER BY sales_amount DESC
);
GO

-- Procedure
CREATE PROCEDURE get_top_percent_by_category
    @category VARCHAR(20),
    @percentage FLOAT
AS
BEGIN
    SELECT COUNT(*) as row_count
    FROM (
        SELECT TOP (@percentage) PERCENT *
        FROM test_percent_sales_large
        WHERE category = @category
        ORDER BY sales_amount DESC
    ) as derived_table;
END;
GO


