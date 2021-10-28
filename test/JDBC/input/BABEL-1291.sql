CREATE TABLE sql_variant_test(a sql_variant, b sql_variant);
GO

INSERT INTO sql_variant_test VALUES (NULL,NULL);
GO

SELECT * FROM sql_variant_test;
GO

DROP TABLE sql_variant_test;
GO

select cast(cast(NULL as bit) as sql_variant);
select cast(cast(NULL as VARCHAR(2)) as sql_variant);
select cast(null as sql_variant);
GO