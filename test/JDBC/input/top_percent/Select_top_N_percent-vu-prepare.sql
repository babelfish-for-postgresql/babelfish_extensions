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
 * | 32  | TOP PERCENT with FOR JSON AUTO                   | JSON Output         | Tests 50% with FOR JSON AUTO                  |
 * | 33  | TOP PERCENT with FOR JSON PATH                   | JSON Output         | Tests 30% with FOR JSON PATH                  |
 * | 34  | TOP PERCENT with FOR JSON INCLUDE_NULL_VALUES    | JSON Output         | Tests 33% with NULL handling in JSON          |
 * | 35  | TOP PERCENT with UNION ALL                       | Set Operations      | Tests 30% and 50% with UNION ALL              |
 * | 36  | TOP PERCENT with UNION                           | Set Operations      | Tests 40% and 60% with UNION (deduplication)  |
 * | 37  | TOP PERCENT on outside of UNION                  | Set Operations      | Tests 20% applied to UNION result             |
 * | 38  | TOP PERCENT with cross schema JOIN               | Cross Schema        | Tests 30% with cross-schema LEFT JOIN         |
 * | 39  | TOP PERCENT with cross schema subquery           | Cross Schema        | Tests 40% with cross-schema subquery          |
 * | 40  | TOP PERCENT with cross schema CTE                | Cross Schema        | Tests 50% with cross-schema CTE               |
 * | 41  | UPDATE TOP N PERCENT                             | Error Case          | Should throw error - not supported            |
 * | 42  | DELETE TOP N PERCENT                             | Error Case          | Should throw error - not supported            |
 * | 43  | INSERT TOP N PERCENT                             | Error Case          | Should throw error - not supported            |
 * | 44  | INSERT with OUTPUT INTO and TOP N PERCENT        | OUTPUT INTO         | Tests INSERT TOP 100% with OUTPUT INTO        |
 * | 45  | UPDATE with JOIN and TOP N PERCENT               | JOIN with DML       | Tests UPDATE TOP 100% with JOIN               |
 * | 46  | UPDATE with OUTPUT INTO and TOP N PERCENT        | OUTPUT INTO         | Tests UPDATE TOP 100% with OUTPUT INTO        |
 * | 47  | DELETE with JOIN and TOP N PERCENT               | JOIN with DML       | Tests DELETE TOP 100% with JOIN               |
 * | 48  | DELETE with OUTPUT INTO and TOP N PERCENT        | OUTPUT INTO         | Tests DELETE TOP 100% with OUTPUT INTO        |
 */

-- Create schema for TOP PERCENT testing
CREATE SCHEMA jira_babel_1358;
GO

 -- Create test tables for TOP N PERCENT testing
CREATE TABLE jira_babel_1358.test_percent_scores (
    id INT,
    student_name VARCHAR(50),
    score DECIMAL(5,2),
    class_name VARCHAR(50),
    year INT
);

CREATE TABLE jira_babel_1358.test_percent_sales (
    id INT,
    product_name VARCHAR(50),
    revenue MONEY,
    region VARCHAR(50),
    quarter VARCHAR(2)
);
GO

-- Insert test data for scores
INSERT INTO jira_babel_1358.test_percent_scores (id, student_name, score, class_name, year) VALUES
(1, 'John Doe', 95.5, 'Math', 2023),
(2, 'Jane Smith', 87.3, 'Math', 2023),
(3, 'Bob Wilson', 92.0, 'Math', 2023),
(4, 'Alice Brown', 78.5, 'Math', 2023),
(5, 'Charlie Davis', 88.9, 'Math', 2023),
(6, 'Eva White', 100.0, 'Physics', 2023),
(7, 'Frank Black', 100.0, 'Physics', 2023),
(8, 'George Grey', 0.0, 'Physics', 2023),
(9, 'Helen Green', NULL, 'Physics', 2023);

-- Insert test data for sales
INSERT INTO jira_babel_1358.test_percent_sales (id, product_name, revenue, region, quarter) VALUES
(1, 'Product A', 10000.00, 'North', 'Q1'),
(2, 'Product B', 15000.50, 'North', 'Q1'),
(3, 'Product C', 20000.75, 'North', 'Q1'),
(4, 'Product D', 5000.25, 'South', 'Q1'),
(5, 'Product E', 7500.50, 'South', 'Q1'),
(6, 'Product F', NULL, 'South', 'Q1');
GO

-- Create a simple large table
CREATE TABLE jira_babel_1358.test_percent_sales_large (
    product_name VARCHAR(20),
    category VARCHAR(20),
    sales_amount DECIMAL(10,2)
);
GO

-- Insert sample data (10,000 rows)
WITH Numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 
    FROM Numbers 
    WHERE n < 10000
)
INSERT INTO jira_babel_1358.test_percent_sales_large (product_name, category, sales_amount)
SELECT 
    'Product' + CAST((n % 10) AS VARCHAR(2)),
    CASE (n % 3)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Clothing'
        ELSE 'Food'
    END,
    100 + (n % 900)
FROM Numbers
OPTION (MAXRECURSION 10000);
GO


/*
 * ======================================================================================================================
 *                                          DEPENDENT OBJECTS TESTS
 * ======================================================================================================================
 */

 -- View 
CREATE VIEW jira_babel_1358.top_performers_view AS
    SELECT TOP 20 PERCENT student_name, score, class_name
    FROM jira_babel_1358.test_percent_scores
    WHERE score IS NOT NULL
    ORDER BY score DESC;
GO


-- Function
CREATE FUNCTION jira_babel_1358.get_top_sales(@percentage FLOAT)
RETURNS TABLE
AS
RETURN (
    SELECT TOP (@percentage) PERCENT product_name, sales_amount
    FROM jira_babel_1358.test_percent_sales_large
    ORDER BY sales_amount DESC
);
GO

-- Procedure
CREATE PROCEDURE jira_babel_1358.get_top_percent_by_category
    @category VARCHAR(20),
    @percentage FLOAT
AS
BEGIN
    SELECT COUNT(*) as row_count
    FROM (
        SELECT TOP (@percentage) PERCENT *
        FROM jira_babel_1358.test_percent_sales_large
        WHERE category = @category
        ORDER BY sales_amount DESC
    ) as derived_table;
END;
GO


-- Create second schema for cross-schema testing
CREATE SCHEMA test_schema2_jira_babel_1358;
GO

CREATE TABLE test_schema2_jira_babel_1358.test_cross_sales (
    id INT,
    product_name VARCHAR(50),
    revenue MONEY,
    region VARCHAR(50),
    sales_date DATE
);
GO

-- Insert test data for cross-schema testing
INSERT INTO test_schema2_jira_babel_1358.test_cross_sales (id, product_name, revenue, region, sales_date) VALUES
(1, 'Cross Product A', 12000.00, 'East', '2023-01-15'),
(2, 'Cross Product B', 18000.50, 'West', '2023-02-20'),
(3, 'Cross Product C', 25000.75, 'East', '2023-03-10'),
(4, 'Cross Product D', 8000.25, 'West', '2023-04-05'),
(5, 'Cross Product E', 15500.50, 'North', '2023-05-12');
GO


/*
 * Created to test insert into output ..
 * test case 43-48 
 */ 
CREATE TABLE jira_babel_1358.test_percent_scores_second (
    id INT,
    student_name VARCHAR(50),
    score DECIMAL(5,2),
    class_name VARCHAR(50),
    year INT
);

CREATE TABLE jira_babel_1358.test_percent_sales_second (
    id INT,
    product_name VARCHAR(50),
    revenue MONEY,
    region VARCHAR(50),
    quarter VARCHAR(2)
);
GO

CREATE TABLE jira_babel_1358.test_percent_scores_third (
    id INT,
    student_name VARCHAR(50),
    score DECIMAL(5,2),
    class_name VARCHAR(50),
    year INT
);

CREATE TABLE jira_babel_1358.test_percent_sales_third (
    id INT,
    product_name VARCHAR(50),
    revenue MONEY,
    region VARCHAR(50),
    quarter VARCHAR(2)
);
GO