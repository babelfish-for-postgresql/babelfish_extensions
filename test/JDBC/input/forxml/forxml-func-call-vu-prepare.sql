create table forxml_func_call_vu_t_employees(
pers_id int,
fname nvarchar(20),
lname nvarchar(20),
sal money);
insert into forxml_func_call_vu_t_employees values (1, 'John', 'Johnson', 123.1234);
insert into forxml_func_call_vu_t_employees values (2, 'Max', 'Welch', 200.1234);
go

-- test internal functions for upgrade
create view forxml_vu_v_tsql_query_to_xml_sfunc as
select tsql_query_to_xml_sfunc(
	NULL,
	row,
	0,
	NULL,
	FALSE,
	NULL
)
FROM (SELECT TOP 1 * FROM forxml_func_call_vu_t_employees) row
go

CREATE VIEW forxml_vu_v_tsql_query_to_xml_ffunc AS
SELECT tsql_query_to_xml_ffunc(
	'<row />'
)
GO

CREATE VIEW forxml_vu_v_tsql_query_to_xml_text_ffunc AS
SELECT tsql_query_to_xml_text_ffunc(
	'<row />'
)
GO