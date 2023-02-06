

execute forxml_vu_p_employee_select;
go

execute forxml_vu_p_employee_select2 150, 300;
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

SELECT * FROM forxml_vu_v_with_where
GO

SELECT * FROM forxml_vu_v_with
GO

exec forxml_vu_p_datalength 1;
go

exec forxml_vu_p_strvar 1, 't1_a1';
go
-- test NULL parameter
exec forxml_vu_p_strvar 1, NULL;
go