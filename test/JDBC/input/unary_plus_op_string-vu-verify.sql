insert t1_unary_plus_op_string values (1, 'abc')
go

set quoted_identifier off
go
select 'x'+'y'
go
select 'x' + 'y'
go
select 'x' + 
/* comment*/
'y'
/*comment*/    + 
   'z'
go
select 'x'++'y'
go
select 'x'++++++++'y'
go
select 'x'++N'y'
go
select 'x'++++++++N'y'
go
select 'x' ++++++++ 'y'
go
select 'x' ++   ++ 
/* comment*/  +  +
'y'  ++ -- comment +
/*comment*/    ++  +
 ++  'z'
go
declare @v varchar(10)='y' select 'x'+ @v, 'x' +@v, 'x' ++++++@v
go
declare @v varchar(10)='y' select 'x'+ (@v), 'x' + (+@v), 'x' ++++(++(+++@v))
go
declare @v tinyint=1 select 1 +@v, 2 + (+@v), 3 ++++(++(+++@v))
go
declare @v int=1 select 1 +@v, 2 + (+@v), 3 ++++(++(+++@v))
go
declare @v bigint=1 select 1 +@v, 2 + (+@v), 3 ++++(++(+++@v))
go
declare @v decimal(10,4)=1 select 1 +@v, 2 + (+@v), 3 ++++(++(+++@v))
go
declare @v money=1 select 1 +@v, 2 + (+@v), 3 ++++(++(+++@v))
go
declare @v datetime='2024-Jan-01 01:02:03' select  +@v, + (+@v), ++++(++(+++@v))
go
declare @v datetime2='2024-Jan-01 01:02:03' select  +@v, + (+@v), ++++(++(+++@v))
go
select +'y'
go
select +N'y'
go
select ((+'y')) 
go
select ((+N'y')) 
go
select ++++(++++++(+++++'y')) 
go
select 'x'+(+'y') 
go
select 'x'+++((+++(+++'y')))
go
select 'x'+++(
(+++
(+++
'y')))
go
if 'x' <> + char(13) select 'true' else select 'false'
go
if 'x' <> +++ char(13) select 'true' else select 'false'
go
select len(+'x')
go
select len(+N'x')
go
select 'x' ++ substring('xyz', 2, 1)
go
select 'x' +++++ substring(+'xyz', 2, 1)  
go
select 'x' ++ case when len('a'+++ 'b')=2 then 'true' else 'false' end
go
select 'x' ++ case when len(+'a'+++ 'b')=2 then +'true' else +++++'false' end
go
declare @v varchar(10) = 'true'
select 'x' ++ case when len(+'a'+++ 'b')=2 then +@v else 'false' end
go
select 1 where 'x' in (+'x')
go
select 1 where 'x' like +'x'
go
declare @v varchar(10) = 'x'
select 1 where 'x' like (+@v)
go
declare @v varchar(10) = 'x'
select 1 where 'x' like +(+(+@v))
go
declare @v varchar(10) = 'x'
if 'y' <> + @v select 'true' else select 'false'
go
declare @v varchar(10) = 'x'
if 'y' <> +++ @v select 'true' else select 'false'
set @v = 'x' ++ case when len('a'+++ 'b')=2 then 'true2' else 'false2' end
select @v
go
select 'x' ++vc from t1_unary_plus_op_string order by 1
go
select 'x' ++(+vc) from t1_unary_plus_op_string order by 1
go
select +(select 'abc')
go
select ++++(select 'abc')
go
select +(+((select 'abc')))
go

/*double-quoted strings*/
select "x"+"y"
go
select "x" + "y"
go
select "x" + 
/* comment*/
"y" 
/*comment*/    + 
   "z"
go
select "x"++"y"
go
select "x"++++++++"y"
go
select "x" ++++++++ "y"
go
select "x" ++   ++ 
/* comment*/  +  +
"y"  ++ 
/*comment*/    ++  +
 ++  "z"
go
declare @v varchar(10)="y" select "x"+ @v, "x" +@v, "x" ++++++@v
go
select +"y"
go
select ((+"y")) 
go
select ++++(++++++(+++++"y")) 
go
select 'x'+(+"y") 
go
select "x"+++((+++(+++"y")))
go
select "x"+++(
(+++
(+++
"y")))
go
if "x" <> + char(13) select "true" else select "false"
go
if "x" <> +++ char(13) select "true" else select "false"
go
select len(+"x")
go
select "x" ++ substring("xyz", 2, 1)
go
select "x" +++++ substring(+"xyz", 2, 1)  
go
select "x" ++ case when len("a"+++ "b")=2 then "true" else "false" end
go
declare @v varchar(10) = "true"
select "x" ++ case when len(+"a"+++ 'b')=2 then +@v else +"false" end
go
select 1 where "x" in (+"x")
go
select 1 where "x" like +"x"
go
declare @v varchar(10) = "x"
if "y" <> +++ @v select "true" else select "false"
set @v = "x" ++ case when len(++"a"+++N'b')=2 then "true2" else "false2" end
select @v
go
select +(+((select "abc")))
go

/* double-quoted identifiers */
set quoted_identifier on
go
select 'x' ++ "vc" from t1_unary_plus_op_string order by 1
go
select 'x' ++((+(++"vc"))) from t1_unary_plus_op_string order by 1
go
set quoted_identifier off
go

/* bracket-delimited identifiers */
select 'x' ++ [vc] from t1_unary_plus_op_string order by 1
go
select 'x' ++ ((+(++[vc]))) from t1_unary_plus_op_string order by 1
go

/*numeric expressions should not be affected*/
select 1 +-2
go
select 1 + -2
go
select 1 ++-2
go
select 1 + + -2
go
select 1 + ~2
go
select 1 ++~2
go
select 1 ++ ~2
go
select 1 ++++ (++++ 2) 
go
select 1 ++++ (++++ ~2) 
go
select 1 ++++ (++++ -2) 
go

/* execute-immediate */
execute('select ((+''y'')) ')
go
execute('select ''x''+++((+++(+++''y'')))')
go
execute('select ''x'' ++vc from t1_unary_plus_op_string order by 1')
go

/* SQL objects */
select * from v1_unary_plus_op_string
go
execute p1_unary_plus_op_string
go
select * from dbo.f1_unary_plus_op_string('test')
go

/* the following should raise an error: unary operator other than '+' is invalid for a string in T-SQL */
select  ~'y' 
go
select 'x' + ~'y' 
go
select 'x' ++ ~'y' 
go
select  -'y' 
go
select 'x' + -'y' 
go
select 'x' ++ -'y' 
go