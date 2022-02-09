-- test connectionproperty() function
-- invalid property name, should return NULL
select connectionproperty('invalid property');
GO

select connectionproperty(NULL);
GO

-- valid supported properties
select connectionproperty('net_transport'),connectionproperty('protocol_type'), connectionproperty('auth_scheme'), connectionproperty('local_tcp_port');
GO

select @@MICROSOFTVERSION;
GO