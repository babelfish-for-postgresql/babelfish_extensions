create table tb_recomp_11(c11 int primary key, x int)
go
create procedure p_recomp_11 @p int as
select * from tb_recomp_11 where c11 = @p  -- parametrized
select * from tb_recomp_11 where c11 = 1   -- non-parametrized
go

create table tb_recomp_12(c12 int primary key, x int)
go
create procedure p_recomp_12 @p int as
select * from tb_recomp_12 where c12 = @p  -- parametrized
select * from tb_recomp_12 where c12 = 1   -- non-parametrized
go

create table tb_recomp_13(c13 int primary key, x int)
go
create procedure p_recomp_13 @p int as
select * from tb_recomp_13 where c13 = @p  -- parametrized
select * from tb_recomp_13 where c13 = 1   -- non-parametrized
go

create table tb_recomp_21(c21 int primary key, x int)
go
create procedure p_recomp_21 @p int as
select * from tb_recomp_21 where c21 = @p  -- parametrized
select * from tb_recomp_21 where c21 = 1   -- non-parametrized
go

create table tb_recomp_22(c22 int primary key, x int)
go
create procedure p_recomp_22 @p int as
select * from tb_recomp_22 where c22 = @p  -- parametrized
select * from tb_recomp_22 where c22 = 1   -- non-parametrized
go

create table tb_recomp_23(c23 int primary key, x int)
go
create procedure p_recomp_23 @p int as
select * from tb_recomp_23 where c23 = @p  -- parametrized
select * from tb_recomp_23 where c23 = 1   -- non-parametrized
go

create table tb_recomp_31(c31 int primary key, x int)
go
create procedure p_recomp_31 @p int as
select * from tb_recomp_31 where c31 = @p  -- parametrized
select * from tb_recomp_31 where c31 = 1   -- non-parametrized
go

create table tb_recomp_32(c32 int primary key, x int)
go
create procedure p_recomp_32 @p int as
select * from tb_recomp_32 where c32 = @p  -- parametrized
select * from tb_recomp_32 where c32 = 1   -- non-parametrized
go

create table tb_recomp_33(c33 int primary key, x int)
go
create procedure p_recomp_33 @p int as
select * from tb_recomp_33 where c33 = @p  -- parametrized
select * from tb_recomp_33 where c33 = 1   -- non-parametrized
go

create table tb_recomp_41(c41 int primary key, x int)
go
create procedure p_recomp_41 @p int 
with recompile
as
select * from tb_recomp_41 where c41 = @p  -- parametrized
select * from tb_recomp_41 where c41 = 1   -- non-parametrized
go

create table tb_recomp_51(c51 int primary key, x int)
go
create procedure p_recomp_51 @p int as
select * from tb_recomp_51 where c51 = @p  -- parametrized
select * from tb_recomp_51 where c51 = 1   -- non-parametrized
exec p_recomp_12 1
exec p_recomp_12 1 with recompile
exec p_recomp_12 1 with recompile, result sets none
exec p_recomp_41 1
exec p_recomp_41 1 with recompile
exec p_recomp_41 1 with result sets none, recompile
go

create table tb_recomp_61(c61 int primary key, x int)
go
-- fails:
create procedure p_recomp_61 @p int 
with recompile, encryption
as
select * from tb_recomp_61 where c61 = @p  -- parametrized
select * from tb_recomp_61 where c61 = 1   -- non-parametrized
go
-- fails:
create procedure p_recomp_61 @p int 
with recompile, execute as owner
as
select * from tb_recomp_61 where c61 = @p  -- parametrized
select * from tb_recomp_61 where c61 = 1   -- non-parametrized
go
-- succeeds:
create procedure p_recomp_61 @p int 
with recompile, execute as caller
as
select * from tb_recomp_61 where c61 = @p  -- parametrized
select * from tb_recomp_61 where c61 = 1   -- non-parametrized
go
