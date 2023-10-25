select ''+'ps';
GO

select 'rs' + '';
GO

select '' + '';
GO

select '' + NULL;
GO

select NULL + '';
GO

set quoted_identifier off
GO
select ""+'s';
GO

set quoted_identifier off
GO
select 'rs' + "";
GO

set quoted_identifier off
GO
select '' + "";
GO

set quoted_identifier off
GO
select "" + NULL;
GO

set quoted_identifier off
GO
select NULL + "";
GO

set quoted_identifier off
GO
select ""+"s";
GO

set quoted_identifier off
GO
select "pr" + "";
GO

set quoted_identifier off
GO
select "" + "";
GO

set quoted_identifier off
GO
select "" + "";
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT 'Hello' + NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT 'Hello' + NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT '' + NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT '' + NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT '' + NULL + '';
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT '' + NULL + '';
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT 'Hello' + NULL;
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT 'Hello' + NULL;
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT "" + NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT "" + NULL + 'World';
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT "" + NULL + "";
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT "" + NULL + "";
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT '' + NULL + "World";
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT '' + NULL + "World";
GO

SET CONCAT_NULL_YIELDS_NULL ON;
GO
SELECT '' + NULL + "";
GO

SET CONCAT_NULL_YIELDS_NULL OFF;
GO
SELECT '' + NULL + "";
GO