CREATE TABLE forxml_raw_elements_t1 (id INT, name VARCHAR(50), salary INT, department VARCHAR(50));
INSERT INTO forxml_raw_elements_t1 VALUES (1, 'John', 50000, 'IT');
INSERT INTO forxml_raw_elements_t1 VALUES (2, 'Jane', 60000, 'HR');
INSERT INTO forxml_raw_elements_t1 VALUES (3, 'Bob', NULL, 'Finance');
INSERT INTO forxml_raw_elements_t1 VALUES (4, 'Alice', 70000, NULL);
INSERT INTO forxml_raw_elements_t1 VALUES (5, NULL, NULL, NULL);
GO

CREATE TABLE forxml_raw_elements_t2 (col1 INT, col2 VARCHAR(20), col3 DECIMAL(10,2), col4 DATE, col5 BIT);
INSERT INTO forxml_raw_elements_t2 VALUES (1, 'test', 123.45, '2024-01-15', 1);
INSERT INTO forxml_raw_elements_t2 VALUES (2, NULL, NULL, NULL, NULL);
GO

CREATE TABLE forxml_raw_elements_t3 (id INT, value VARCHAR(100));
INSERT INTO forxml_raw_elements_t3 VALUES (1, 'a & b');
INSERT INTO forxml_raw_elements_t3 VALUES (2, 'a < b');
INSERT INTO forxml_raw_elements_t3 VALUES (3, 'a > b');
INSERT INTO forxml_raw_elements_t3 VALUES (4, 'say "hello"');
INSERT INTO forxml_raw_elements_t3 VALUES (5, 'it''s working');
INSERT INTO forxml_raw_elements_t3 VALUES (6, '<tag>value</tag>');
INSERT INTO forxml_raw_elements_t3 VALUES (7, '   spaces   ');
INSERT INTO forxml_raw_elements_t3 VALUES (8, '');
GO

CREATE TABLE forxml_raw_elements_unicode (id INT, name NVARCHAR(50));
INSERT INTO forxml_raw_elements_unicode VALUES (1, N'日本語');
INSERT INTO forxml_raw_elements_unicode VALUES (2, N'中文');
INSERT INTO forxml_raw_elements_unicode VALUES (3, N'한국어');
INSERT INTO forxml_raw_elements_unicode VALUES (4, N'العربية');
INSERT INTO forxml_raw_elements_unicode VALUES (5, N'émoji 😀');
GO

CREATE TABLE forxml_raw_elements_results (xml_data VARCHAR(MAX));
GO

CREATE PROCEDURE forxml_raw_elements_proc1
AS
BEGIN
    SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS;
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc2
AS
BEGIN
    SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL;
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc3
AS
BEGIN
    SELECT * FROM forxml_raw_elements_t1 FOR XML RAW('Employee'), ELEMENTS, ROOT('Employees');
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc4 @empid INT
AS
BEGIN
    SELECT * FROM forxml_raw_elements_t1 WHERE id = @empid FOR XML RAW, ELEMENTS;
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc5 @empid INT
AS
BEGIN
    SELECT * FROM forxml_raw_elements_t1 WHERE id = @empid FOR XML RAW, ELEMENTS XSINIL;
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc6 @dept VARCHAR(50)
AS
BEGIN
    SELECT * FROM forxml_raw_elements_t1 WHERE department = @dept FOR XML RAW('Employee'), ELEMENTS, ROOT('Department');
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc_insert
AS
BEGIN
    SELECT 1 AS a, 2 AS b FOR XML RAW, ELEMENTS;
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc_insert2
AS
BEGIN
    SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL;
END;
GO

CREATE PROCEDURE forxml_raw_elements_proc_insert3
AS
BEGIN
    SELECT * FROM forxml_raw_elements_t1 FOR XML RAW, ELEMENTS, ROOT('data');
END;
GO

CREATE VIEW forxml_raw_elements_view1 AS
SELECT * FROM forxml_raw_elements_t1 WHERE salary IS NOT NULL;
GO

CREATE VIEW forxml_raw_elements_view2 (col1, col2) AS
SELECT id, name FROM forxml_raw_elements_t1;
GO
