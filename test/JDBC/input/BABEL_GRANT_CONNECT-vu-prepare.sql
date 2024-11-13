create database grant_connect_db1;
go

use grant_connect_db1;
go

create table grant_connect_t1(a int);
go

create login grant_connect_abc with password = 'Babel123'
go
