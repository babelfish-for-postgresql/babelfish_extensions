SELECT name, type, type_desc from sys.all_objects  where name like 'sys_all_objects_vu_prepare_1%' order by name;
GO

select case when object_id([name]) = object_id then 'equal' else 'not equal' end
from sys.all_objects where [name] = 'sys_all_objects_vu_prepare_1_3'
go