create table trans2(id int identity(1,1) primary key, source int not null , target int not null, amount int );

insert into TRANS2 (source, amount, a, c ) values (1,1,1)
GO

ALTER TABLE trans2 ADD a int4 default 3;
GO

ALTER TABLE trans2 ADD b varchar;
GO

ALTER TABLE trans2 ADD c varchar(10) NOT null;
GO

ALTER TABLE trans2 ADD c varchar(10) NOT null;
GO

ALTER TABLE trans2 ADD c varchar(30) not null default 'aaa';
go

ALTER TABLE trans2 WITH NOCHECK ADD CONSTRAINT exd_check CHECK (source > 1) ;
GO

ALTER TABLE trans2 ADD CONSTRAINT col_b_def DEFAULT 50 FOR target ;
GO

insert into TRANS2 (source, amount, a, c ) values (3,1,1,'ddd')
GO

ALTER TABLE trans2 ADD AddDate smalldatetime NULL CONSTRAINT AddDateDflt DEFAULT GETDATE() with values ;
GO

ALTER TABLE trans2 ADD AddDate smalldatetime NULL CONSTRAINT AddDateDflt DEFAULT GETDATE() ;
GO

alter table trans2 add unique (source asc);
GO

insert into TRANS2 (source, amount, a, c ) values (3,1,1,'ddd')
GO

ALTER TABLE trans2 DROP COLUMN AddDate
GO

drop table trans2
GO