create table t ( a varchar(30))
GO

insert into t values ('abc'),('bbc'),('cbc')
GO

select * from t where a like '[abc]bc';
GO

select * from t where a like '[a-c]bc';
GO

select * from t where a like '[abc]_c';
GO

select * from t where a like '[a]%c';
GO

select * from t where a like '%[abc]c';
GO

select * from t where a like '[%]bc';
GO

select * from t where a like '[_]bc';
GO

select * from t where a like 'a[bc]c';
GO

select * from t where a like '[a-z][a-z]c';
GO

select * from t where a like '[^ a][a-z]c';
GO

select * from t where a like '[^ a-b][a-z]c';
GO

select * from t where a like '[0-9a-f][0-9a-f][0-9a-f]';
GO

insert into t values (']bc')
GO

insert into t values ('[bc')
GO

select * from t where a like ('[]]bc');
GO

select * from t where a like ('[[]bc');
GO

insert into t values ('11.22');
GO

select * from t where a like '[0-9][0-9].[0-9][0-9]'
GO

create table t2 ( b varchar(30) collate BBF_Unicode_General_CS_AS)
GO

insert into t2 values ('[abc]bc'),('[abc]_c'),('[]]bc'),('[[]bc'),('%[abc]c'),('[^ a-b][a-z]c'),('[0-9][0-9].[0-9][0-9]')
GO

select * from t2 join t on a like b;
GO

drop table t2;
GO

drop table t;
GO