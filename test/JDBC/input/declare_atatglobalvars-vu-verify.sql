declare @@cursor_rows int
go
declare @@datefirst int
go
declare @@DBTS int
go
declare @@error int
go
declare @@pgerror int
go
declare @@fetch_status int
go
declare @@IDENTITY int
go
declare @@language varchar(100)
go
declare @@LOCK_TIMEOUT int
go
declare @@max_connections int
go
declare @@max_precision int
go
declare @@nestlevel int
go
declare @@options int
go
declare @@procid int
go
declare @@rowcount int
go
declare @@servername varchar(100)
go
declare @@servicename varchar(100)
go
declare @@spid int
go
declare @@trancount int
go
declare @@version varchar(100)
go
declare @@microsoftversion int
go
declare @@connections int
go
declare @@cpu_busy int
go
declare @@idle int
go
declare @@io_busy int
go
declare @@langid int
go
declare @@packet_errors int
go
declare @@pack_received int
go
declare @@pack_sent int
go
declare @@remserver varchar(100)
go
declare @@textsize int
go
declare @@timeticks int
go
declare @@total_errors int
go
declare @@total_read int
go
declare @@total_write int
go


declare @@myvar int, @@spid int
go
declare @@spid table(a int)
go

create procedure p1_declare_atatglobalvars
as
declare @@spid int=123
select @@spid
go
create procedure p1_declare_atatglobalvars
as
declare @@DATEFIRST int=123
select @@datefirst
go
create procedure p1_declare_atatglobalvars
as
declare @@myvar int=123, @@nestlevel int=123
select @@nestlevel
go

create procedure p1_declare_atatglobalvars
@@identity int
as
return 0
go

create procedure p1_declare_atatglobalvars
@@myparam int, @@options int = -1, @@myparam2 int
as
return 0
go

create procedure p1_declare_atatglobalvars 
@@dbts tt_declare_atatglobalvars readonly
as
return 0
go

create function f1_declare_atatglobalvars() 
returns int 
as 
begin
declare @@max_precision int
return 0 
end
go

create function f1_declare_atatglobalvars() 
returns int 
as 
begin
declare @@myvar int=123, @@max_precision int
return 0 
end
go

create function f1_declare_atatglobalvars(@@fetch_status int) 
returns int 
as 
begin 
return 0 
end
go

create function f1_declare_atatglobalvars(@@myparam int, @@fetch_status int, @@myparam2 int) 
returns int 
as 
begin 
return 0 
end
go

create function f1_declare_atatglobalvars() 
returns @@rowcount table(a int)
as begin 
return 
end
go

create trigger tr1 on t1_declare_atatglobalvars for insert
as
begin
declare @@procid int
end
go

create trigger tr1 on t1_declare_atatglobalvars for insert
as
begin
declare @@myvar int, @@procid int, @@myvar2 int
end
go

-- verify @@rowcount etc. still work orrectly (NB. this is just a brief test, other test cases already exist for these)
select a from t1_declare_atatglobalvars order by a
select @@rowcount as rc, @@nestlevel as nl, @@trancount as tc, @@error as err, @@pgerror as pgerr
go

create procedure p2_declare_atatglobalvars
as
select a from t1_declare_atatglobalvars order by a
select @@rowcount as rc, @@nestlevel as nl, @@trancount as tc, @@error as err, @@pgerror as pgerr
go
exec p2_declare_atatglobalvars
go
begin tran
exec p2_declare_atatglobalvars
rollback
go

-- non-zero @@PGERROR:
select 1/0
go
select @@error as err, @@pgerror as pgerr
go

create procedure p3_declare_atatglobalvars @@myparam int
as
select @@myparam
go
exec p3_declare_atatglobalvars @@max_precision
go
exec p3_declare_atatglobalvars @@myparam=@@max_precision
go

create function f2_declare_atatglobalvars(@@myparam int) 
returns int 
as 
begin 
return @@myparam
end
go
select dbo.f2_declare_atatglobalvars(@@max_precision)
go

declare @@pgerror2 int=123 select @@pgerror2
go
declare @@spid_ int=123 select @@spid_
go
