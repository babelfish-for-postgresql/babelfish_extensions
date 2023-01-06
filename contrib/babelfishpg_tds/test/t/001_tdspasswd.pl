# Copyright (c) 2021, Amazon Web Services, Inc. or its affiliates. All Rights Reserved

# Verify that work items work correctly

use strict;
use warnings;


use Test::More tests => 6;
use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use TDSNode;

# Delete pg_hba.conf from the given node, add a new entry to it
# and then execute a reload to refresh it.
sub reset_pg_hba
{
	my $node       = shift;
	my $hba_method = shift;

	unlink($node->data_dir . '/pg_hba.conf');
	# just for testing purposes, use a continuation line
	$node->append_conf('pg_hba.conf', "host all all 127.0.0.1/32 \\\n $hba_method");
	$node->reload;
	return;
}

# Initialize primary node
my $node = PostgreSQL::Test::Cluster->new('primary');
$node->init;
$node->append_conf(
	'postgresql.conf', qq{
log_connections = on
listen_addresses='127.0.0.1'
shared_preload_libraries = 'babelfishpg_tds'
lc_messages = 'C'
});
$node->start;

# Initialize Babelfish
my $tsql_node = new TDSNode($node);
$tsql_node->init_tsql('test_master', 'testdb');

# Create a login with password
$tsql_node->safe_tsql("master","CREATE LOGIN test_login WITH PASSWORD='12345678'");

my @connstr1 = $tsql_node->tsql_connstr_with_role('master', 'test_master', '');
$tsql_node->connect_ok('Test 1', (connstr => \@connstr1));

# Test password and md5 methods
reset_pg_hba($node, 'password');
my @connstr2 = $tsql_node->tsql_connstr_with_role('master', 'test_login', '12345678');
$tsql_node->connect_ok('Test 2', (connstr => \@connstr2));
reset_pg_hba($node, 'md5');
my @connstr3 = $tsql_node->tsql_connstr_with_role('master', 'test_login', '12345678');
$tsql_node->connect_ok('Test 3', (connstr => \@connstr3));

# Test invalid password
my @connstr4 = $tsql_node->tsql_connstr_with_role('master', 'test_login', '123');
$tsql_node->connect_fails('Test 4', (connstr => \@connstr4));

# Test reject method
reset_pg_hba($node, 'reject');
my @connstr5 = $tsql_node->tsql_connstr_with_role('master', 'test_login', '12345678');
$tsql_node->connect_fails('Test 5', (connstr => \@connstr5),
					   log_like =>
					   [qr/pg_hba.conf rejects connection for host "127.0.0.1", user "test_login", database "testdb"/]);

$node->stop;
