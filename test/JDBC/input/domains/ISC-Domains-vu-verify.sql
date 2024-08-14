
select * from information_schema.domains where DOMAIN_SCHEMA = 'isc_domains_vu_prepare_s' ORDER BY DOMAIN_NAME
go

-- Test cross db references
use isc_domains_vu_prepare_db
go

select COUNT(*) from information_schema.domains
go
