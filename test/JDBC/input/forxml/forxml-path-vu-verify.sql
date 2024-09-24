-- Should throw Error , att-centric after normal columns
SELECT  String as param1, hello.String as [@param2] FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('hello')
GO

-- Should throw error, PATH supplied is NULL
SELECT hello.String as [@param2] FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('')
GO


-- NORMAL Usecase both types of columns
SELECT hello.String as [@param2] , string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH
GO

-- Only att-centric columns
SELECT String as [@param2]  FROM for_xml_path ORDER BY SequenceNumber FOR XML PATH
GO

-- Complex expression without column name , should not add a <?column?> tag
SELECT ' '+string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('')
GO

-- Complex expression without column name , should not add a <?column?> tag
SELECT ' '+string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH
GO

-- Dep Objects
SELECT * FROM for_xml_path_v1
GO

SELECT * FROM for_xml_path_v2
GO

SELECT * FROM for_xml_path_v3
GO

SELECT * FROM for_xml_path_v4
GO

EXEC for_xml_path_p1
GO

EXEC for_xml_path_p2
GO

EXEC for_xml_path_p3
GO

EXEC for_xml_path_p4
GO
