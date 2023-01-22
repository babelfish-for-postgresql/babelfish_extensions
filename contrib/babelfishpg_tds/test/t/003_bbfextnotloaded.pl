# Copyright (c) 2021, Amazon Web Services, Inc. or its affiliates. All Rights Reserved

# Verify that we throw appropriate error in case
# Babelfish extensions are not installed

use strict;
use warnings;
use Test::More;
use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use TDSNode;

# Initialize primary node
my $node = PostgreSQL::Test::Cluster->new('primary');
$node->init;
$node->append_conf(
	'postgresql.conf', qq{
log_connections = on
listen_addresses='127.0.0.1'
shared_preload_libraries = 'babelfishpg_tds'
lc_messages = 'C'
babelfishpg_tsql.database_name = 'testdb'
});
$node->start;

# Create user and a babelfish data but don't create babelfish extensions
my $tsql_node = new TDSNode($node);
$node->safe_psql('postgres', qq{CREATE USER test_master WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '12345678' INHERIT});
$node->safe_psql('postgres', qq{CREATE DATABASE testdb OWNER test_master});

# Connection should fail with a FATAL error in log
my @connstr1 = $tsql_node->tsql_connstr_with_role('master', 'test_master', '12345678');
$tsql_node->connect_fails('Test 1', (connstr => \@connstr1),
					   log_like =>
					   [qr/babelfishpg_tsql extension is not installed/]);

$node->stop;

done_testing();
