-- Tests for OUTPUT with INSERT statement --
create table t1(num integer, word varchar(10));
go
 
insert into t1 output inserted.num values(1, 'one');
go
 
insert into t1 output inserted.num, inserted.word values(2, 'two');
go
 
insert into t1 output inserted.* values(3, 'three');
go
 
select * from t1;
go
 
-- Test conflict case with table name
create table inserted(num integer);
go
 
insert into inserted output inserted.* values(10);
go
 
-- Tests for OUTPUT with DELETE statement --
delete t1 output deleted.num where num=1;
go
 
delete t1 output deleted.num, deleted.word where word='two';
go
 
delete t1 output deleted.* where num=3;
go
 
select * from t1;
go
 
-- Test conflict cases with table name
create table deleted(num integer, nextnum integer);
go
 
insert into deleted values(10, 11), (12, 13), (14,15);
go
 
insert into t1 values(10, 'ten'), (12, 'twelve'), (14, 'fourteen');
go
 
delete deleted
output deleted.num
from deleted
inner join t1
 on deleted.num=t1.num
where t1.num=10;
go
 
delete deleted
output deleted.nextnum
from deleted
inner join t1
 on deleted.num=t1.num
where t1.num=12;
go
 
delete t1
output t1.word
from t1
inner join deleted
 on t1.num=deleted.num
where t1.num=14;
go
 
select * from deleted;
go
 
select * from t1;
go
 
-- Cleanup
drop table t1;
go
 
drop table inserted;
go
 
drop table deleted;
go

-- Tests for OUTPUT INTO with INSERT statement --
create table t1(num integer, word varchar(10));
go

create table t2(num integer, word varchar(10));
go

insert into t1(num, word)
    output inserted.num, inserted.word into t2
values(1, 'one');
go

select * from t1;
go

select * from t2;
go

create table t3(num integer, word varchar(10));
go

with cte(num, word) as(
    select num, word from t1
)
insert into t2(num, word)
    output inserted.num, inserted.word into t3
select num, word from cte;
go

select * from t3;
go

-- Test recursive CTE case
create table t4(num integer);
go

create table t5(num integer);
go

with Numbers as 
(
   select 1 as n
   union all
   select n + 1 from Numbers where n + 1 <= 10
)
insert into t4(num)
output num into t5
select n from Numbers;
go

select * from t4;
go

-- Cleanup
drop table t1;
go

drop table t2;
go

drop table t3;
go

drop table t4;
go

drop table t5;
go

-- Tests for OUTPUT INTO with DELETE statement --
create table t1(num integer, word varchar(10));
go

insert into t1 values(1, 'one'), (2, 'two'), (3, 'three'), (4, 'four');
go

create table t1_insert(num integer, word varchar(10));
go

delete t1 
output deleted.* into t1_insert
where num < 4;
go

create table t2(num integer, word varchar(10));
go

insert into t1 values(1, 'one'), (2, 'two'), (3, 'three');
go

select * from t1;
go

select * from t1_insert;
go

delete from t1_insert
output deleted.num, deleted.word into t2
where num in (
  select num from t1);
go

select * from t1_insert;
go

select * from t2;
go

create table inserted(num integer);
go

insert into inserted output inserted.* values(10);
go

create table deleted(num integer, nextnum integer);
go

insert into deleted values(10, 11);
go

insert into t1 values(10, 'ten');
go

delete deleted
output deleted.num into inserted
from deleted
inner join t1
 on deleted.num=t1.num
where t1.num=10;
go

select * from deleted;
go

select * from t1;
go

-- Cleanup
drop table t1;
go

drop table t1_insert;
go

drop table t2;
go

drop table inserted;
go

drop table deleted;
go

-- Tests for OUTPUT with UPDATE statement --
create table t1(a integer);
go

insert into t1(a) values (1),(2);
go

update t1 set a=20
output deleted.a, inserted.a
where a>1;
go

update t1 set a=30
output deleted.a, inserted.a;
go

-- Test that order of execution of AND and OR in where clause is preserved
create table t2(a integer, b integer, c integer, d integer);
go

insert into t2 values(1,2,3,4), (5,6,7,8), (4,2,6,1), (8,9,0,3);
go

update t2 set a=25 output deleted.*
where a>2 and b<20 or c>5 and d>0;
go

create table table1 (age integer, fname varchar(100), year integer);
        insert into table1 (age, fname, year) values (10, 'albert', 30);
        insert into table1 (age, fname, year) values (100, 'isaac', 40);
        insert into table1 (age, fname, year) values (30, 'marie', 70);
        select * from table1;
go
        
create table table2 (age integer, fname varchar(100), lastname varchar(100));
        insert into table2 (age, fname, lastname) values (10, 'albert', 'einstein');
        insert into table2 (age, fname, lastname) values (100, 'isaac', 'newton');
        insert into table2 (age, fname, lastname) values (30, 'mary', 'kom');
        select * from table2;
go

update table1 set age=1 output deleted.age
from table1 t1
left join table2 t2
on t1.fname=t2.fname where year>50 and lastname!='smith';
go

update table1 set age=1 output deleted.age
from table1 t1
left join table2 t2
on t1.fname=t2.fname where year>50;
go

update table1 set year=1990 output deleted.*, inserted.*
from table1 t1
left join table2 t2
on t1.fname=t2.fname where t1.fname='isaac';

update table1 set year=2020 output deleted.*
from table2 t2
where table1.fname=t2.fname and lastname='einstein';
go

-- Cleanup
drop table t1;
go

drop table t2;
go

drop table table1;
go

drop table table2;
go

-- Tests for OUTPUT INTO with UPDATE statement --
create table t1(a integer);
go

create table t1_insert(a integer);
go

insert into t1(a) values (1),(2);
go

update t1 set a=20
output deleted.a into t1_insert
where a>1;
go

select * from t1_insert;
go

update t1 set a=30
output inserted.a into t1_insert;
go

select * from t1_insert;
go

-- Test that order of execution of AND and OR in where clause is preserved
create table t2(a integer, b integer, c integer, d integer);
go

create table t2_insert(a integer, b integer, c integer, d integer);
go

insert into t2 values(1,2,3,4), (5,6,7,8), (4,2,6,1), (8,9,0,3);
go

update t2 set a=25 output deleted.* into t2_insert
where a>2 and b<20 or c>5 and d>0;
go

select * from t2_insert;
go

create table table1 (age integer, fname varchar(100), year integer);
        insert into table1 (age, fname, year) values (10, 'albert', 30);
        insert into table1 (age, fname, year) values (100, 'isaac', 40);
        insert into table1 (age, fname, year) values (30, 'marie', 70);
        select * from table1;
go
        
create table table2 (age integer, fname varchar(100), lastname varchar(100));
        insert into table2 (age, fname, lastname) values (10, 'albert', 'einstein');
        insert into table2 (age, fname, lastname) values (100, 'isaac', 'newton');
        insert into table2 (age, fname, lastname) values (30, 'mary', 'kom');
        select * from table2;
go

create table table_insert (age integer, fname varchar(100), year integer);
go

update table1 set age=1
output deleted.age, inserted.fname, inserted.year into table_insert
from table1 t1
left join table2 t2
on t1.fname=t2.fname where year>50 and lastname!='smith';
go

select * from table_insert;
go

update table1 set age=1
output deleted.age, inserted.fname, inserted.year into table_insert
from table1 t1
left join table2 t2
on t1.fname=t2.fname where year>50;
go

select * from table_insert;
go

update table1 set year=1990 output deleted.*, inserted.*
from table1 t1
left join table2 t2
on t1.fname=t2.fname where t1.fname='isaac';

select * from table_insert;
go

update table1 set year=2020 output deleted.*
from table2 t2
where table1.fname=t2.fname and lastname='einstein';
go

select * from table_insert;

-- Cleanup
drop table t1;
go

drop table t1_insert;
go

drop table t2;
go

drop table t2_insert;
go

drop table table1;
go

drop table table2;
go

drop table table_insert;
go

-- Tests for order of execution of OUTPUT clause --
create table t1 (age integer, fname varchar(20), year integer);
go

create trigger t1_insert_trig on t1 for insert as
begin
    update t1 set age = 99;
end;
go

insert into t1 output inserted.* values (21, 'Amanda', 2000);
go

select * from t1;
go

drop trigger t1_insert_trig;
go

create trigger t1_update_trig on t1 for update as
begin
    delete t1;
end;
go

update t1 set fname = 'Lucy'
output deleted.fname, inserted.fname
where fname = 'Amanda';
go

select * from t1;
go

insert into t1 values (21, 'Amanda', 2000);
go

drop trigger t1_update_trig;
go

create trigger t1_delete_trig on t1 for delete as
begin
    insert into t1 values (22, 'Tracy', 1998)
end;
go

delete t1 output deleted.year;
go

select * from t1;
go

drop trigger t1_delete_trig
go

-- Cleanup
drop table t1;
go

-- Tests for NULL in output target list (BABEL-1768) --
create table t1(age integer, fname varchar(100));
create table t2(age integer, fname varchar(100), lname varchar(100));
go

insert into t1 
   output inserted.age, inserted.fname, null into t2
values(10, 'albert');
go

select * from t1;
go

select * from t2;
go

update t2 set age=20
  output deleted.age, null into t1
where age=10;
go

select * from t2;
go

select * from t1;
go

delete t1
output deleted.age, deleted.fname, null;
go

select * from t1;
go

-- Cleanup
drop table t1;
go

drop table t2;
go

-- Tests for column names for target table in OUTPUT INTO (BABEL-1769) --
create table t1(num integer, word varchar(10));
go

create table t2(num integer, word varchar(10), next_num integer);
go

create table t3(prev_word varchar(10), random_number integer);
go

insert into t1
output inserted.num, inserted.word into t2(num, word)
values(1, 'one');
go

select * from t1;
go

select * from t2;
go

update t1 set word='one unit'
output deleted.word into t3(prev_word)
where num=1;
go

select * from t1;
go

select * from t3;
go

delete t2
output deleted.num into t1(num);
go

select * from t2;
go

select * from t1;
go

-- Cleanup
drop table t1;
go

drop table t2;
go

drop table t3;
go


-- Test OUTPUT with temp tables --
create table non_temp_tbl(fname varchar(10), lname varchar(10), age integer, score decimal);
create table #temp_tbl(fname varchar(10), lname varchar(10), age integer, score decimal);
go

insert into non_temp_tbl
output inserted.* into #temp_tbl
values ('kelly', 'slater', 40, 100), ('john', 'cena', 50, 78);
go

select * from non_temp_tbl;
go

select * from #temp_tbl;
go

update #temp_tbl set score=0
output inserted.* into non_temp_tbl
where age=40;
go

select * from #temp_tbl;
go

select * from non_temp_tbl;
go

-- Test OUTPUT with triggers --
delete non_temp_tbl;
go

delete #temp_tbl;
go

create trigger insert_output_trig on non_temp_tbl for insert
as
begin
update non_temp_tbl set age=-1
output inserted.*, deleted.*
end;
go

insert into non_temp_tbl values ('joey', 'tribbiani', 45, 99);
go

drop trigger insert_output_trig;
go

create trigger update_output_trig on non_temp_tbl for update
as
begin
insert into non_temp_tbl
output inserted.* into #temp_tbl
values ('joni', 'mitchell', 80, 0)
end;
go

update non_temp_tbl set lname='morgan'
where age=-1;
go

select * from non_temp_tbl;
go

select * from #temp_tbl;
go

-- Cleanup
drop table #temp_tbl;
go

drop table non_temp_tbl;
go

-- Test OUTPUT with procedures --
create table t1(num integer, word varchar(10));
create table t2(num integer, word varchar(10));
go

create procedure output_insert_proc as
begin
insert into t1 output inserted.* into t2 values(1, 'one');
end;
go

exec output_insert_proc;
go

select * from t1;
go

select * from t2;
go

create procedure output_update_proc as
begin
update t1 set num=100 output inserted.*, deleted.* where num=1;
end;
go

exec output_update_proc;
go

select * from t1;
go

create procedure output_delete_proc as
begin
delete t1 output deleted.*;
end;
go

exec output_delete_proc;
go

select * from t1;
go

-- Cleanup 
drop procedure output_insert_proc;
go

drop procedure output_update_proc;
go

drop procedure output_delete_proc;
go

drop table t1;
go

drop table t2;
go

-- [BABEL-1921] Test OUTPUT with functions and expressions --
create table t1(num integer, word varchar(10));
go

create table t2(num integer, word varchar(10));
go

create table t3(str varchar(20));
go

insert into t1 output inserted.num+2 values(1, 'one');
go

select * from t1;
go

insert into t1 output round(inserted.num)+1, 'sum' into t2 values(2, 'two');
go

select * from t1;
go

select * from t2;
go

insert into t1 values (3, 'three'), (4, 'four'), (5, 'five');
go

select * from t1;
go

update t1 set word = 'one unit' output concat(inserted.word, '_old') where num = 1;
go

select * from t1;
go

update t1 set word = 'two units' 
    output concat(inserted.word, '_old') into t3
where num = 2 and word = 'two';
go

select * from t1;
go

select * from t3;
go

delete t1 output round(deleted.num)+5 where num = 3;
go

select * from t1;
go

delete t1 output concat(deleted.word, '_old') into t3 where num = 4;
go

select * from t1;
go

select * from t3;
go

-- Test nested functions
insert into t1 output round(floor(inserted.num)) values (6, 'six'), (7, 'seven'), (8, 'eight'), (9, 'nine');
go

select * from t1;
go

-- Cleanup 
drop table t1;
go

drop table t2;
go

drop table t3;
go

-- Test that order by is working --
create table t1(num integer, word varchar(10));
go

create table t2(num integer, word varchar(10));
go

insert into t1 values(2, 'two'), (1, 'one'), (3, 'three');
go

insert into t2 select * from t1 order by num;
go

select * from t2;
go

select * from t1;
go

-- Cleanup
drop table t1;
go

drop table t2;
go

-- [BABEL-1901] Test specific cases that trigger ambiguous column errors
create table t1(num integer, word varchar(10));
go

create table t2(prev_word varchar(10), new_word varchar(10));
go

insert into t1 values(1, 'one');
go

-- output deleted, inserted of same column into table
update t1 set word='one unit'
output deleted.word, inserted.word into t2(prev_word, new_word)
where num=1;
go

select * from t1;
go

select * from t2;
go

delete t1;
go

drop table t2;
go

create table t2(num integer, word varchar(10));
go

insert into t1 values(1, 'one'), (2, 'two'), (3, 'three'), (4, 'four'), (5, 'five');
go

-- delete with top
delete top 2 t1
output deleted.* into t2
where num<5;
go

select * from t1;
go

select * from t2;
go

-- delete with top in subquery
delete t1
output deleted.num, deleted.word into t2
from (select top 2 * from t1 order by num asc) as x
where t1.num = x.num and t1.num<5;
go

select * from t1;
go

select * from t2;
go

drop table t1;
go

drop table t2;
go

CREATE TABLE t1(
	c1PK INT PRIMARY KEY
	, c2INT INT NOT NULL
	, c3STR VARCHAR(50) NOT NULL
	, c4COMMENT VARCHAR(100) NOT NULL
)
go
CREATE TABLE HISTORY(
	c4BEFORE VARCHAR(100) NOT NULL
	, c4AFTER VARCHAR(100) NOT NULL
)
go
INSERT INTO t1 VALUES( 1, 10, 'filler1', 'vanilla insert' )
go

UPDATE t1
SET c4COMMENT = 'updated: output to table'
OUTPUT DELETED.c4COMMENT, INSERTED.c4COMMENT INTO HISTORY
WHERE c1PK = 1
go

SELECT * FROM t1;
go

SELECT * FROM HISTORY;
go

DROP TABLE t1
go
DROP TABLE HISTORY
go

CREATE TABLE t1(
	c1PK INT PRIMARY KEY
	, c2INT INT NOT NULL
	, c3STR VARCHAR(50)	NOT NULL
	, c4COMMENT VARCHAR(100) NOT NULL
);
go
CREATE TABLE t2(
	c1PK INT PRIMARY KEY
	, c2INT INT NOT NULL
	, c3STR VARCHAR(50) NOT NULL
	, c4COMMENT VARCHAR(100) NOT NULL
);
go
CREATE TABLE HISTORY(
	c1PK INT PRIMARY KEY
	, c2INT INT NOT NULL
	, c3BEFORE VARCHAR(100) NOT NULL
	, c4AFTER VARCHAR(100) NOT NULL
);
go
INSERT INTO t1 VALUES( 1, 10, 'filler1', 'vanilla insert' );
go
INSERT INTO t1 VALUES( 2, 20, 'filler2', 'vanilla insert' );
go
INSERT INTO t2 VALUES( 1, 10, 'filler1', 'vanilla insert' );
go
INSERT INTO t2 VALUES( 2, 20, 'filler2', 'vanilla insert' );
go

DELETE FROM t1
OUTPUT DELETED.c1PK, DELETED.c2INT, DELETED.c3STR, DELETED.c4COMMENT INTO HISTORY
FROM t2 table2
WHERE t1.c1PK = 2
AND t1.c2INT = table2.c2INT;
go

SELECT * FROM t1
go

SELECT * FROM HISTORY
go

DROP TABLE t1;
go
DROP TABLE t2;
go
DROP TABLE HISTORY;
go

CREATE TABLE t1(
	c1PK INT PRIMARY KEY
	, c2INT INT NOT NULL
	, c3STR VARCHAR(50) NOT NULL
	, c4COMMENT VARCHAR(100) NOT NULL
)
go
CREATE TABLE t2(
	c1PK INT PRIMARY KEY
	, c2INT INT NOT NULL
	, c3STR VARCHAR(50) NOT NULL
	, c4COMMENT VARCHAR(100) NOT NULL
)
go
CREATE TABLE trigger_history(
    c1OPS CHAR(3) NOT NULL
    , c2PK INT NOT NULL
    , c3INT INT NOT NULL
    , c4COMMENT VARCHAR(100) NOT NULL
    , c5ROWS INT NOT NULL
	, c6SRCTABLE VARCHAR(20) NOT NULL
)
go

CREATE TRIGGER t1_ins
ON t1
AFTER INSERT
AS
DECLARE @rows INT = @@rowcount
PRINT '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>     INSERT TRIGGER ON t1     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
INSERT INTO t2
OUTPUT 'INS', INSERTED.c1PK, INSERTED.c2INT, INSERTED.c4COMMENT, @rows, 't1' INTO trigger_history( c1OPS, c2PK, c3INT, c4COMMENT, c5ROWS, c6SRCTABLE )
SELECT INSERTED.c1PK, INSERTED.c2INT, INSERTED.c3STR, INSERTED.c4COMMENT FROM INSERTED
PRINT '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>     TRIGGER DONE     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<'
RETURN
go

INSERT INTO t1 VALUES( 1, 10, 'filler1', 'vanilla insert' )
go

SELECT * from t2
go

-- The value of c5ROWS needs to be changed when BABEL-2208 is fixed
SELECT * from trigger_history
go

-- Cleanup
DROP TRIGGER t1_ins
go
DROP TABLE trigger_history
go
DROP TABLE t1
go
DROP TABLE t2
go


-- [BABEL-2522] Test specific cases that trigger ambiguous column errors
CREATE TABLE dml_table(
        c1PK    INT     PRIMARY KEY
        , c2FLOAT       FLOAT   NOT NULL
)
go

CREATE TABLE output_FLOAT(
        c1INT   INT     PRIMARY KEY
        , c2FLOAT   FLOAT   NULL
)
go

INSERT INTO dml_table
OUTPUT INSERTED.c1PK, INSERTED.c1PK / 21 INTO output_FLOAT( c1INT, c2FLOAT )
VALUES ( 4, 4567.890 )
go

SELECT * FROM dml_table
go

SELECT * from output_FLOAT
go

DELETE output_FLOAT
go

UPDATE dml_table SET c1PK = 5
OUTPUT DELETED.c1PK, INSERTED.c1PK + DELETED.c1PK INTO output_FLOAT( c1INT, c2FLOAT )
WHERE c1PK = 4
go

SELECT * FROM dml_table
go

SELECT * FROM output_FLOAT
go

-- Cleanup
DROP TABLE dml_table
go

DROP TABLE output_FLOAT
go

-- Test OUTPUT with table variables --
create table test_tbl(fname varchar(10), lname varchar(10), age integer, score decimal);
declare @tbl_var table(fname varchar(10), lname varchar(10), age integer, score decimal);

insert into test_tbl
output inserted.* into @tbl_var
values ('kelly', 'slater', 40, 100), ('john', 'cena', 50, 78);

update @tbl_var set score=0
output inserted.* into test_tbl
where age=40;

select * from @tbl_var;
go

select * from test_tbl;
go

-- Cleanup
DROP TABLE test_tbl;

-- Test OUTPUT with default column --
CREATE TABLE #testdef
(
        c2 uniqueidentifier
        ,c4 varchar(10) DEFAULT 'Hello')

DECLARE @uq table(uq uniqueidentifier)

INSERT #testdef(c2)
OUTPUT inserted.c2 INTO @uq
VALUES('0A0EA68C-864E-45B7-9ABE-DFFA2D8EFCC5')

SELECT uq FROM @uq
go

CREATE TABLE t1(
    a int, 
    b int default 1, 
    c int default 2 )

INSERT INTO t1(a,b) VALUES (1, 2)
go

SELECT * FROM t1
go

-- Cleanup
drop table #testdef;
go
drop table t1;
go

-- Test OUTPUT INTO with a table with NULL column --

CREATE TABLE [dbo].[t1]
(
    [Id] [int] NOT NULL IDENTITY(1, 1),
    [Name] [varchar] (100)  NOT NULL,
    [Desc] [varchar] (32)  NULL,
) 
go

DECLARE @t2 TABLE (Id INT, Name VARCHAR(50))

INSERT INTO dbo.t1 (Name)
OUTPUT Inserted.Id, Inserted.Name INTO @t2
VALUES ('abc')

SELECT * FROM @t2
go

SELECT * FROM dbo.t1
go

-- Cleanup --
drop table t1
go

-- Test that a local variable at the beginning of OUTPUT INTO list works properly -- 
CREATE TABLE t1 (
      id                 integer       NOT NULL,
      fname              varchar(128)  NOT NULL,
      lname              varchar(128)      NULL,
      age                integer       NOT NULL,
      preferredname      AS (fname),
      CONSTRAINT pk_t1 PRIMARY KEY (
         id,
         lname
        )
);

CREATE TABLE #t2 (
      operation          varchar(128),
      gender             varchar(1),
      id                 integer       NOT NULL,
      fname              varchar(128)  NOT NULL,
      lname              varchar(128)      NULL,
      age                integer       NOT NULL,
      preferredname      varchar(128)
);


INSERT INTO t1 VALUES (
    1,
    'john',
    'doe',
    28
);

DECLARE @str_operation VARCHAR(8);
SET @str_operation    = 'DELETE';

DECLARE @str_gender VARCHAR(1);
SET @str_gender  = 'M';

DELETE t1
OUTPUT @str_operation, @str_gender, deleted.id, deleted.fname, deleted.lname, 
        deleted.age, deleted.preferredname
INTO #t2
WHERE 1=1;

SELECT * FROM t1;
SELECT * FROM #t2;
go

-- Cleanup
DROP TABLE t1;
go

DROP TABLE #t2;
go