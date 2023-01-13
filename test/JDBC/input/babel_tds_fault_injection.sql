-- check the status of a fault
select inject_fault_status('test_fault1');
go

-- inject a fault
select inject_fault('test_fault1');
go

select inject_fault_status('test_fault1');
go

-- re-inject a fault for next two requests and check the status
select inject_fault('test_fault1', 2);
go

select inject_fault_status('test_fault1');
go

-- trigger the test fault
select trigger_test_fault();
go

select inject_fault_status('test_fault1');
go

select trigger_test_fault();
go

select inject_fault_status('test_fault1');
go

-- should be empty
select trigger_test_fault();
go

-- disable an injected fault
select inject_fault('test_fault1');
go

select inject_fault_status('test_fault1');
go

select disable_injected_fault('test_fault1');
go

select inject_fault_status('test_fault1');
go

-- try to disable a disabled fault
select disable_injected_fault('test_fault1');
go

-- trigger two faults
select inject_fault('test_fault1');
go

select inject_fault('test_fault2');
go

select trigger_test_fault();
go

-- should be empty
select trigger_test_fault();
go

-- enable/disable all the faults except "tds_comm_throw_error" fault
select inject_fault('test_fault1');
select inject_fault('test_fault2');
select inject_fault('pre_parsing_tamper_request');
select inject_fault('pre_parsing_tamper_rpc_request_sptype');
select inject_fault('parsing_tamper_rpc_parameter_datatype');
select inject_fault('pre_parsing_throw_error');
select inject_fault('buffer_overflow_test');
select inject_fault('post_parsing_throw_error');
GO


-- below will trigger "pre_parsing_throw_error"
select 1
go

-- below will trigger "post_parsing_throw_error"
select 1
go

-- 'test_fault1' should be enable 
select inject_fault_status('test_fault1');
go

-- 'test_fault2' should be enable
select inject_fault_status('test_fault2');
go

-- 'test_fault1' and 'test_fault2' should be triggered
select trigger_test_fault();
go

-- disable all fault injections
select disable_injected_fault_all();
go

-- should be disabled
select inject_fault_status('test_fault1');
go

-- should be disabled
select inject_fault_status('test_fault2');
go

-- should be disabled
select inject_fault_status('tds_comm_throw_error');
go

-- should be disabled
select inject_fault_status('pre_parsing_tamper_request');
go

-- should be disabled
select inject_fault_status('pre_parsing_tamper_request');
go

-- should be disabled
select inject_fault_status('pre_parsing_tamper_rpc_request_sptype');
go

-- should be disabled
select inject_fault_status('parsing_tamper_rpc_parameter_datatype');
go

-- should be disabled
select inject_fault_status('pre_parsing_throw_error');
go

-- should be disabled
select inject_fault_status('buffer_overflow_test');
go

-- should be disabled
select inject_fault_status('post_parsing_throw_error');
go