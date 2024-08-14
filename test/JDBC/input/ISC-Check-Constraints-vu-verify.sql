select length(tsql_get_constraintdef(oid)) from pg_constraint where contype='c' and conrelid = (select oid from pg_class where relname='isc_check_constraints_t1');
go

-- The check constraint defnition only shows upto 4000 number of characters.
select "CONSTRAINT_NAME","CHECK_CLAUSE", length("CHECK_CLAUSE") from information_schema.check_constraints where "CONSTRAINT_NAME" = 'isc_check_constraints_t1_a_check';
go

use isc_check_constraints_db1;
go

select * from information_schema.check_constraints order by "CONSTRAINT_NAME","CHECK_CLAUSE";
go

use master
go

select * from information_schema.check_constraints where "CONSTRAINT_NAME" = 'isc_check_constraints_t1_a_check' order by "CONSTRAINT_NAME";
go