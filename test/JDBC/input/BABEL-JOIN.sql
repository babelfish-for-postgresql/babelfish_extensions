CREATE TABLE t1(
	id INT,
	comment NVARCHAR(20)
) 
go
CREATE TABLE t2(
	id INT,
	t1_id INT,
	PRIMARY KEY(id ASC)
) 
go
INSERT t1 VALUES (1, 'test')	
go
select * from t1 a left join t2 b on b.t1_id = a.id 
go

DROP Table t1
DROP Table t2
go