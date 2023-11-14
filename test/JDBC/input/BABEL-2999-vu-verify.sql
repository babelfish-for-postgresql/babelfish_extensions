insert into t1_BABEL2999 exec('Select ''5''');
GO

insert into t1_BABEL2999 exec('Select 5');
GO

insert into t1_BABEL2999 exec('Select ''5''');
GO

insert into t1_BABEL2999 exec('Select ''hello''');
GO

insert into t1_BABEL2999 exec('SELECT ''helloworld''');
GO

insert into t1_BABEL2999 exec('SELECT ''helloworldhello''');
GO

select b from t1_BABEL2999 order by b;
GO

insert into t2_BABEL2999 exec('Select ''5'''); -- varchar to int
GO

insert into t2_BABEL2999 exec('Select 5');  -- int to int
GO

insert into t2_BABEL2999 SELECT '5'; 
GO

select b from t2_BABEL2999 order by b;
GO

insert into t3_BABEL2999 exec('Select ''5''');
GO

insert into t3_BABEL2999 exec('Select 5');
GO

insert into t3_BABEL2999 exec('Select ''5''');
GO

select b from t3_BABEL2999 order by b;
GO

delete from t1_BABEL2999
GO

insert into t1_BABEL2999 exec p1_BABEL2999;
GO

insert into t1_BABEL2999 exec('exec p1_BABEL2999');
GO

select * from  t1_BABEL2999;
GO

insert t3_BABEL2999_2 exec('select ''123'', 123, 123');
GO

insert into t3_BABEL2999_2 exec p3_BABEL2999
GO

insert into t3_BABEL2999_2 select '123', 123, 123
GO

select * from t3_BABEL2999_2;
GO

insert into t3_BABEL2999_2 exec('select ''123''');
GO

insert into t3_BABEL2999_2 exec('select 123, 123');
GO

insert into t4_BABEL2999 exec('select 123, 123, 123, 123, 123')
GO

insert into t4_BABEL2999 exec('select cast(123 as binary), cast(123 as varbinary), 123, cast(123 as datetime), cast(123 as smalldatetime)')
GO

insert into t4_BABEL2999 select 123, 123, 123, 123, 123
GO

insert into t4_BABEL2999 exec('select ''123'', ''123'', ''123'', ''123'', ''123''');
GO

select * from t4_BABEL2999
GO

insert into t5_BABEL2999 exec('select ''1.234'', ''33.33''');
GO

select * from t5_BABEL2999
GO

insert into t6_BABEL2999 exec('select 1,2,3')
GO

insert into t6_BABEL2999 exec('select ''1'',''2'',''3''')
GO

insert into t6_BABEL2999 exec('select c,b,a from t6_BABEL2999')
GO

select * from t6_BABEL2999
GO
