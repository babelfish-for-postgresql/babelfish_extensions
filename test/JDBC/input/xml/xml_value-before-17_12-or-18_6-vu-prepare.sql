CREATE TABLE babel_5223_xml_value_t1 (XmlColumn XML)
GO

INSERT INTO babel_5223_xml_value_t1
VALUES ('<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>')
GO

CREATE TABLE babel_5223_xml_value_t2 (Id INT PRIMARY KEY, XmlColumn XML);
GO

INSERT INTO babel_5223_xml_value_t2 (Id, XmlColumn)
VALUES (1, '<Root><Child1>Value1</Child1></Root>'),
       (2, '<Root><Child2>Value2</Child2></Root>'),
       (3, '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>');
GO

CREATE TABLE babel_5223_xml_value_text (XmlColumn TEXT)
GO

INSERT INTO babel_5223_xml_value_text
VALUES ('<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>')
GO

CREATE SCHEMA babel_5223_sch1
GO

CREATE SCHEMA babel_5223_sch2
GO

CREATE TYPE babel_5223_sch1.babel_5223_xml_value_sch_varcharUDT FROM VARCHAR(100);
GO

CREATE TYPE babel_5223_sch2.babel_5223_xml_value_sch_varcharUDT FROM VARCHAR(100);
GO

CREATE TYPE dbo.babel_5223_xml_value_varcharUDT FROM VARCHAR(100);
GO

CREATE TYPE dbo.babel_5223_xml_value_imageUDT FROM IMAGE;
GO

CREATE TYPE dbo.babel_5223_xml_value_xmlUDT FROM XML;
GO

CREATE TABLE babel_5223_xml_value_udt (VarUDTColumn dbo.babel_5223_xml_value_varcharUDT, ImageUDTColumn dbo.babel_5223_xml_value_imageUDT, XmlUDTColumn dbo.babel_5223_xml_value_xmlUDT)
GO

INSERT INTO babel_5223_xml_value_udt
VALUES ('<Root><Child1>Value1</Child1></Root>', CAST('<Root><Child1>Value1</Child1></Root>' AS IMAGE), '<Root><Child1>Value1</Child1></Root>')
GO

CREATE VIEW babel_5223_xml_value_dep_view AS
    SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') as namevalues FROM babel_5223_xml_value_t1
GO

CREATE PROCEDURE babel_5223_xml_value_dep_proc AS
    SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1
GO

CREATE FUNCTION babel_5223_xml_value_dep_func()
RETURNS VARCHAR(100)
AS
BEGIN
RETURN (SELECT TOP 1 XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1)
END
GO

CREATE FUNCTION babel_5223_xml_value_itvf_func()
RETURNS TABLE
AS
RETURN (SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') as namevalues FROM babel_5223_xml_value_t1)
GO

CREATE FUNCTION dbo.babel_5223_xml_value_func1()
RETURNS XML
AS
BEGIN
RETURN CAST('<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>' as XML)
END
GO

-- computed columns
CREATE TABLE babel_5223_xml_value_compcol(id INT, col_xml XML, comp_col as col_xml.value('(/artist/@name)[1]', 'varchar(100)'))
GO

-- check constraints
CREATE TABLE babel_5223_xml_value_constraint(col_xml XML, constraint chkNamevalue check(col_xml.value('(/artist/@name)[1]', 'varchar(100)') IS NULL))
GO

-- UDF wrapper function on value
CREATE FUNCTION dbo.wrapper_xmlvalue1(@xml XML)
RETURNS VARCHAR(100)
AS
BEGIN
RETURN @xml.value('(/artist/@name)[1]', 'varchar(100)');
END
GO

-- change the volatility of wrapper_xmlvalue1 to immutable
EXEC sys.sp_babelfish_volatility 'wrapper_xmlvalue1', 'immutable'
GO
EXEC sys.sp_babelfish_volatility 'wrapper_xmlvalue1'
GO

-- computed columns on wrapper function
CREATE TABLE babel_5223_xml_value_compcol1(id INT, col_xml XML, comp_col as dbo.wrapper_xmlvalue1(col_xml))
GO

-- check constraints on wrapper function
CREATE TABLE babel_5223_xml_value_constraint1(col_xml XML, constraint chkNamevalue1 check(wrapper_xmlvalue1(col_xml) IS NULL))
GO


SET QUOTED_IDENTIFIER OFF
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

-- creating dependent view on xml value when quoted_identifier is OFF
CREATE VIEW babel_5223_xml_value_dep_view2 AS
    SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') as namevalues FROM babel_5223_xml_value_t1
GO

-- creating wrapper function on xml value when quoted_identifier is OFF
CREATE FUNCTION dbo.wrapper_xmlvalue2(@xml XML)
RETURNS VARCHAR(100)
AS
BEGIN
RETURN @xml.value('(/artist/@name)[1]', 'varchar(100)');
END
GO

-- change the volatility of wrapper_xmlvalue2 to immutable
EXEC sys.sp_babelfish_volatility 'wrapper_xmlvalue2', 'immutable'
GO
EXEC sys.sp_babelfish_volatility 'wrapper_xmlvalue2'
GO

-- creating computed columns on wrapper function when quoted_identifier is OFF
CREATE TABLE babel_5223_xml_value_compcol2(id INT, col_xml XML, comp_col as dbo.wrapper_xmlvalue2(col_xml))
GO

-- creating check constraints on wrapper function when quoted_identifier is OFF
CREATE TABLE babel_5223_xml_value_constraint2(col_xml XML, constraint chkNamevalue2 check(wrapper_xmlvalue2(col_xml) = 'Rohit Bhagat'))
GO


SET QUOTED_IDENTIFIER ON
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO


-- Create a table to test the trigger and constraints
CREATE TABLE babel_5223_xml_value_school_details (
    id INT,
    student XML
);
GO

INSERT INTO babel_5223_xml_value_school_details (id, student)
VALUES
    (1, '<student classid="1" rollid="1" studentname="StudentA" />'),
    (2, '<student classid="1" rollid="2" studentname="StudentB" />'),
    (3, '<student classid="1" rollid="3" studentname="StudentC" />'),
    (4, '<student classid="2" rollid="1" studentname="StudentD" />'),
    (5, '<student classid="2" rollid="2" studentname="StudentE" />')
GO

-- Create a trigger to display invalid student entries
CREATE TRIGGER  babel_5223_xml_value_tr_parital_student_entry
ON babel_5223_xml_value_school_details
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SELECT id, student AS invalid_entries FROM babel_5223_xml_value_school_details
    WHERE student.value('(/student/@studentname)[1]', 'varchar(100)') not like 'Student%'
    ORDER BY id;
END;
GO
