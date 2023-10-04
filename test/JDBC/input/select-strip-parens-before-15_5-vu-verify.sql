-- unquoted field successfull queries
select field1 from (select field1 from select_strip_parens_t1) a;
go
select field1 from (select (field1) from select_strip_parens_t1) a;
go
select field1 from (select ((field1)) from select_strip_parens_t1) a;
go
select field1 from (select (  ( field1 )  ) from select_strip_parens_t1) a;
go
select field1 from (select (
  ( field1 )
) from select_strip_parens_t1) a;
go
select field1 from (select (
  ( "field1" )
) from select_strip_parens_t1) a;
go
select field1 from (select (
  ( [field1] )
) from select_strip_parens_t1) a;
go
select field1 from (select field1 from select_strip_parens_v1) a;
go
select field1 from (select (field1) from select_strip_parens_v1) a;
go
select field1 from (select ((field1)) from select_strip_parens_v1) a;
go
select field1 from (select (  ( field1 )  ) from select_strip_parens_v1) a;
go
select field1 from (select (
  ( field1 )
) from select_strip_parens_v1) a;
go
select field1 from (select (
  ( "field1" )
) from select_strip_parens_v1) a;
go
select field1 from (select (
  ( [field1] )
) from select_strip_parens_v1) a;
go

-- unquoted field failed queries
select field1 from (select " field1" from select_strip_parens_t1) a;
go
select field1 from (select " field1" from select_strip_parens_v1) a;
go
select field1 from (select [ field1] from select_strip_parens_t1) a;
go
select field1 from (select [ field1] from select_strip_parens_v1) a;
go
select field1 from (select (
  ( " field1" )
) from select_strip_parens_t1) a;
go
select field1 from (select (
  ( " field1" )
) from select_strip_parens_v1) a;
go
select field1 from (select (
  ( [ field1] )
) from select_strip_parens_t1) a;
go
select field1 from (select (
  ( [ field1] )
) from select_strip_parens_v1) a;
go

-- quoted fields successfull queries
select " field2  ", [  field3 ] from (select " field2  ", [  field3 ] from select_strip_parens_t1) a;
go
select [ field2  ], [  field3 ] from (select " field2  ", [  field3 ] from select_strip_parens_t1) a;
go
select " field2  ", [  field3 ] from (select (" field2  "), ([  field3 ]) from select_strip_parens_t1) a;
go
select " field2  ", [  field3 ] from (select ((" field2  ")), (([  field3 ])) from select_strip_parens_t1) a;
go
select " field2  ", [  field3 ] from (select ( ( " field2  " ) ), ( ( [  field3 ] ) ) from select_strip_parens_t1) a;
go
select " field2  ", [  field3 ] from (select (
  ( " field2  " )
), (
  ( [  field3 ] )
) from select_strip_parens_t1) a;
go

select " field2  ", [  field3 ] from (select " field2  ", [  field3 ] from select_strip_parens_v1) a;
go
select " field2  ", "  field3 " from (select " field2  ", [  field3 ] from select_strip_parens_v1) a;
go
select " field2  ", [  field3 ] from (select (" field2  "), ([  field3 ]) from select_strip_parens_v1) a;
go
select " field2  ", [  field3 ] from (select ((" field2  ")), (([  field3 ])) from select_strip_parens_v1) a;
go
select " field2  ", [  field3 ] from (select ( ( " field2  " ) ), ( ( [  field3 ] ) ) from select_strip_parens_v1) a;
go
select " field2  ", [  field3 ] from (select (
  ( " field2  " )
), (
  ( [  field3 ] )
) from select_strip_parens_v1) a;
go

-- quoted fields failed queries
select "  field2 " from (select " field2  ", [  field3 ] from select_strip_parens_t1) a;
go
select [ field3  ] from (select " field2  ", [  field3 ] from select_strip_parens_v1) a;
go
