SELECT CAST('Index Name fetched from sys.indexes' AS CHAR(30)), CAST('index_id' AS CHAR(7)), CAST('index_column_id' AS CHAR(14)), CAST('column_id' AS CHAR(8)), CAST('key_ordinal' AS CHAR(10)), CAST('is_descending_key' AS CHAR(15)), CAST('is_included_column' AS CHAR(15));
SELECT CAST(i.name AS CHAR(30)), CAST(c.index_id AS CHAR(7)), CAST(c.index_column_id AS CHAR(14)), CAST(c.column_id AS CHAR(8)), CAST(c.key_ordinal AS CHAR(10)), CAST(c.is_descending_key AS CHAR(15)), CAST(c.is_included_column AS CHAR(15))
    FROM
        sys.index_columns AS c
        INNER JOIN sys.indexes i ON (i.object_id = c.object_id AND i.index_id = c.index_id)
    WHERE
        c.object_id = OBJECT_ID('babel_4817_t1') AND i.type_desc != 'HEAP'
    ORDER BY c.index_id ASC, c.column_id ASC;
GO


SELECT CAST('Index Name fetched from sys.indexes' AS CHAR(30)), CAST('index_id' AS CHAR(7)), CAST('index_column_id' AS CHAR(14)), CAST('column_id' AS CHAR(8)), CAST('key_ordinal' AS CHAR(10)), CAST('is_descending_key' AS CHAR(15)), CAST('is_included_column' AS CHAR(15));
SELECT CAST(i.name AS CHAR(30)), CAST(c.index_id AS CHAR(7)), CAST(c.index_column_id AS CHAR(14)), CAST(c.column_id AS CHAR(8)), CAST(c.key_ordinal AS CHAR(10)), CAST(c.is_descending_key AS CHAR(15)), CAST(c.is_included_column AS CHAR(15))
    FROM
        sys.index_columns AS c
        INNER JOIN sys.indexes i ON (i.object_id = c.object_id AND i.index_id = c.index_id)
    WHERE
        c.object_id = OBJECT_ID('babel_4817_t2') AND i.type_desc != 'HEAP'
    ORDER BY c.index_id ASC, c.column_id ASC;
GO



SELECT 'col1 --> is_computed? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col1', 'iscomputed')
SELECT 'col2 --> is_computed? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col2', 'iscomputed')
SELECT 'col3 --> is_computed? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col3', 'iscomputed')
SELECT 'col4 --> is_computed? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col4', 'iscomputed')
SELECT 'col5 --> is_computed? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col5', 'iscomputed')
SELECT 'col6 --> is_computed? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col6', 'iscomputed')
GO

SELECT 'col1 --> columnid= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col1', 'columnid')
SELECT 'col2 --> columnid= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col2', 'columnid')
SELECT 'col3 --> columnid= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col3', 'columnid')
SELECT 'col4 --> columnid= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col4', 'columnid')
SELECT 'col5 --> columnid= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col5', 'columnid')
SELECT 'col6 --> columnid= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col6', 'columnid')
GO

SELECT 'col1 --> ordinal= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col1', 'ordinal')
SELECT 'col2 --> ordinal= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col2', 'ordinal')
SELECT 'col3 --> ordinal= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col3', 'ordinal')
SELECT 'col4 --> ordinal= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col4', 'ordinal')
SELECT 'col5 --> ordinal= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col5', 'ordinal')
SELECT 'col6 --> ordinal= ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col6', 'ordinal')
GO

SELECT 'col1 --> isidentity? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col1', 'isidentity')
SELECT 'col3 --> isidentity? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col3', 'isidentity')
SELECT 'col2 --> isidentity? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col2', 'isidentity')
SELECT 'col4 --> isidentity? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col4', 'isidentity')
SELECT 'col5 --> isidentity? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col5', 'isidentity')
SELECT 'col6 --> isidentity? ', columnproperty(OBJECT_ID('babel_4817_t3'), 'col6', 'isidentity')
GO
