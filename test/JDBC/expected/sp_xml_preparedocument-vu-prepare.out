CREATE TABLE sp_xml_preparedocument_HandleStore (handle_value int);
GO

CREATE DATABASE sp_xml_preparedocument_temp_db;
GO

CREATE TABLE handle_store(handle_id INT);
GO

CREATE PROCEDURE test_xml_proc
AS
BEGIN
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>proc_value</child></root>';
SELECT @hdoc AS handle_inside_proc;
END
GO
