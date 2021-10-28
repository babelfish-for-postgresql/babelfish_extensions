--
-- Tests for TOP clause
--

create table students (fname varchar(10), lname varchar(10), score double precision)
go

insert into students (fname, lname, score)
values
    ('John', 'Doe', 72.5),
    ('Jane', 'Smith', 88),
    ('Jill', 'Johnson', 98),
    ('Jack', 'Green', 67),
    ('Jennifer', 'Ross', 75.7),
    ('Jacob', 'Brown', 95.2)
go

select top 3 * from students
go

select top 4 score from students
go

select top 3 from students
go

-- test top bigint
select top 2147483648 * from students
go

-- test top 100 percent
select top 100 percent * from students
go

select top 100.00 percent lname from students
go

-- cleanup
drop table students
go