CREATE PROCEDURE openxml_without_with_dep_proc(@xml nvarchar(max)) 
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
