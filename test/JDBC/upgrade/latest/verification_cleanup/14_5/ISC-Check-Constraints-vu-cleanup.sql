drop table isc_check_constraints_t1
go

use isc_check_constraints_db1
go

drop table test_tsql_const
drop table test_datetime
drop table test_functioncall
drop table test_null
drop table test_tsql_collate
drop table test_tsql_cast
drop table test_upper
drop table test_null1
drop table test_null2
drop table test_udd
go

drop type sch1.udd_float
drop type sch1.udd_datetime
drop type sch1.udd_time
drop schema sch1
go

use master
GO

drop database isc_check_constraints_db1
go
