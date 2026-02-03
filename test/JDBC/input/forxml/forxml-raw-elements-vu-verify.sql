-- ============================================
-- SECTION 1: Basic ELEMENTS directive
-- ============================================

-- Basic ELEMENTS with two columns
SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS;
GO

-- Regression: Without ELEMENTS (attribute format)
SELECT 1 AS a, 2 AS b FOR XML RAW;
GO

-- ELEMENTS with three columns
SELECT 1 AS a, 2 AS b, 3 AS c FOR XML RAW, ELEMENTS;
GO

-- ELEMENTS with single column
SELECT 1 AS a FOR XML RAW, ELEMENTS;
GO

-- ELEMENTS with five columns
SELECT 1 AS a, 2 AS b, 3 AS c, 4 AS d, 5 AS e FOR XML RAW, ELEMENTS;
GO

-- ELEMENTS with ten columns
SELECT 1 AS a, 2 AS b, 3 AS c, 4 AS d, 5 AS e, 6 AS f, 7 AS g, 8 AS h, 9 AS i, 10 AS j FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 2: Custom element names
-- ============================================

SELECT 1 AS a, 2 AS b FOR XML RAW('item'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('Employee'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('my_element'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('x'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('element123'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('UPPERCASE'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('MixedCase'), ELEMENTS;
GO

-- ============================================
-- SECTION 3: NULL handling with ELEMENTS
-- ============================================

-- NULL in second column
SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS;
GO

-- NULL in first column
SELECT NULL AS a, 2 AS b FOR XML RAW, ELEMENTS;
GO

-- All NULL columns
SELECT NULL AS a, NULL AS b FOR XML RAW, ELEMENTS;
GO

-- NULL in middle column
SELECT 1 AS a, NULL AS b, 3 AS c FOR XML RAW, ELEMENTS;
GO

-- Multiple NULLs
SELECT NULL AS a, 2 AS b, NULL AS c FOR XML RAW, ELEMENTS;
GO

-- All NULLs with four columns
SELECT NULL AS a, NULL AS b, NULL AS c, NULL AS d FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 4: ELEMENTS ABSENT (default behavior)
-- ============================================

SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS ABSENT;
GO

SELECT NULL AS a, 2 AS b FOR XML RAW, ELEMENTS ABSENT;
GO

SELECT NULL AS a, NULL AS b FOR XML RAW, ELEMENTS ABSENT;
GO

SELECT 1 AS a, NULL AS b, 3 AS c FOR XML RAW, ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 5: ELEMENTS XSINIL
-- ============================================

SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT NULL AS a, 2 AS b FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT NULL AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT 1 AS a, NULL AS b, 3 AS c FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT NULL AS a, 2 AS b, NULL AS c FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT NULL AS a, NULL AS b, NULL AS c, NULL AS d FOR XML RAW, ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 6: ELEMENTS with ROOT directive
-- ============================================

SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, ROOT('data');
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, ROOT('data'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('item'), ELEMENTS, ROOT('items');
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('item'), ROOT('items'), ELEMENTS;
GO

SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL, ROOT('data');
GO

SELECT 1 AS a, NULL AS b FOR XML RAW, ROOT('data'), ELEMENTS XSINIL;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, ROOT('MyRoot');
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, ROOT('root123');
GO

-- ============================================
-- SECTION 7: ELEMENTS with TYPE directive
-- ============================================

SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, TYPE;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, TYPE, ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('item'), ELEMENTS, TYPE;
GO

SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL, TYPE;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, ROOT('data'), TYPE;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, TYPE, ROOT('data'), ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW, ROOT('data'), TYPE, ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('item'), ROOT('items'), ELEMENTS, TYPE;
GO

-- ============================================
-- SECTION 8: Table data with ELEMENTS
-- ============================================

SELECT * FROM forxml_raw_elements_t1 WHERE id = 1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id <= 2 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 3 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 3 FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 4 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 4 FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 5 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 5 FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_raw_elements_t1 FOR XML RAW('Employee'), ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
GO

SELECT * FROM forxml_raw_elements_t1 FOR XML RAW('Employee'), ELEMENTS XSINIL, ROOT('Employees');
GO

SELECT id, name FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS;
GO

SELECT name, salary FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS;
GO

SELECT id, salary FROM forxml_raw_elements_t1 WHERE salary IS NOT NULL FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 9: Multiple data types
-- ============================================

SELECT * FROM forxml_raw_elements_t2 WHERE col1 = 1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t2 WHERE col1 = 2 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t2 WHERE col1 = 2 FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT col1, col3 FROM forxml_raw_elements_t2 FOR XML RAW, ELEMENTS;
GO

SELECT col1, col4 FROM forxml_raw_elements_t2 FOR XML RAW, ELEMENTS;
GO

SELECT col1, col5 FROM forxml_raw_elements_t2 FOR XML RAW, ELEMENTS;
GO

SELECT 123 AS num FOR XML RAW, ELEMENTS;
GO

SELECT 123.456 AS decimal_num FOR XML RAW, ELEMENTS;
GO

SELECT 'hello' AS str FOR XML RAW, ELEMENTS;
GO

SELECT CAST('2024-01-15' AS DATE) AS date_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST('2024-01-15 10:30:00' AS DATETIME) AS datetime_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(1 AS BIT) AS bit_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(0 AS BIT) AS bit_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(12345.67 AS MONEY) AS money_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(123 AS BIGINT) AS bigint_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(123 AS SMALLINT) AS smallint_val FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 10: Special characters in values
-- ============================================

SELECT * FROM forxml_raw_elements_t3 WHERE id = 1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 2 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 3 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 4 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 5 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 6 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 7 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 WHERE id = 8 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t3 FOR XML RAW('SpecialChars'), ELEMENTS, ROOT('Data');
GO

-- Special character values directly
SELECT 'a & b' AS val FOR XML RAW, ELEMENTS;
GO

SELECT 'a < b' AS val FOR XML RAW, ELEMENTS;
GO

SELECT 'a > b' AS val FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 11: Unicode/Multibyte characters in values
-- ============================================

SELECT * FROM forxml_raw_elements_unicode FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_unicode FOR XML RAW('Record'), ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_unicode FOR XML RAW, ELEMENTS, ROOT('UnicodeData');
GO

SELECT * FROM forxml_raw_elements_unicode WHERE id = 1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_unicode WHERE id = 5 FOR XML RAW, ELEMENTS;
GO

SELECT '日本語' AS name, '中文' AS value FOR XML RAW, ELEMENTS;
GO

SELECT N'Ελληνικά' AS greek, N'Русский' AS russian FOR XML RAW, ELEMENTS;
GO

SELECT N'مرحبا' AS arabic, N'שלום' AS hebrew FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 12: Multibyte characters in element names
-- ============================================

SELECT 1 AS a, 2 AS b FOR XML RAW('データ'), ELEMENTS;
GO

SELECT 1 AS a FOR XML RAW, ELEMENTS, ROOT('ルート');
GO

SELECT 1 AS a, 2 AS b FOR XML RAW('中文元素'), ELEMENTS;
GO

SELECT 1 AS a FOR XML RAW('요소'), ELEMENTS, ROOT('루트');
GO

-- ============================================
-- SECTION 13: Long column names (>64 characters)
-- ============================================

SELECT * FROM forxml_raw_elements_long_cols FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_long_cols FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_raw_elements_long_cols FOR XML RAW('LongColTest'), ELEMENTS, ROOT('Data');
GO

-- ============================================
-- SECTION 14: Edge cases
-- ============================================

-- Empty result set
SELECT 1 AS a WHERE 1 = 0 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 999 FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a WHERE 1 = 0 FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT 1 AS a WHERE 1 = 0 FOR XML RAW, ELEMENTS, ROOT('data');
GO

-- Empty string values
SELECT '' AS empty_string FOR XML RAW, ELEMENTS;
GO

SELECT '   ' AS spaces_only FOR XML RAW, ELEMENTS;
GO

-- Explicit NULL cast
SELECT CAST(NULL AS VARCHAR(10)) AS null_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(NULL AS VARCHAR(10)) AS null_val FOR XML RAW, ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 15: Boundary cases for element names
-- ============================================

-- Empty element name
SELECT 1 AS a, 2 AS b FOR XML RAW(''), ELEMENTS;
GO

-- Element name with spaces
SELECT 1 AS a FOR XML RAW('element name'), ELEMENTS;
GO

-- Element name starting with number
SELECT 1 AS a FOR XML RAW('123element'), ELEMENTS;
GO

-- Element name with special characters
SELECT 1 AS a FOR XML RAW('element-name'), ELEMENTS;
GO

-- Element name with underscore
SELECT 1 AS a FOR XML RAW('element_name'), ELEMENTS;
GO

-- NULL element name
SELECT 1 AS a FOR XML RAW(NULL), ELEMENTS;
GO

-- ============================================
-- SECTION 16: ORDER BY, GROUP BY, TOP clauses
-- ============================================

SELECT * FROM forxml_raw_elements_t1 ORDER BY id FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY name FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY salary DESC FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY id FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
GO

SELECT department, COUNT(*) AS cnt FROM forxml_raw_elements_t1 GROUP BY department ORDER BY department FOR XML RAW, ELEMENTS;
GO

SELECT department, SUM(salary) AS total_salary FROM forxml_raw_elements_t1 GROUP BY department ORDER BY department FOR XML RAW, ELEMENTS;
GO

SELECT department, AVG(salary) AS avg_salary FROM forxml_raw_elements_t1 GROUP BY department ORDER BY department FOR XML RAW, ELEMENTS;
GO

SELECT TOP 1 * FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS;
GO

SELECT TOP 2 * FROM forxml_raw_elements_t1 ORDER BY id FOR XML RAW, ELEMENTS;
GO

SELECT TOP 3 * FROM forxml_raw_elements_t1 ORDER BY salary DESC FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 17: WHERE clause variations
-- ============================================

SELECT * FROM forxml_raw_elements_t1 WHERE salary > 50000 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE salary IS NULL FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE salary IS NULL FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE salary IS NOT NULL FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE name LIKE 'J%' FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE department IN ('IT', 'HR') FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 18: UNION queries
-- ============================================

SELECT 1 AS a, 2 AS b
UNION ALL
SELECT 3 AS a, 4 AS b
FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, 2 AS b
UNION ALL
SELECT 3 AS a, 4 AS b
UNION ALL
SELECT 5 AS a, 6 AS b
FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, NULL AS b
UNION ALL
SELECT NULL AS a, 2 AS b
FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, NULL AS b
UNION ALL
SELECT NULL AS a, 2 AS b
FOR XML RAW, ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 19: Subqueries
-- ============================================

SELECT id, (SELECT name FROM forxml_raw_elements_t1 t2 WHERE t2.id = t1.id FOR XML RAW, ELEMENTS, TYPE) AS subquery_result
FROM forxml_raw_elements_t1 t1
WHERE id <= 2;
GO

SELECT id, (SELECT name, salary FROM forxml_raw_elements_t1 t2 WHERE t2.id = t1.id FOR XML RAW, ELEMENTS, TYPE) AS emp_data
FROM forxml_raw_elements_t1 t1
WHERE id = 1;
GO

-- ============================================
-- SECTION 20: Stored Procedures
-- ============================================

EXEC forxml_raw_elements_proc1;
GO

EXEC forxml_raw_elements_proc2;
GO

EXEC forxml_raw_elements_proc3;
GO

EXEC forxml_raw_elements_proc4 @empid = 1;
GO

EXEC forxml_raw_elements_proc4 @empid = 3;
GO

EXEC forxml_raw_elements_proc4 @empid = 999;
GO

EXEC forxml_raw_elements_proc5 @empid = 3;
GO

EXEC forxml_raw_elements_proc6 @dept = 'IT';
GO

EXEC forxml_raw_elements_proc6 @dept = 'HR';
GO

-- ============================================
-- SECTION 21: INSERT..EXEC with procedures
-- ============================================

INSERT INTO forxml_raw_elements_results (xml_data)
EXEC forxml_raw_elements_proc_insert;
GO

SELECT * FROM forxml_raw_elements_results;
GO

TRUNCATE TABLE forxml_raw_elements_results;
GO

INSERT INTO forxml_raw_elements_results (xml_data)
EXEC forxml_raw_elements_proc_insert2;
GO

SELECT * FROM forxml_raw_elements_results;
GO

TRUNCATE TABLE forxml_raw_elements_results;
GO

INSERT INTO forxml_raw_elements_results (xml_data)
EXEC forxml_raw_elements_proc_insert3;
GO

SELECT * FROM forxml_raw_elements_results;
GO

TRUNCATE TABLE forxml_raw_elements_results;
GO

-- ============================================
-- SECTION 22: SELECT INTO variable
-- ============================================

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS);
SELECT @xml_var AS result;
GO

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS);
SELECT @xml_var AS result;
GO

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL);
SELECT @xml_var AS result;
GO

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, ROOT('data'));
SELECT @xml_var AS result;
GO

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT * FROM forxml_raw_elements_t1 WHERE id = 1 FOR XML RAW, ELEMENTS);
SELECT @xml_var AS result;
GO

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT * FROM forxml_raw_elements_t1 FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees'));
SELECT @xml_var AS result;
GO

DECLARE @xml_var XML;
SELECT @xml_var = (SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, TYPE);
SELECT @xml_var AS result;
GO

DECLARE @xml_var XML;
SELECT @xml_var = (SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL, TYPE);
SELECT @xml_var AS result;
GO

DECLARE @xml_var XML;
SELECT @xml_var = (SELECT * FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS, TYPE);
SELECT @xml_var AS result;
GO

DECLARE @xml_var XML;
SELECT @xml_var = (SELECT * FROM forxml_raw_elements_t1 FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees'), TYPE);
SELECT @xml_var AS result;
GO

-- ============================================
-- SECTION 23: Regular Views with FOR XML
-- ============================================

SELECT * FROM forxml_raw_elements_view1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_view1 FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
GO

SELECT * FROM forxml_raw_elements_view2 FOR XML RAW, ELEMENTS;
GO

-- ============================================
-- SECTION 24: Dependent Views (using FOR XML RAW, ELEMENTS)
-- ============================================

SELECT * FROM forxml_raw_elements_dep_view1;
GO

SELECT * FROM forxml_raw_elements_dep_view2;
GO

SELECT * FROM forxml_raw_elements_dep_view3;
GO

SELECT * FROM forxml_raw_elements_dep_view4;
GO

-- ============================================
-- SECTION 25: Dependent Functions (using FOR XML RAW, ELEMENTS)
-- ============================================

SELECT dbo.forxml_raw_elements_func1() AS result;
GO

SELECT dbo.forxml_raw_elements_func2() AS result;
GO

SELECT dbo.forxml_raw_elements_func3() AS result;
GO

SELECT dbo.forxml_raw_elements_func4(1) AS result;
GO

SELECT dbo.forxml_raw_elements_func4(3) AS result;
GO

-- ============================================
-- SECTION 26: XML methods on FOR XML result
-- ============================================

-- Using .value() method to extract data
SELECT (SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS, TYPE).value('(/row/a)[1]', 'INT') AS extracted_value;
GO

SELECT (SELECT 'hello' AS name FOR XML RAW, ELEMENTS, TYPE).value('(/row/name)[1]', 'VARCHAR(50)') AS extracted_name;
GO

SELECT (SELECT 1 AS id, 'John' AS name FOR XML RAW, ELEMENTS, TYPE).value('(/row/name)[1]', 'VARCHAR(50)') AS emp_name;
GO

-- ============================================
-- SECTION 27: JOIN Queries with ELEMENTS
-- ============================================

-- INNER JOIN - basic
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS;
GO

-- INNER JOIN with ELEMENTS XSINIL
SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS XSINIL;
GO

-- INNER JOIN with custom element name
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW('Employee'), ELEMENTS;
GO

-- INNER JOIN with ROOT
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
GO

-- LEFT JOIN - includes NULLs
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
LEFT JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS;
GO

-- LEFT JOIN with ELEMENTS XSINIL
SELECT e.emp_id, e.emp_name, d.dept_name, d.location
FROM forxml_raw_elements_employees e
LEFT JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS XSINIL;
GO

-- RIGHT JOIN
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
RIGHT JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS;
GO

-- RIGHT JOIN with ELEMENTS XSINIL
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
RIGHT JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS XSINIL;
GO

-- FULL OUTER JOIN
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
FULL OUTER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS;
GO

-- FULL OUTER JOIN with ELEMENTS XSINIL
SELECT e.emp_id, e.emp_name, d.dept_name
FROM forxml_raw_elements_employees e
FULL OUTER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS XSINIL;
GO

-- Self JOIN - employee with manager
SELECT e.emp_id, e.emp_name, m.emp_name AS manager_name
FROM forxml_raw_elements_employees e
LEFT JOIN forxml_raw_elements_employees m ON e.manager_id = m.emp_id
FOR XML RAW, ELEMENTS;
GO

-- Self JOIN with ELEMENTS XSINIL
SELECT e.emp_id, e.emp_name, m.emp_name AS manager_name
FROM forxml_raw_elements_employees e
LEFT JOIN forxml_raw_elements_employees m ON e.manager_id = m.emp_id
FOR XML RAW, ELEMENTS XSINIL;
GO

-- Multiple table JOIN (3 tables)
SELECT e.emp_name, d.dept_name, p.project_name, ep.role
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_emp_projects ep ON e.emp_id = ep.emp_id
INNER JOIN forxml_raw_elements_projects p ON ep.project_id = p.project_id
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW, ELEMENTS;
GO

-- Multiple table JOIN with custom element and ROOT
SELECT e.emp_name, d.dept_name, p.project_name, ep.role
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_emp_projects ep ON e.emp_id = ep.emp_id
INNER JOIN forxml_raw_elements_projects p ON ep.project_id = p.project_id
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
FOR XML RAW('Assignment'), ELEMENTS, ROOT('Assignments');
GO

-- Multiple table JOIN with NULLs and ELEMENTS XSINIL
SELECT e.emp_name, d.dept_name, p.project_name, p.budget
FROM forxml_raw_elements_employees e
LEFT JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
LEFT JOIN forxml_raw_elements_emp_projects ep ON e.emp_id = ep.emp_id
LEFT JOIN forxml_raw_elements_projects p ON ep.project_id = p.project_id
ORDER BY e.emp_name, p.project_name
FOR XML RAW, ELEMENTS XSINIL;
GO

-- JOIN with WHERE clause
SELECT e.emp_name, d.dept_name, e.salary
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.emp_name
FOR XML RAW, ELEMENTS;
GO

-- JOIN with ORDER BY
SELECT e.emp_name, d.dept_name, e.salary
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
ORDER BY e.salary DESC
FOR XML RAW, ELEMENTS;
GO

-- JOIN with GROUP BY and aggregation
SELECT d.dept_name, COUNT(e.emp_id) AS emp_count, SUM(e.salary) AS total_salary
FROM forxml_raw_elements_departments d
LEFT JOIN forxml_raw_elements_employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY d.dept_name
FOR XML RAW, ELEMENTS;
GO

-- JOIN with GROUP BY and ELEMENTS XSINIL
SELECT d.dept_name, COUNT(e.emp_id) AS emp_count, AVG(e.salary) AS avg_salary
FROM forxml_raw_elements_departments d
LEFT JOIN forxml_raw_elements_employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY d.dept_name
FOR XML RAW, ELEMENTS XSINIL;
GO

-- JOIN with TOP
SELECT TOP 3 e.emp_name, d.dept_name, e.salary
FROM forxml_raw_elements_employees e
INNER JOIN forxml_raw_elements_departments d ON e.dept_id = d.dept_id
ORDER BY e.salary DESC
FOR XML RAW, ELEMENTS;
GO

-- JOIN with DISTINCT
SELECT DISTINCT d.dept_name, d.location
FROM forxml_raw_elements_departments d
INNER JOIN forxml_raw_elements_employees e ON d.dept_id = e.dept_id
ORDER BY d.dept_name
FOR XML RAW, ELEMENTS;
GO

-- Cross JOIN (Cartesian product) - small result
SELECT TOP 5 e.emp_name, p.project_name
FROM forxml_raw_elements_employees e
CROSS JOIN forxml_raw_elements_projects p
ORDER BY e.emp_name, p.project_name
FOR XML RAW, ELEMENTS;
GO

-- Subquery in JOIN
SELECT e.emp_name, e.salary, dept_avg.avg_salary
FROM forxml_raw_elements_employees e
INNER JOIN (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM forxml_raw_elements_employees
    WHERE salary IS NOT NULL
    GROUP BY dept_id
) dept_avg ON e.dept_id = dept_avg.dept_id
FOR XML RAW, ELEMENTS;
GO