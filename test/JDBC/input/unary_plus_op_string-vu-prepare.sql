set quoted_identifier off
go
create table t1_unary_plus_op_string(i int, vc varchar(30))
go

create view v1_unary_plus_op_string as
select 'view '+++(+N'value1') + 
+ /*comment*/
(
+ /*comment*/
+ -- comment +
(
+
'value2'))++(+(select 'value3')) as col1,
1 + -2 as col2,
1 ++ -2 as col3,
1 + ~2 as col4,
1 +++++ ~2 as col5,
1 ++++ (++++ -2) as col6,
1 ++++ (++++ ~2) as col7
go

create procedure p1_unary_plus_op_string 
as
declare @v varchar(20) = ' test'
declare @i int = 1
declare @d datetime='2024-Jan-01 01:02:03' 
declare @dc decimal(10,4)=1
select 'proc '+'line1'
select 'proc '++'line2'
select 'proc '++N'line3'
select 'proc '+++++'line4'
select 'proc '+++++"line5"
select 'proc '+
+ /*comment*/
(
+ /*comment*/
+ -- comment +
(
+
"line6"))+++@v
select 'proc ' ++(++(++(select N'line7')))++(+@v)
select 'proc ' ++ case when len('a'+++ 'b')=2 then 'true' else 'false' end
select 'proc line8' where 'x' in (+'x')
select 'proc line9' where 'x' like +'x'
set @v = 'x'
select 'proc line10' where 'x' like (+@v)
select 'proc line11' where 'x' like +(+(+@v))
select 'proc line 12 ' ++ vc from t1_unary_plus_op_string order by 1  
select 'proc line 13 ' ++(+vc) from t1_unary_plus_op_string order by 1
select 'proc line 14 ' ++ [vc] from t1_unary_plus_op_string order by 1 
select 1 + @i, 2 + (+@i), 3 ++++(++(+++@i)) 
select +@d, + (+@d), ++++(++(+++@d))
select 1 +@dc, 2 + (+@dc), 3 ++++(++(+++@dc))
select 1 + -2 as expr1
select 1 ++ -2 as expr2
select 1 + ~2 as expr3
select 1 +++++ ~2 as expr4
select 1 ++++ (++++ -2) as expr5
select 1 ++++ (++++ ~2) as expr6
EXECUTE('select ''execimm ''++''line1''')
EXECUTE('select ''execimm ''++N''line2''')
EXECUTE('select ''execimm ''++(+(select N''line3''))')
go

create function f1_unary_plus_op_string (@v varchar(10)) returns varchar(30)
as
begin
declare @s varchar(30)
set @s = 'func '+++(+N'value1') +
+
(
+ /*comment*/
+ -- comment +
(++(select "value2")))++(+@v)
return @s
end
go
