-- Test BASE64 encoding on binary data
CREATE TABLE forxml_after_14_5_t_binary (Col1 int PRIMARY KEY, Col2 binary);
INSERT INTO forxml_after_14_5_t_binary VALUES (1, 0x7);
GO

create view forxml_after_14_5_v_path as
SELECT Col1, CAST(Col2 as image) as Col2 FROM forxml_after_14_5_t_binary FOR XML PATH;
GO

create view forxml_after_14_5_v_base64 as
SELECT Col1, CAST(Col2 as image) as Col2 FROM forxml_after_14_5_t_binary FOR XML PATH, BINARY BASE64;
GO