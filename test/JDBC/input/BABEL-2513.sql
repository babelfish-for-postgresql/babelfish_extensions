use master;
go

CREATE TABLE t2513(
  dto datetimeoffset,
  dt2 datetime2,
	dt datetime,
	sdt smalldatetime,
	d date,
	t time);

INSERT INTO t2513 values ('1900-01-01 00:00:00', '1900-01-01 00:00:00', '1900-01-01 00:00:00', '1900-01-01 00:00:00', '1900-01-01', '00:00:00'); -- all same
INSERT INTO t2513 values ('1900-01-01 00:00:00', '1900-01-02 00:00:02', '1900-01-03 00:00:03', '1900-01-04 00:00:04', '1900-01-05', '00:00:06'); -- ascending
INSERT INTO t2513 values ('1900-01-06 00:00:00', '1900-01-05 00:00:05', '1900-01-04 00:00:04', '1900-01-03 00:00:03', '1900-01-02', '00:00:01'); -- descending
GO

-- start of dto

-- dto vs dto
select * from t2513 where dto = dto;
select * from t2513 where dto != dto;
select * from t2513 where dto < dto;
select * from t2513 where dto <= dto;
select * from t2513 where dto > dto;
select * from t2513 where dto >= dto;
GO

-- dto vs dt2
select * from t2513 where dto = dt2;
select * from t2513 where dto != dt2;
select * from t2513 where dto < dt2;
select * from t2513 where dto <= dt2;
select * from t2513 where dto > dt2;
select * from t2513 where dto >= dt2;
GO

-- dto vs dt
select * from t2513 where dto = dt;
select * from t2513 where dto != dt;
select * from t2513 where dto < dt;
select * from t2513 where dto <= dt;
select * from t2513 where dto > dt;
select * from t2513 where dto >= dt;
GO

-- dto vs sdt
select * from t2513 where dto = sdt;
select * from t2513 where dto != sdt;
select * from t2513 where dto < sdt;
select * from t2513 where dto <= sdt;
select * from t2513 where dto > sdt;
select * from t2513 where dto >= sdt;
GO

-- dto vs d
select * from t2513 where dto = d;
select * from t2513 where dto != d;
select * from t2513 where dto < d;
select * from t2513 where dto <= d;
select * from t2513 where dto > d;
select * from t2513 where dto >= d;
GO

-- dto vs t
select * from t2513 where dto = t;
select * from t2513 where dto != t;
select * from t2513 where dto < t;
select * from t2513 where dto <= t;
select * from t2513 where dto > t;
select * from t2513 where dto >= t;
GO

-- start of dt2

-- dt2 vs dto
select * from t2513 where dt2 = dto;
select * from t2513 where dt2 != dto;
select * from t2513 where dt2 < dto;
select * from t2513 where dt2 <= dto;
select * from t2513 where dt2 > dto;
select * from t2513 where dt2 >= dto;
GO

-- dt2 vs dt2
select * from t2513 where dt2 = dt2;
select * from t2513 where dt2 != dt2;
select * from t2513 where dt2 < dt2;
select * from t2513 where dt2 <= dt2;
select * from t2513 where dt2 > dt2;
select * from t2513 where dt2 >= dt2;
GO

-- dt2 vs dt
select * from t2513 where dt2 = dt;
select * from t2513 where dt2 != dt;
select * from t2513 where dt2 < dt;
select * from t2513 where dt2 <= dt;
select * from t2513 where dt2 > dt;
select * from t2513 where dt2 >= dt;
GO

-- dt2 vs sdt
select * from t2513 where dt2 = sdt;
select * from t2513 where dt2 != sdt;
select * from t2513 where dt2 < sdt;
select * from t2513 where dt2 <= sdt;
select * from t2513 where dt2 > sdt;
select * from t2513 where dt2 >= sdt;
GO

-- dt2 vs d
select * from t2513 where dt2 = d;
select * from t2513 where dt2 != d;
select * from t2513 where dt2 < d;
select * from t2513 where dt2 <= d;
select * from t2513 where dt2 > d;
select * from t2513 where dt2 >= d;
GO

-- dt2 vs t
select * from t2513 where dt2 = t;
select * from t2513 where dt2 != t;
select * from t2513 where dt2 < t;
select * from t2513 where dt2 <= t;
select * from t2513 where dt2 > t;
select * from t2513 where dt2 >= t;
GO

-- start of dt

-- dt vs dto
select * from t2513 where dt = dto;
select * from t2513 where dt != dto;
select * from t2513 where dt < dto;
select * from t2513 where dt <= dto;
select * from t2513 where dt > dto;
select * from t2513 where dt >= dto;
GO

-- dt vs dt2
select * from t2513 where dt = dt2;
select * from t2513 where dt != dt2;
select * from t2513 where dt < dt2;
select * from t2513 where dt <= dt2;
select * from t2513 where dt > dt2;
select * from t2513 where dt >= dt2;
GO

-- dt vs dt
select * from t2513 where dt = dt;
select * from t2513 where dt != dt;
select * from t2513 where dt < dt;
select * from t2513 where dt <= dt;
select * from t2513 where dt > dt;
select * from t2513 where dt >= dt;
GO

-- dt vs sdt
select * from t2513 where dt = sdt;
select * from t2513 where dt != sdt;
select * from t2513 where dt < sdt;
select * from t2513 where dt <= sdt;
select * from t2513 where dt > sdt;
select * from t2513 where dt >= sdt;
GO

-- dt vs d
select * from t2513 where dt = d;
select * from t2513 where dt != d;
select * from t2513 where dt < d;
select * from t2513 where dt <= d;
select * from t2513 where dt > d;
select * from t2513 where dt >= d;
GO

-- dt vs t
select * from t2513 where dt = t;
select * from t2513 where dt != t;
select * from t2513 where dt < t;
select * from t2513 where dt <= t;
select * from t2513 where dt > t;
select * from t2513 where dt >= t;
GO

-- start of sdt

-- sdt vs dto
select * from t2513 where sdt = dto;
select * from t2513 where sdt != dto;
select * from t2513 where sdt < dto;
select * from t2513 where sdt <= dto;
select * from t2513 where sdt > dto;
select * from t2513 where sdt >= dto;
GO

-- sdt vs dt2
select * from t2513 where sdt = dt2;
select * from t2513 where sdt != dt2;
select * from t2513 where sdt < dt2;
select * from t2513 where sdt <= dt2;
select * from t2513 where sdt > dt2;
select * from t2513 where sdt >= dt2;
GO

-- sdt vs dt
select * from t2513 where sdt = dt;
select * from t2513 where sdt != dt;
select * from t2513 where sdt < dt;
select * from t2513 where sdt <= dt;
select * from t2513 where sdt > dt;
select * from t2513 where sdt >= dt;
GO

-- sdt vs sdt
select * from t2513 where sdt = sdt;
select * from t2513 where sdt != sdt;
select * from t2513 where sdt < sdt;
select * from t2513 where sdt <= sdt;
select * from t2513 where sdt > sdt;
select * from t2513 where sdt >= sdt;
GO

-- sdt vs d
select * from t2513 where sdt = d;
select * from t2513 where sdt != d;
select * from t2513 where sdt < d;
select * from t2513 where sdt <= d;
select * from t2513 where sdt > d;
select * from t2513 where sdt >= d;
GO

-- sdt vs t
select * from t2513 where sdt = t;
select * from t2513 where sdt != t;
select * from t2513 where sdt < t;
select * from t2513 where sdt <= t;
select * from t2513 where sdt > t;
select * from t2513 where sdt >= t;
GO

-- start of d

-- d vs dto
select * from t2513 where d = dto;
select * from t2513 where d != dto;
select * from t2513 where d < dto;
select * from t2513 where d <= dto;
select * from t2513 where d > dto;
select * from t2513 where d >= dto;
GO

-- d vs dt2
select * from t2513 where d = dt2;
select * from t2513 where d != dt2;
select * from t2513 where d < dt2;
select * from t2513 where d <= dt2;
select * from t2513 where d > dt2;
select * from t2513 where d >= dt2;
GO

-- d vs dt
select * from t2513 where d = dt;
select * from t2513 where d != dt;
select * from t2513 where d < dt;
select * from t2513 where d <= dt;
select * from t2513 where d > dt;
select * from t2513 where d >= dt;
GO

-- d vs sdt
select * from t2513 where d = sdt;
select * from t2513 where d != sdt;
select * from t2513 where d < sdt;
select * from t2513 where d <= sdt;
select * from t2513 where d > sdt;
select * from t2513 where d >= sdt;
GO

-- d vs d
select * from t2513 where d = d;
select * from t2513 where d != d;
select * from t2513 where d < d;
select * from t2513 where d <= d;
select * from t2513 where d > d;
select * from t2513 where d >= d;
GO

-- d vs t
select * from t2513 where d = t;
select * from t2513 where d != t;
select * from t2513 where d < t;
select * from t2513 where d <= t;
select * from t2513 where d > t;
select * from t2513 where d >= t;
GO

-- start of t

-- t vs dto
select * from t2513 where t = dto;
select * from t2513 where t != dto;
select * from t2513 where t < dto;
select * from t2513 where t <= dto;
select * from t2513 where t > dto;
select * from t2513 where t >= dto;
GO

-- t vs dt2
select * from t2513 where t = dt2;
select * from t2513 where t != dt2;
select * from t2513 where t < dt2;
select * from t2513 where t <= dt2;
select * from t2513 where t > dt2;
select * from t2513 where t >= dt2;
GO

-- t vs dt
select * from t2513 where t = dt;
select * from t2513 where t != dt;
select * from t2513 where t < dt;
select * from t2513 where t <= dt;
select * from t2513 where t > dt;
select * from t2513 where t >= dt;
GO

-- t vs sdt
select * from t2513 where t = sdt;
select * from t2513 where t != sdt;
select * from t2513 where t < sdt;
select * from t2513 where t <= sdt;
select * from t2513 where t > sdt;
select * from t2513 where t >= sdt;
GO

-- t vs d
select * from t2513 where t = d;
select * from t2513 where t != d;
select * from t2513 where t < d;
select * from t2513 where t <= d;
select * from t2513 where t > d;
select * from t2513 where t >= d;
GO

-- t vs t
select * from t2513 where t = t;
select * from t2513 where t != t;
select * from t2513 where t < t;
select * from t2513 where t <= t;
select * from t2513 where t > t;
select * from t2513 where t >= t;
GO

drop table t2513
GO
