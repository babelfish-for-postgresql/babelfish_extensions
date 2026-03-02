-- ============================================
-- SECTION: Base Tables
-- ============================================

CREATE TABLE forxml_path_elements_t1 (
    ID INT,
    Name VARCHAR(50),
    Department VARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_t1 VALUES (1, 'John', 'Sales');
INSERT INTO forxml_path_elements_t1 VALUES (2, 'Jane', NULL);
INSERT INTO forxml_path_elements_t1 VALUES (3, 'Bob', 'IT');
INSERT INTO forxml_path_elements_t1 VALUES (4, NULL, NULL);
INSERT INTO forxml_path_elements_t1 VALUES (5, NULL, 'HR');
GO

-- ============================================
-- SECTION: Multiple Data Types Table
-- ============================================

CREATE TABLE forxml_path_elements_t2 (
    IntCol INT,
    VarcharCol VARCHAR(50),
    BitCol BIT,
    DecimalCol DECIMAL(10,2),
    DateCol DATE
);
GO

INSERT INTO forxml_path_elements_t2 VALUES (100, 'Text1', 1, 99.99, '2024-01-01');
INSERT INTO forxml_path_elements_t2 VALUES (NULL, NULL, NULL, NULL, NULL);
INSERT INTO forxml_path_elements_t2 VALUES (200, NULL, 0, NULL, '2024-06-15');
INSERT INTO forxml_path_elements_t2 VALUES (NULL, 'Text2', NULL, 50.00, NULL);
GO

-- ============================================
-- SECTION: NULL Patterns Table
-- ============================================

CREATE TABLE forxml_path_elements_t3 (
    Col1 INT,
    Col2 VARCHAR(50),
    Col3 VARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_t3 VALUES (NULL, NULL, NULL);
INSERT INTO forxml_path_elements_t3 VALUES (1, NULL, NULL);
INSERT INTO forxml_path_elements_t3 VALUES (NULL, 'Val', NULL);
INSERT INTO forxml_path_elements_t3 VALUES (NULL, NULL, 'Val');
GO

-- ============================================
-- SECTION: Attribute-Centric Test Table
-- ============================================

CREATE TABLE forxml_path_elements_t4 (
    ID INT,
    Name VARCHAR(50),
    Value VARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_t4 VALUES (1, 'Item1', 'Value1');
INSERT INTO forxml_path_elements_t4 VALUES (2, NULL, 'Value2');
INSERT INTO forxml_path_elements_t4 VALUES (3, 'Item3', NULL);
GO

-- ============================================
-- SECTION: Single Column Table
-- ============================================

CREATE TABLE forxml_path_elements_t5 (
    SingleCol VARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_t5 VALUES ('Value');
INSERT INTO forxml_path_elements_t5 VALUES (NULL);
GO

-- ============================================
-- SECTION: Many Columns Table
-- ============================================

CREATE TABLE forxml_path_elements_t6 (
    Col1 INT,
    Col2 VARCHAR(50),
    Col3 VARCHAR(50),
    Col4 INT,
    Col5 VARCHAR(50),
    Col6 BIT,
    Col7 VARCHAR(50),
    Col8 INT
);
GO

INSERT INTO forxml_path_elements_t6 VALUES (1, 'A', 'B', 2, 'C', 1, 'D', 3);
INSERT INTO forxml_path_elements_t6 VALUES (NULL, NULL, 'B', NULL, 'C', NULL, NULL, NULL);
INSERT INTO forxml_path_elements_t6 VALUES (1, NULL, NULL, 2, NULL, NULL, 'D', NULL);
GO

-- ============================================
-- SECTION: Text Content Table
-- ============================================

CREATE TABLE forxml_path_elements_t7 (
    ID INT,
    TextCol VARCHAR(100)
);
GO

INSERT INTO forxml_path_elements_t7 VALUES (1, 'Normal Text');
INSERT INTO forxml_path_elements_t7 VALUES (2, NULL);
INSERT INTO forxml_path_elements_t7 VALUES (3, 'Text with special chars');
GO

-- ============================================
-- SECTION: Special Characters Table
-- ============================================

CREATE TABLE forxml_path_elements_special (
    ID INT,
    Value VARCHAR(100)
);
GO

INSERT INTO forxml_path_elements_special VALUES (1, 'a & b');
INSERT INTO forxml_path_elements_special VALUES (2, 'a < b');
INSERT INTO forxml_path_elements_special VALUES (3, 'a > b');
INSERT INTO forxml_path_elements_special VALUES (4, 'say "hello"');
INSERT INTO forxml_path_elements_special VALUES (5, 'it''s working');
INSERT INTO forxml_path_elements_special VALUES (6, '<tag>value</tag>');
GO

-- ============================================
-- SECTION: Unicode/Multibyte Values Table
-- ============================================

CREATE TABLE forxml_path_elements_unicode (
    ID INT,
    Name NVARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_unicode VALUES (1, N'日本語');
INSERT INTO forxml_path_elements_unicode VALUES (2, N'中文');
INSERT INTO forxml_path_elements_unicode VALUES (3, N'한국어');
INSERT INTO forxml_path_elements_unicode VALUES (4, N'العربية');
INSERT INTO forxml_path_elements_unicode VALUES (5, N'émoji 😀');
GO

-- ============================================
-- SECTION: Long Column Names Table (>64 characters)
-- ============================================

CREATE TABLE forxml_path_elements_long_cols (
    ID INT,
    this_is_a_very_long_column_name_that_exceeds_sixty_four_characters_in_length VARCHAR(50),
    another_extremely_long_column_name_for_testing_xml_element_generation_limits VARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_long_cols VALUES (1, 'value1', 'value2');
INSERT INTO forxml_path_elements_long_cols VALUES (2, NULL, 'value3');
GO

-- ============================================
-- SECTION: Tables for JOIN Queries
-- ============================================

CREATE TABLE forxml_path_elements_orders (
    OrderID INT,
    CustomerID INT,
    OrderDate DATE,
    TotalAmount DECIMAL(10,2)
);
GO

INSERT INTO forxml_path_elements_orders VALUES (1, 1, '2024-01-15', 100.00);
INSERT INTO forxml_path_elements_orders VALUES (2, 1, '2024-02-20', 250.00);
INSERT INTO forxml_path_elements_orders VALUES (3, 2, '2024-03-10', NULL);
INSERT INTO forxml_path_elements_orders VALUES (4, 3, NULL, 175.50);
GO

CREATE TABLE forxml_path_elements_customers (
    CustomerID INT,
    CustomerName VARCHAR(50),
    City VARCHAR(50)
);
GO

INSERT INTO forxml_path_elements_customers VALUES (1, 'Acme Corp', 'New York');
INSERT INTO forxml_path_elements_customers VALUES (2, 'Tech Inc', NULL);
INSERT INTO forxml_path_elements_customers VALUES (3, NULL, 'Boston');
INSERT INTO forxml_path_elements_customers VALUES (4, 'Global Ltd', 'Chicago');
GO

CREATE TABLE forxml_path_elements_products (
    ProductID INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2)
);
GO

INSERT INTO forxml_path_elements_products VALUES (1, 'Widget', 25.00);
INSERT INTO forxml_path_elements_products VALUES (2, 'Gadget', NULL);
INSERT INTO forxml_path_elements_products VALUES (3, NULL, 75.00);
GO

CREATE TABLE forxml_path_elements_order_items (
    OrderID INT,
    ProductID INT,
    Quantity INT
);
GO

INSERT INTO forxml_path_elements_order_items VALUES (1, 1, 2);
INSERT INTO forxml_path_elements_order_items VALUES (1, 2, NULL);
INSERT INTO forxml_path_elements_order_items VALUES (2, 1, 5);
INSERT INTO forxml_path_elements_order_items VALUES (3, 3, 1);
GO

-- ============================================
-- SECTION: Stored Procedures (using FOR XML PATH, ELEMENTS)
-- ============================================

CREATE PROCEDURE forxml_path_elements_p1 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS;
GO

CREATE PROCEDURE forxml_path_elements_p2 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

CREATE PROCEDURE forxml_path_elements_p3 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

CREATE PROCEDURE forxml_path_elements_p4 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS XSINIL;
GO

CREATE PROCEDURE forxml_path_elements_p5 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL, ROOT('Data');
GO

CREATE PROCEDURE forxml_path_elements_p7 @DeptFilter VARCHAR(50) AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE Department = @DeptFilter OR Department IS NULL FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

CREATE PROCEDURE forxml_path_elements_p6 @empid INT AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = @empid FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO


-- ============================================
-- SECTION: Regular Views (not using FOR XML)
-- ============================================

CREATE VIEW forxml_path_elements_regular_view AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID <= 3;
GO

-- ============================================
-- SECTION: Dependent Views (using FOR XML PATH, ELEMENTS)
-- ============================================

CREATE VIEW forxml_path_elements_dep_view1 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS;
GO

CREATE VIEW forxml_path_elements_dep_view2 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

CREATE VIEW forxml_path_elements_dep_view3 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

CREATE VIEW forxml_path_elements_dep_view4 AS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Employees'), ELEMENTS XSINIL;
GO

CREATE VIEW forxml_path_elements_dep_view5 AS
SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION: Dependent Functions (using FOR XML PATH, ELEMENTS)
-- ============================================

CREATE FUNCTION forxml_path_elements_func1()
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SELECT @result = (SELECT ID, Name FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH('Employee'), ELEMENTS);
    RETURN @result;
END;
GO

CREATE FUNCTION forxml_path_elements_func2()
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SELECT @result = (SELECT ID, Name FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL);
    RETURN @result;
END;
GO

CREATE FUNCTION forxml_path_elements_func3()
RETURNS XML
AS
BEGIN
    DECLARE @result XML;
    SELECT @result = (SELECT * FROM forxml_path_elements_t1 WHERE ID <= 2 FOR XML PATH('Employee'), ELEMENTS, TYPE);
    RETURN @result;
END;
GO

CREATE FUNCTION forxml_path_elements_func4(@empid INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @result NVARCHAR(MAX);
    SELECT @result = (SELECT * FROM forxml_path_elements_t1 WHERE ID = @empid FOR XML PATH('Employee'), ELEMENTS XSINIL);
    RETURN @result;
END;
GO