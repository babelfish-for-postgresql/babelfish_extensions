SELECT name, type, type_desc from sys.all_objects  where name like 'sys_all_objects_vu_prepare_1%' order by name;
GO

select * from sys.all_objects 
where object_id in 
(select object_id from sys.all_objects group by object_id having count(object_id) > 1);
GO