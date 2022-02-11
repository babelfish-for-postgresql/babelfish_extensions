CREATE TABLE join_repro (
    c1  bigint  NOT NULL
    , c2    binary(123) NOT NULL
    , c3    INT NOT NULL
    , c4    REAL    NOT NULL
    , c5    FLOAT   NOT NULL
    , c6    CHAR(1) NOT NULL
)
go

SELECT T.name
FROM sys.objects O, sys.columns C, sys.types T
WHERE O.object_id = C.object_id
AND C.user_type_id = T.user_type_id
AND O.name = 'join_repro'
AND O.schema_id = SCHEMA_ID( 'dbo' )
ORDER BY T.name
go

-- verifying all type names exists in a clean database
Create database BABEL2869
go

Use BABEL2869
go

Select name from sys.types order by name
go

use master
go

drop table join_repro
drop database BABEL2869
go