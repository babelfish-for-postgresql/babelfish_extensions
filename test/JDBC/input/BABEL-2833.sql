use master;
go

-- uppercase schema name
create schema S2833;
go

select count(*) from (select schema_id('S2833') i) t where i is not null;
go

select count(*) from (select schema_id('s2833') i) t where i is not null;
go

drop schema S2833;
go

-- lowercase schema name
create schema s2833;
go

select count(*) from (select schema_id('S2833') i) t where i is not null;
go

select count(*) from (select schema_id('s2833') i) t where i is not null;
go

drop schema s2833;
go

-- long schema name
create schema S2833_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG;
go

select count(*) from (select schema_id('S2833_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG') i) t where i is not null;
go

select count(*) from (select schema_id('s2833_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong') i) t where i is not null;
go

drop schema S2833_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG;
go

create schema s2833_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong;
go

select count(*) from (select schema_id('S2833_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG_THISISLONG') i) t where i is not null;
go

select count(*) from (select schema_id('s2833_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong') i) t where i is not null;
go

drop schema s2833_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong_thisislong;
go
