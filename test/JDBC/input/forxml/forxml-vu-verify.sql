

execute p_employee_select;
go

execute p_employee_select2 150, 300;
go

select * from forxml_vu_v1;
go

-- Test for xml on view with xml column
select * from forxml_vu_v1 for xml path;
go

select * from forxml_vu_v2 for xml path;
go

SELECT * FROM forxml_vu_v_cte1;
GO

SELECT * FROM forxml_vu_v_cte2;
GO

SELECT * FROM forxml_vu_v_cte3;
GO

SELECT * FROM forxml_vu_v_cte4;
GO

SELECT * FROM forxml_vu_v_with_where
GO

SELECT * FROM forxml_vu_v_with
GO

exec test_forxml_datalength 1;
go

exec test_forxml_strvar 1, 't1_a1';
go
-- test NULL parameter
-- TODO fix BABEL-3569 so this returns 0 rows
exec test_forxml_strvar 1, NULL;
go

select * from forxml_vu_v_correlated_subquery;
go