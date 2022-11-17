create database db_routines_vu_prepare;
go

use db_routines_vu_prepare;
go

create procedure routines_vu_prepare_test_nvar(@test_nvar_a nvarchar , @test_nvar_b int = 8)
AS
BEGIN
        SELECT @test_nvar_b=8;
END
go

create schema routines_vu_prepare_sc1;
go

CREATE FUNCTION routines_vu_prepare_sc1.routines_vu_prepare_test_dec(
    @test_dec_a INT,
    @test_dec_b DEC(10,2),
    @test_dec_c DEC(4,2)
)
RETURNS DEC(10,2)
AS
BEGIN
    RETURN @test_dec_a * @test_dec_b * (1 - @test_dec_c);
END;
go

create function routines_vu_prepare_fc1(@fc1_a nvarchar) RETURNS nvarchar AS BEGIN return @fc1_a END;
go

CREATE FUNCTION routines_vu_prepare_test_func_opt (@test_func_opt_a varchar(10))
RETURNS INT
 WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
        RETURN 2;
END;
go

-- Table valued Function returns NULL
CREATE FUNCTION routines_vu_prepare_test_func_tvp ()
RETURNS @testFuncTvf table (tvf int PRIMARY KEY)
AS
BEGIN
INSERT INTO @testFuncTvf VALUES (1)
RETURN
END;
go
