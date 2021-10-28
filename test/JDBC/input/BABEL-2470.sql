-- verify sys.databases.owner_sid and sys.sysdatabases.sid are the same 
-- inner select should return all 1's (e.g. columns are the same)
select owner_sid from 
sys.sysdatabases as sdb 
inner join sys.databases as d on sdb.name = d.name where owner_sid != [sid]
go

-- verify value of owner_sid/sid from sys.databases/sys.sysdatabases
-- exists in principal_id from server_principals 
select [sid] from sys.sysdatabases
    where cast(cast([sid] as int) as oid) not in
    (
        select principal_id from sys.server_principals
    )
go

select owner_sid from sys.databases
    where cast(cast(owner_sid as int) as oid) not in
    (
        select principal_id from sys.server_principals
    )
go
