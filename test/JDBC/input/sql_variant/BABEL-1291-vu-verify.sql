SELECT * FROM sql_variant_test;
GO

select cast(cast(NULL as bit) as sql_variant);
select cast(cast(NULL as VARCHAR(2)) as sql_variant);
select cast(null as sql_variant);
GO