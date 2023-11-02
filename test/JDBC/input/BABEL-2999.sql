drop table if exists t1_BABEL2999;
GO

create table t1_BABEL2999(b varchar(10));
GO

insert into t1_BABEL2999 exec('Select ''5''');
GO

insert into t1_BABEL2999 exec('Select 5');
GO

insert into t1_BABEL2999 exec('Select ''5''');
GO

insert into t1_BABEL2999 exec('Select ''hello''');
GO

insert into t1 exec('SELECT ''helloworld''');
GO

insert into t1 exec('SELECT ''helloworldhello''');
GO

select b from t1_BABEL2999 order by b;
GO

drop table if exists t2_BABEL2999;
GO

create table t2_BABEL2999(b int);
GO

insert into t2_BABEL2999 exec('Select ''5'''); -- varchar to int
GO

insert into t2_BABEL2999 exec('Select 5');  -- int to int
GO

insert into t2_BABEL2999 SELECT '5'; 
GO

select b from t2_BABEL2999 order by b;
GO

create table t3_BABEL2999(b varchar);
GO

insert into t3_BABEL2999 exec('Select ''5''');
GO

insert into t3_BABEL2999 exec('Select 5');
GO

insert into t3_BABEL2999 exec('Select ''5''');
GO

select b from t3_BABEL2999 order by b;
GO

create table t4_BABEL2999(a int, b datetime, c varchar(20))
GO

insert t4_BABEL2999 exec('select ''123'', 123, 123')
GO

insert t4_BABEL2999 exec('select 123, ''123'', 123')
GO

insert t4_BABEL2999 exec('select 123, 123, ''123''')
GO

select a,b,c from t4_BABEL2999 order by a;
GO

create table t5_BABEL2999(a datetime, b varchar(20))
GO

insert t5_BABEL2999 exec('select 123, 123')
GO

select a,b from t5_BABEL2999 order by a;
GO

drop table t1_BABEL2999;
GO

drop table t2_BABEL2999;
GO

drop table t3_BABEL2999;
GO

drop table t4_BABEL2999;
GO

drop table t5_BABEL2999;
GO

 
CREATE procedure [dbo].[test_hhit_outer]
( @testvar int )
as
set nocount on;
set xact_abort on;
exec dbo.[test_hhit_inner] @testvar
return
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[test_hhit_inner] 
( @testvar int )
as
set nocount on;
set xact_abort on;
declare @orderingTable table (a varchar(100))
insert into @orderingTable
exec  [test_hhit_inner_2]  @testvar=999
select * from @orderingTable
return
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
CREATE procedure [dbo].[test_hhit_inner_2] 
(@testvar int)
 as
set nocount on;
set xact_abort on;
select 'hello'; 
return
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
--Store Proc Call
 
exec dbo.test_hhit_outer @testvar=200
GO

drop procedure test_hhit_inner
GO

drop procedure test_hhit_inner_2
GO

drop procedure test_hhit_outer
GO