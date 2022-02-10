-- Only including test for property "physical_net_transport"
-- Not including test for property "client_net_address"
-- because the output is nondeterministic
SELECT connectionproperty('physical_net_transport')
GO
