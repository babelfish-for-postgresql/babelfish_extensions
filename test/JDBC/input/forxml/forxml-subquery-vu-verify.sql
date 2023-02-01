select * from forxml_subquery_vu_v_path
GO

select * from forxml_subquery_vu_v_base64
GO

SELECT * FROM forxml_subquery_vu_v_cte2;
GO

SELECT * FROM forxml_subquery_vu_v_cte3;
GO

SELECT * FROM forxml_subquery_vu_v_cte4;
GO

select * from forxml_subquery_vu_v_correlated_subquery;
go

-- BABEL-3569/BABEL-3690 return 0 rows for empty rowset
EXEC forxml_subquery_vu_p_empty
GO

SELECT @@rowcount
GO

-- exercise result internal functions
SELECT * FROM forxml_subquery_vu_v_internal
GO

SELECT * FROM forxml_subquery_vu_v_internal_text
GO