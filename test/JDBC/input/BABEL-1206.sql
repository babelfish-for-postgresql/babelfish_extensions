-- BABEL-1265
create table babel_1265_t1 (a varbinary(8), b varbinary(8));
go
insert into babel_1265_t1 values (0xaaa, 0xbbb);
go
select (case when a<b then 1 else 0 end) r from babel_1265_t1;
go
select (case when a<=b then 1 else 0 end) r from babel_1265_t1;
go
select (case when a=b then 1 else 0 end) r from babel_1265_t1;
go
select (case when a>b then 1 else 0 end) r from babel_1265_t1;
go
select (case when a>=b then 1 else 0 end) r from babel_1265_t1;
go

-- BABEL-1206 actual scenarios
CREATE TABLE babel_1206_t1(
  [Login] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
  [PasswordSHA1] varbinary(20) NOT NULL DEFAULT ((0)),
  [UserLicenseKey] int NOT NULL
)
ON [PRIMARY];
go
CREATE NONCLUSTERED INDEX babel_1206_t1_i1
    ON babel_1206_t1 ([Login] ASC, [UserLicenseKey] ASC, [PasswordSHA1] ASC)
    WITH (FILLFACTOR = 90);
go
insert into babel_1206_t1 values (0xaaa, 0xbbb, 1);
go

CREATE TABLE babel_1206_t2(
  [profile_id] int NOT NULL,
  [result_hash] binary(32) NULL
)
ON [PRIMARY];
go
CREATE NONCLUSTERED INDEX babel_1206_t2_i1
     ON babel_1206_t2 ([profile_id] ASC, [result_hash] ASC);
go
insert into babel_1206_t2 values (1, 0xaaa);
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
go

CREATE TABLE babel_1206_t3(
      [DistinctApplicationID] [bigint] IDENTITY(1,1) NOT NULL,
      [Description] [nvarchar](1024) NOT NULL,
      [DescriptionHash]  AS (hashbytes('MD5',[Description])) PERSISTED NOT NULL,
  CONSTRAINT babel_1206_t3_i3 UNIQUE NONCLUSTERED
 (
      [DescriptionHash] ASC
 )
 ) ON [PRIMARY]
go

insert into babel_1206_t3 values (0xaaa);
go
--should throw an error because of duplicate index key
insert into babel_1206_t3 values (0xaaa);
go

drop table babel_1265_t1;
go
drop table babel_1206_t1;
go
drop table babel_1206_t2;
go
drop table babel_1206_t3;
go
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go
