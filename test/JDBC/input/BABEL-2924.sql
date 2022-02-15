use master;
go

-- escape_hatch_storage_options: 'ignore' is default

create database db_2924_1 ON PRIMARY (NAME = 'X');
go
drop database db_2924_1;
go

create database db_2924_2 ON PRIMARY (NAME = 'X') LOG ON (NAME = 'Y');
go
drop database db_2924_2;
go

create database db_2924_3 ON PRIMARY (NAME = 'X'), (NAME = 'X2') LOG ON (NAME = 'Y'), (NAME = 'Y2');
go
drop database db_2924_3;
go

create database db_2924_4 ON PRIMARY (NAME = 'X'), FILEGROUP W (NAME='W1'), (NAME='W2'), (NAME = 'X2') LOG ON FILEGROUP Z (NAME = 'Z1'), (NAME = 'Z2'), (NAME = 'Y'), (NAME = 'Y2');
drop database db_2924_4;
go

create database db_2924_5 CONTAINMENT = NONE ON PRIMARY (NAME = 'X'), FILEGROUP W (NAME='W1'), (NAME='W2'), (NAME = 'X2') LOG ON FILEGROUP Z (NAME = 'Z1'), (NAME = 'Z2'), (NAME = 'Y'), (NAME = 'Y2') WITH DB_CHAINING ON, PERSISTENT_LOG_BUFFER = ON (DIRECTORY_NAME = '/tmp');
drop database db_2924_5;
go

select set_config('babelfishpg_tsql.escape_hatch_storage_options', 'strict', 'false')
go

create database db_2924_1 ON PRIMARY (NAME = 'X');
go

create database db_2924_2 ON PRIMARY (NAME = 'X') LOG ON (NAME = 'Y');
go

create database db_2924_3 ON PRIMARY (NAME = 'X'), (NAME = 'X2') LOG ON (NAME = 'Y'), (NAME = 'Y2');
go

create database db_2924_4 ON PRIMARY (NAME = 'X'), FILEGROUP W (NAME='W1'), (NAME='W2'), (NAME = 'X2') LOG ON FILEGROUP Z (NAME = 'Z1'), (NAME = 'Z2'), (NAME = 'Y'), (NAME = 'Y2');
go

create database db_2924_5 CONTAINMENT = NONE ON PRIMARY (NAME = 'X'), FILEGROUP W (NAME='W1'), (NAME='W2'), (NAME = 'X2') LOG ON FILEGROUP Z (NAME = 'Z1'), (NAME = 'Z2'), (NAME = 'Y'), (NAME = 'Y2') WITH DB_CHAINING ON, PERSISTENT_LOG_BUFFER = ON (DIRECTORY_NAME = '/tmp');
go

select set_config('babelfishpg_tsql.escape_hatch_storage_options', 'ignore', 'false')
go
