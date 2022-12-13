create table forjson_func_call_vu_t1 (x int)
insert into forjson_func_call_vu_t1 values (0),(1),(2)
go

-- Test internal functions
CREATE VIEW forjson_vu_v_sfunc_internal AS
SELECT tsql_query_to_json_sfunc(
	NULL,
	row,
	1,
	FALSE,
	FALSE,
	NULL
)
FROM (SELECT TOP 1 * FROM forjson_func_call_vu_t1) row
GO

CREATE VIEW forjson_vu_v_ffunc_internal AS
SELECT tsql_query_to_json_ffunc(
	'['
)
GO