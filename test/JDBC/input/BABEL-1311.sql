create table babel_1311_t(c_w_id int, c_first int);
insert into babel_1311_t values (1, 1), (2, 2);
GO

DECLARE c_byname CURSOR STATIC FOR
SELECT customer.c_first
FROM babel_1311_t AS customer WITH (INDEX = [customer_i2], repeatableread)
INNER JOIN babel_1311_t AS C_BAL WITH (INDEX = [customer_i1], repeatableread)
ON C_BAL.c_w_id = customer.c_w_id;

DECLARE @var_c_w_id int;

OPEN c_byname;
FETCH c_byname into @var_c_w_id;
PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
FETCH c_byname into @var_c_w_id;
PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
CLOSE c_byname;
DEALLOCATE c_byname;
go

DECLARE cur1 cursor for ((((select c_w_id from babel_1311_t))));
DECLARE @var_c_w_id int;

OPEN cur1;
FETCH cur1 into @var_c_w_id;
PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
FETCH cur1 into @var_c_w_id;
PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
CLOSE cur1;
DEALLOCATE cur1;
go

DECLARE cur1 cursor for with cte_a as (select c_w_id from babel_1311_t where c_w_id = 2) select * from cte_a;
DECLARE @var_c_w_id int;

OPEN cur1;
FETCH cur1 into @var_c_w_id;
PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
CLOSE cur1;
DEALLOCATE cur1;
go

create procedure babel_1311_proc as
begin
  DECLARE c_byname CURSOR STATIC FOR
  SELECT customer.c_first
  FROM babel_1311_t AS customer WITH (INDEX = [customer_i2], repeatableread)
  INNER JOIN babel_1311_t AS C_BAL WITH (INDEX = [customer_i1], repeatableread)
  ON C_BAL.c_w_id = customer.c_w_id;

  DECLARE @var_c_w_id int;

  OPEN c_byname;
  FETCH c_byname into @var_c_w_id;
  PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
  FETCH c_byname into @var_c_w_id;
  PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
  CLOSE c_byname;
end;
go

exec babel_1311_proc;
go

create procedure babel_1311_proc_multiple_parethesis as
begin
  DECLARE cur1 cursor for ((((select c_w_id from babel_1311_t))));
  DECLARE @var_c_w_id int;

  OPEN cur1;
  FETCH cur1 into @var_c_w_id;
  PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
  FETCH cur1 into @var_c_w_id;
  PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
  CLOSE cur1;
end;
go

exec babel_1311_proc_multiple_parethesis;
go

create procedure babel_1311_proc_multiple_parethesis_mismatch1 as
begin
  DECLARE cur1 cursor for select c_w_id from babel_1311_t);
end;
go

create procedure babel_1311_proc_multiple_parethesis_mismatch2 as
begin
  DECLARE cur1 cursor for select (c_w_id from babel_1311_t));
end;
go

create procedure babel_1311_proc_with_clause as
begin
  DECLARE cur1 cursor for with cte_a as (select c_w_id from babel_1311_t where c_w_id = 2) select * from cte_a;
  DECLARE @var_c_w_id int;

  OPEN cur1;
  FETCH cur1 into @var_c_w_id;
  PRINT '@var_c_w_id: ' + cast(@var_c_w_id as varchar(10));
  CLOSE cur1;
end;
go

exec babel_1311_proc_with_clause;
go

drop procedure babel_1311_proc;
go
drop procedure babel_1311_proc_multiple_parethesis;
go
drop procedure babel_1311_proc_with_clause;
go

drop table babel_1311_t;
go
