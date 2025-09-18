CREATE PROCEDURE openxml_without_with_dep_proc1(@xml nvarchar(max)) 
AS 
BEGIN
    DECLARE @handle INT;
    EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
    SELECT 
        id, parentid, nodetype, localname, prefix, namespaceuri, datatype, prev, text
    FROM OPENXML(@handle, '/') ORDER BY id;
    EXEC sp_xml_removedocument @handle;
END 
GO

CREATE PROCEDURE openxml_without_with_dep_proc2(@xml nvarchar(max)) 
AS 
BEGIN
    DECLARE @handle INT;
    EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
    SELECT 
        id, parentid, nodetype, localname, prefix, namespaceuri, datatype, prev, text
    FROM OPENXML(@handle, '/', 1) ORDER BY id;
    EXEC sp_xml_removedocument @handle;
END 
GO

-- Create a table to test the trigger and constraints
CREATE TABLE babel_6046_school_details_raw_xml (
    id INT,
    student NVARCHAR(MAX)
);
GO

CREATE TABLE babel_6046_school_details (
    id sys.BIGINT,
    parentid sys.BIGINT,
    nodetype sys.INT,
    localname sys.NVARCHAR(MAX),
    prefix sys.NVARCHAR(MAX),
    namespaceuri sys.NVARCHAR(MAX),
    datatype sys.NVARCHAR(MAX),
    prev sys.BIGINT,
    text sys.NTEXT
);
GO

-- Create a trigger to display invalid student entries
CREATE TRIGGER  babel_6046_school_details_raw_xml_to_table
ON babel_6046_school_details_raw_xml
AFTER INSERT
AS
BEGIN
    DECLARE @xml nvarchar(1000);
    SELECT @xml = student FROM inserted;
    DECLARE @handle INT;
    EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
    INSERT INTO babel_6046_school_details SELECT * FROM OPENXML(@handle, '/');
    EXEC sp_xml_removedocument @handle
END;
GO

