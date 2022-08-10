-- Numeric testcase for precision overflow triggers known protocol violation
CREATE TABLE overflow_test (amount numeric(38, 0));
go

-- sum(38 9's + 1) -> should cause arithmetic overflow
INSERT INTO overflow_test VALUES(99999999999999999999999999999999999999);
go

SELECT amount + 1 from overflow_test;
go

SELECT amount * 10 from overflow_test;
go

INSERT INTO overflow_test VALUES(1);
go

SELECT sum(amount) from overflow_test;
go

SELECT avg(amount) from overflow_test;
go

DROP TABLE overflow_test;
go

CREATE TABLE overflow_test (amount numeric(38, 5));
go

INSERT INTO overflow_test VALUES(999999999999999999999999999999999.99999);
go

INSERT INTO overflow_test VALUES(.00001);
go

SELECT sum(amount) from overflow_test;
go

DROP TABLE overflow_test;
go

-- 39 9's
select CAST(999999999999999999999999999999999999999 AS NUMERIC);
go

create table num_t1(a varchar(39));
go

-- 39 9's
insert into num_t1 values (999999999999999999999999999999999999999);
go

select cast(a as numeric) from num_t1;
go

drop table num_t1;
go

-- BABEL-3450 (Zero produced as result of numeric operation is causing crash)
create table num_zero(a numeric(5, 2));
go

insert into num_zero values(123.45);
go

insert into num_zero values(-123.45);
go

select sum(a) from num_zero;
go

drop table num_zero;
go
