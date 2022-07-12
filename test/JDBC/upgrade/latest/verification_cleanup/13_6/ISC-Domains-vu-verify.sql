
select * from information_schema.domains where DOMAIN_SCHEMA = 'isc_domains' ORDER BY DOMAIN_NAME
go

-- Test cross db references
use isc_domain_db
go

select COUNT(*) from information_schema.domains
go
