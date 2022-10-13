USE MASTER
GO

select object_id, count(*) from sys.all_objects group by object_id having count(*) > 1;
GO

select object_id, count(*) from sys.all_sql_modules group by object_id having count(*) > 1;
GO
