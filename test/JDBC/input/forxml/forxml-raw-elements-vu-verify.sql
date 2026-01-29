SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, 2 AS b FOR XML RAW;
GO

SELECT 1 AS a, 2 AS b, 3 AS c FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, 2 AS b, 3 AS c, 4 AS d, 5 AS e FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, 2 AS b, 3 AS c, 4 AS d, 5 AS e, 6 AS f, 7 AS g, 8 AS h, 9 AS i, 10 AS j FOR XML RAW, ELEMENTS;
GO

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

SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS;
GO

SELECT NULL AS a, 2 AS b FOR XML RAW, ELEMENTS;
GO

SELECT NULL AS a, NULL AS b FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, NULL AS b, 3 AS c FOR XML RAW, ELEMENTS;
GO

SELECT NULL AS a, 2 AS b, NULL AS c FOR XML RAW, ELEMENTS;
GO

SELECT NULL AS a, NULL AS b, NULL AS c, NULL AS d FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS ABSENT;
GO

SELECT NULL AS a, 2 AS b FOR XML RAW, ELEMENTS ABSENT;
GO

SELECT NULL AS a, NULL AS b FOR XML RAW, ELEMENTS ABSENT;
GO

SELECT 1 AS a, NULL AS b, 3 AS c FOR XML RAW, ELEMENTS ABSENT;
GO

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

SELECT 1 AS a WHERE 1 = 0 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 WHERE id = 999 FOR XML RAW, ELEMENTS;
GO

SELECT 1 AS a WHERE 1 = 0 FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT 1 AS a WHERE 1 = 0 FOR XML RAW, ELEMENTS, ROOT('data');
GO

SELECT '' AS empty_string FOR XML RAW, ELEMENTS;
GO

SELECT '   ' AS spaces_only FOR XML RAW, ELEMENTS;
GO

SELECT CAST(NULL AS VARCHAR(10)) AS null_val FOR XML RAW, ELEMENTS;
GO

SELECT CAST(NULL AS VARCHAR(10)) AS null_val FOR XML RAW, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY id FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY name FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY salary DESC FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_t1 ORDER BY id FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
GO

SELECT department, COUNT(*) AS cnt FROM forxml_raw_elements_t1 GROUP BY department FOR XML RAW, ELEMENTS;
GO

SELECT department, SUM(salary) AS total_salary FROM forxml_raw_elements_t1 GROUP BY department FOR XML RAW, ELEMENTS;
GO

SELECT department, AVG(salary) AS avg_salary FROM forxml_raw_elements_t1 GROUP BY department FOR XML RAW, ELEMENTS;
GO

SELECT TOP 1 * FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS;
GO

SELECT TOP 2 * FROM forxml_raw_elements_t1 ORDER BY id FOR XML RAW, ELEMENTS;
GO

SELECT TOP 3 * FROM forxml_raw_elements_t1 ORDER BY salary DESC FOR XML RAW, ELEMENTS;
GO

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

SELECT id, (SELECT name FROM forxml_raw_elements_t1 t2 WHERE t2.id = t1.id FOR XML RAW, ELEMENTS, TYPE) AS subquery_result
FROM forxml_raw_elements_t1 t1
WHERE id <= 2;
GO

SELECT id, (SELECT name, salary FROM forxml_raw_elements_t1 t2 WHERE t2.id = t1.id FOR XML RAW, ELEMENTS, TYPE) AS emp_data
FROM forxml_raw_elements_t1 t1
WHERE id = 1;
GO

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

SELECT * FROM forxml_raw_elements_view1 FOR XML RAW, ELEMENTS;
GO

SELECT * FROM forxml_raw_elements_view1 FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
GO

SELECT * FROM forxml_raw_elements_view2 FOR XML RAW, ELEMENTS;
GO
