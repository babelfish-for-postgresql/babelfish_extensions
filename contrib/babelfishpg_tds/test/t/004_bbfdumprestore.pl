# Set of tests for Babelfish dump/restore to test blocked options,
# including cross-version and cross-migration checks.
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use PostgreSQL::Test::Utils;
use PostgreSQL::Test::Cluster;
use Test::More;
use TDSNode;

# This test requires two clusters, an old one to dump and a new one in
# which we will restore. Below environment variable is required to be set:
# - "oldinstall", to point to the installation path of the old cluster.
if (!defined($ENV{oldinstall}))
{
	# oldinstall is not defined, so leave and die if test is
	# done with an older installation.
	die "oldinstall is undefined";
}

# Paths to the dumps taken during the tests.
my $tempdir    = PostgreSQL::Test::Utils::tempdir;
my $dump1_file = "$tempdir/dump_all_old.sql";
my $dump2_file = "$tempdir/dump_db_old.sql";
my $dump3_file = "$tempdir/dump_all_new.sql";
my $dump4_file = "$tempdir/dump_db_new.sql";

############################################################################################
############################### Test for cross version mode ################################
############################################################################################

# Initialize old node to dump
my $oldnode =
  PostgreSQL::Test::Cluster->new('old_node',
	install_path => $ENV{oldinstall});
$oldnode->init;
$oldnode->append_conf(
	'postgresql.conf', qq{
	log_connections = on
	listen_addresses='127.0.0.1'
	shared_preload_libraries = 'babelfishpg_tds'
	lc_messages = 'C'
});
$oldnode->start;
# Initialize Babelfish in old node
my $tsql_oldnode = new TDSNode($oldnode);
$tsql_oldnode->init_tsql('test_master', 'testdb');
$oldnode->stop;

# Initialize a new node for the restore.
my $newnode = PostgreSQL::Test::Cluster->new('new_node');
$newnode->init;
$newnode->append_conf(
	'postgresql.conf', qq{
	log_connections = on
	listen_addresses='127.0.0.1'
	shared_preload_libraries = 'babelfishpg_tds'
	lc_messages = 'C'
});
$newnode->start;
# Initialize Babelfish in new node
my $tsql_newnode = new TDSNode($newnode);
$tsql_newnode->init_tsql('test_master', 'testdb');
$newnode->stop;

# Dump global objects using pg_dumpall. Note that we
# need to use dump utilities from the new node here.
$oldnode->start;
my @dumpall_command = (
	'pg_dumpall', '--database', 'testdb', '--username', 'test_master',
	'--port', $oldnode->port, '--globals-only', '--quote-all-identifiers',
	'--verbose', '--no-role-passwords', '--file', $dump1_file);
$newnode->command_ok(\@dumpall_command, 'Dump global objects.');
# Dump Babelfish database using pg_dump.
my @dump_command = (
	'pg_dump', '--username', 'test_master', '--quote-all-identifiers',
	'--port', $oldnode->port, '--verbose', '--dbname', 'testdb',
	'--file', $dump2_file);
$newnode->command_ok(\@dump_command, 'Dump Babelfish database.');
$oldnode->stop;

# Retore the dumped files on the new server.
$newnode->start;

# Restore of dumpall file should cause a failure since cross version
# dump/restore is not yet supported.
$newnode->command_fails_like(
	[
		'psql',
		'-d',         'testdb',
		'-U',         'test_master',
		'-p',         $newnode->port,
		'-f',         $dump1_file,
	],
	qr/Dump and restore across different Postgres versions is not yet supported./,
	'Restore of global objects failed since source and target versions do not match.');

# Similarly, restore of dump file should also cause a failure.
$newnode->command_fails_like(
	[
		'psql',
		'-d',         'testdb',
		'-U',         'test_master',
		'-p',         $newnode->port,
		'-f',         $dump2_file,
	],
	qr/Dump and restore across different Postgres versions is not yet supported./,
	'Restore of Babelfish database failed since source and target versions do not match.');
$newnode->stop;

############################################################################################
############################## Test for cross migration mode ###############################
############################################################################################

# Initialize a node with the current version to dump.
my $newnode2 = PostgreSQL::Test::Cluster->new('new_node2');
$newnode2->init;
$newnode2->append_conf(
	'postgresql.conf', qq{
	log_connections = on
	listen_addresses='127.0.0.1'
	shared_preload_libraries = 'babelfishpg_tds'
	lc_messages = 'C'
});
$newnode2->start;
# Initialize Babelfish in new node
my $tsql_newnode2 = new TDSNode($newnode2);
$tsql_newnode2->init_tsql('test_master', 'testdb', 'multi-db');

# Dump global objects using pg_dumpall. Note that we
# need to use dump utilities from the new node here.
@dumpall_command = (
	'pg_dumpall', '--database', 'testdb', '--username', 'test_master',
	'--port', $newnode2->port, '--globals-only', '--quote-all-identifiers',
	'--verbose', '--no-role-passwords', '--file', $dump3_file);
$newnode2->command_ok(\@dumpall_command, 'Dump global objects.');
# Dump Babelfish database using pg_dump.
@dump_command = (
	'pg_dump', '--username', 'test_master', '--quote-all-identifiers',
	'--port', $newnode2->port, '--verbose', '--dbname', 'testdb',
	'--file', $dump4_file);
$newnode2->command_ok(\@dump_command, 'Dump Babelfish database.');
$newnode2->stop;

# Retore the dumped files on the new server.
$newnode->start;

# Restore of dumpall file should cause a failure since cross migration mode
# dump/restore is not yet supported.
$newnode->command_fails_like(
	[
		'psql',
		'-d',         'testdb',
		'-U',         'test_master',
		'-p',         $newnode->port,
		'-f',         $dump3_file,
	],
	qr/Dump and restore across different migration modes is not yet supported./,
	'Restore of global objects failed since source and target migration modes do not match.');

# Similarly, restore of dump file should also cause a failure.
$newnode->command_fails_like(
	[
		'psql',
		'-d',         'testdb',
		'-U',         'test_master',
		'-p',         $newnode->port,
		'-f',         $dump4_file,
	],
	qr/Dump and restore across different migration modes is not yet supported./,
	'Restore of Babelfish database failed since source and target migration modes do not match.');
$newnode->stop;
done_testing();
