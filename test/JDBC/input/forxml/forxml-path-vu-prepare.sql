CREATE TABLE for_xml_path (SequenceNumber  INTEGER PRIMARY KEY, String VARCHAR(100) NOT NULL);
GO

INSERT INTO for_xml_path VALUES (1,'SELECT'),(2,'Product,'),(3,'UnitPrice,'),(4,'EffectiveDate'),(5,'FROM'), (6,'Products'),(7,'WHERE'),(8,'UnitPrice'),(9,'> 100');
GO

CREATE VIEW for_xml_path_v1 AS SELECT String as param1, hello.String as [@param2] FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('hello')
GO

CREATE VIEW for_xml_path_v2 AS SELECT hello.String as [@param2] FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('')
GO

CREATE VIEW for_xml_path_v3 AS SELECT hello.String as [@param2] , string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH
GO

CREATE VIEW for_xml_path_v4 AS SELECT ' '+string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('')
GO

CREATE PROCEDURE for_xml_path_p1 AS SELECT  String as param1, hello.String as [@param2] FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('hello')
GO

CREATE PROCEDURE for_xml_path_p2 AS SELECT hello.String as [@param2] FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('')
GO

CREATE PROCEDURE for_xml_path_p3 AS SELECT hello.String as [@param2] , string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH
GO

CREATE PROCEDURE for_xml_path_p4 AS SELECT ' '+string  FROM for_xml_path hello ORDER BY SequenceNumber FOR XML PATH('')
GO