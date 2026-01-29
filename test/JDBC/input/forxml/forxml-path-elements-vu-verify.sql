SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee');
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 4 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 4 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

SELECT NULL AS Col1, NULL AS Col2 FOR XML PATH('row'), ELEMENTS XSINIL;
GO

SELECT NULL AS Col1, NULL AS Col2 FOR XML PATH('row'), ELEMENTS ABSENT;
GO

SELECT NULL AS Col1, NULL AS Col2 FOR XML PATH('row'), ELEMENTS;
GO

SELECT 1 AS ID, NULL AS Name, 'Active' AS Status FOR XML PATH('Record'), ELEMENTS XSINIL;
GO

SELECT 1 AS ID, NULL AS Name, 'Active' AS Status FOR XML PATH('Record'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL, ROOT('Data');
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT, ROOT('Data');
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH(''), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH(''), ELEMENTS ABSENT;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 WHERE IntCol = 100 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 WHERE IntCol IS NULL FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 WHERE Col1 IS NULL AND Col2 IS NULL AND Col3 IS NULL FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 WHERE Col1 IS NULL AND Col2 IS NULL AND Col3 IS NULL FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT ID, Name AS [@Name], Value FROM forxml_path_elements_t4 FOR XML PATH('Item'), ELEMENTS XSINIL;
GO

SELECT ID, Name AS [@Name], Value FROM forxml_path_elements_t4 FOR XML PATH('Item'), ELEMENTS ABSENT;
GO

SELECT SingleCol FROM forxml_path_elements_t5 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT SingleCol FROM forxml_path_elements_t5 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT SingleCol FROM forxml_path_elements_t5 WHERE SingleCol IS NULL FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT SingleCol FROM forxml_path_elements_t5 WHERE SingleCol IS NULL FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8 FROM forxml_path_elements_t6 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8 FROM forxml_path_elements_t6 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT ID, TextCol FROM forxml_path_elements_t7 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT ID, TextCol FROM forxml_path_elements_t7 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 999 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 999 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), TYPE, ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), TYPE, ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), TYPE, ELEMENTS XSINIL;
GO

SELECT * FROM forxml_path_elements_v1;
GO

SELECT * FROM forxml_path_elements_v2;
GO

SELECT * FROM forxml_path_elements_v3;
GO

SELECT * FROM forxml_path_elements_v4;
GO

SELECT * FROM forxml_path_elements_v5;
GO

SELECT * FROM forxml_path_elements_v6;
GO

EXEC forxml_path_elements_p1;
GO

EXEC forxml_path_elements_p2;
GO

EXEC forxml_path_elements_p3;
GO

EXEC forxml_path_elements_p4;
GO

EXEC forxml_path_elements_p5;
GO
