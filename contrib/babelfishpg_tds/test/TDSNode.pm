package TDSNode;
use strict;
use warnings;
use Exporter 'import';
use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use Test::More;
use Scalar::Util qw(blessed);

our @EXPORT = qw(
  init_tsql
  safe_tsql
);

#constructor
sub new {
	my $class = shift;

	my ($node, %params) = @_;

	my $self = {
		_node => $node,
		_tsql_port => 1433,
		_tsql_master_role => '',
		_tsql_master_db => ''
	};

	bless $self, $class;

	return $self;
}

sub tsql_port {
	my $self = shift;

	return $self->{_tsql_port};
}

sub tsql_master_role {
	my $self = shift;

	return $self->{_tsql_master_role};
}

sub tsql_master_db {
	my $self = shift;

	return $self->{_tsql_master_db};
}

sub init_tsql {
	my ($self, $role, $testdb) = @_;
	my $node = $self->{_node};

	if (!defined($role) or ($role eq ""))
	{
		die "cannot initialize babelfish, master role is empty";
	}

	if (!defined($testdb) or ($testdb eq ""))
	{
		die "cannot initialize babelfish, master database is empty";
	}

	$self->{_tsql_master_role} = $role;
	$self->{_tsql_master_db} = $testdb;

	$node->safe_psql('postgres', qq{CREATE USER $role WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '12345678' INHERIT});
	$node->safe_psql('postgres', qq{CREATE DATABASE $testdb OWNER $role});
	$node->safe_psql($testdb, qq{CREATE EXTENSION IF NOT EXISTS "babelfishpg_tds" CASCADE});
	$node->safe_psql($testdb, qq{GRANT ALL ON SCHEMA sys to $role});
	$node->safe_psql($testdb, qq{ALTER USER $role CREATEDB});
	$node->safe_psql($testdb, qq{ALTER SYSTEM SET babelfishpg_tsql.database_name = '$testdb'});
	$node->safe_psql($testdb, qq{SELECT pg_reload_conf()});
	$node->safe_psql($testdb, qq{CALL sys.initialize_babelfish('$role')});
}

sub tsql {
	my ($self, $dbname, $sql, %params) = @_;
	my $node = $self->{_node};

	my $stdout            = $params{stdout};
	my $stderr            = $params{stderr};
	my $timeout           = undef;
	my $timeout_exception = 'tsql timed out';

	my @connarray;
	if (defined $params{connstr})
	{
		@connarray = @{$params{connstr}};
	}
	else
	{
		my $role = $self->{_tsql_master_role};
		@connarray = $self->tsql_connstr_with_role($dbname, $role, '');
	}

	# Build connection string with database, query and warning level
	my @tsql_params = (
		$node->installed_command('sqlcmd'),
		'-Q', $sql,
		'-r1');

	# Now append reset of the options
	foreach(@connarray)
	{
		push @tsql_params, $_;
	}

	# If the caller wants an array and hasn't passed stdout/stderr
	# references, allocate temporary ones to capture them so we
	# can return them. Otherwise we won't redirect them at all.
	if (wantarray)
	{
		if (!defined($stdout))
		{
			my $temp_stdout = "";
			$stdout = \$temp_stdout;
		}
		if (!defined($stderr))
		{
			my $temp_stderr = "";
			$stderr = \$temp_stderr;
		}
	}

	$timeout =
	  IPC::Run::timeout($params{timeout}, exception => $timeout_exception)
	  if (defined($params{timeout}));

	${ $params{timed_out} } = 0 if defined $params{timed_out};

	# IPC::Run would otherwise append to existing contents:
	$$stdout = "" if ref($stdout);
	$$stderr = "" if ref($stderr);

	my $ret;

	do {
		local $@;
		eval {
			my @ipcrun_opts = (\@tsql_params);
			push @ipcrun_opts, '1>',  $stdout if defined $stdout;
			push @ipcrun_opts, '2>', $stderr if defined $stderr;
			push @ipcrun_opts, $timeout if defined $timeout;

			IPC::Run::run @ipcrun_opts;
			$ret = $?;
		};
		my $exc_save = $@;
		if ($exc_save)
		{

			# IPC::Run::run threw an exception. re-throw unless it's a
			# timeout, which we'll handle by testing is_expired
			die $exc_save
			  if (blessed($exc_save)
				|| $exc_save !~ /^\Q$timeout_exception\E/);

			$ret = undef;

			die "Got timeout exception '$exc_save' but timer not expired?!"
			  unless $timeout->is_expired;

			if (defined($params{timed_out}))
			{
				${ $params{timed_out} } = 1;
			}
			else
			{
				die "sqlcmd timed out: stderr: '$$stderr'\n"
				  . "while running '@tsql_params'";
			}
		}
	};

	if (defined $$stdout)
	{
		chomp $$stdout;
	}

	if (defined $$stderr)
	{
		chomp $$stderr;
	}

	# See http://perldoc.perl.org/perlvar.html#%24CHILD_ERROR
	# We don't use IPC::Run::Simple to limit dependencies.
	#
	# We always die on signal.
	my $core = $ret & 128 ? " (core dumped)" : "";
	die "sqlcmd exited with signal "
	  . ($ret & 127)
	  . "$core: '$$stderr' while running '@tsql_params'"
	  if $ret & 127;
	$ret = $ret >> 8;

	if ($ret && $params{on_error_die})
	{
		die "sqlcmd error: stderr: '$$stderr'\nwhile running '@tsql_params'"
		  if $ret == 1;
		die "connection error: '$$stderr'\nwhile running '@tsql_params'"
		  if $ret == 2;
		die
		  "error running SQL: '$$stderr'\nwhile running '@tsql_params' with sql '$sql'"
		  if $ret == 3;
		die "sqlcmd returns $ret: '$$stderr'\nwhile running '@tsql_params'";
	}

	if (wantarray)
	{
		return ($ret, $$stdout, $$stderr);
	}
	else
	{
		return $ret;
	}

}

sub safe_tsql {
	my ($node, $dbname, $sql, %params) = @_;

	my ($stdout, $stderr);

	my $ret = tsql(
		$node, $dbname, $sql,
		%params,
		stdout        => \$stdout,
		stderr        => \$stderr,
		on_error_die  => 1,
		on_error_stop => 1);

	# tsql can emit stderr from NOTICEs etc
	if ($stderr ne "")
	{
		print "#### Begin standard error\n";
		print $stderr;
		print "\n#### End standard error\n";
	}

	return $stdout;
}

# prepares a sqlcmd string with -S and -d option. It also appends extra options
# if provided.
sub tsql_connstr
{
	my ($self, $dbname, %params) = @_;

	my $node = $self->{_node};
	my @connarray;

	my $dbhost;
	if (!defined $params{dbhost})
	{
		$dbhost = '127.0.0.1,'.$self->{_tsql_port};
	}
	else
	{
		$dbhost = $params{dbhost};
	}
	push @connarray, '-S', $dbhost;

	# Escape properly the database string before using it, only
	# single quotes and backslashes need to be treated this way.
	$dbname =~ s#\\#\\\\#g;
	$dbname =~ s#\'#\\\'#g;
	push @connarray, '-d', $dbname;

	push @connarray, @{ $params{extra_params} }
	  if defined $params{extra_params};

	return @connarray;
}

# same as tsql_connstr but also appends a login id and password
sub tsql_connstr_with_role
{
	my ($self, $dbname, $dbrole, $dbpass, %params) = @_;

	my $node = $self->{_node};
	my @connarray = $self->tsql_connstr($dbname, %params);

	$dbrole =~ s#\\#\\\\#g;
	$dbrole =~ s#\'#\\\'#g;
	push @connarray, '-U', $dbrole;
	push @connarray, '-P', $dbpass;

	return @connarray;
}

sub connect_ok
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($self, $test_name, %params) = @_;
	my $node = $self->{_node};

	my @connstr;
	if (!defined($params{connstr}))
	{
		die "missing connection string";
	}
	else
	{
		@connstr = @{$params{connstr}};
	}

	my $sql;
	if (defined($params{sql}))
	{
		$sql = $params{sql};
	}
	else
	{
		$sql = "SELECT \"connected with @connstr\"";
	}

	my (@log_like, @log_unlike);
	if (defined($params{log_like}))
	{
		@log_like = @{ $params{log_like} };
	}
	if (defined($params{log_unlike}))
	{
		@log_unlike = @{ $params{log_unlike} };
	}

	my $log_location = -s $node->logfile();

	# Never prompt for a password, any callers of this routine should
	# have set up things properly, and this should not block.
	my ($ret, $stdout, $stderr) = $self->tsql(
		'master',
		$sql,
		connstr       => \@connstr,
		on_error_stop => 0);

	is($ret, 0, $test_name);

	if (defined($params{expected_stdout}))
	{
		like($stdout, $params{expected_stdout}, "$test_name: matches");
	}
	if (@log_like or @log_unlike)
	{
		my $log_contents = slurp_file($node->logfile(), $log_location);

		while (my $regex = shift @log_like)
		{
			like($log_contents, $regex, "$test_name: log matches");
		}
		while (my $regex = shift @log_unlike)
		{
			unlike($log_contents, $regex, "$test_name: log does not match");
		}
	}
}

sub connect_fails
{
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my ($self, $test_name, %params) = @_;
	my $node = $self->{_node};

	my @connstr;
	if (!defined($params{connstr}))
	{
		die "missing connection string";
	}
	else
	{
		@connstr = @{$params{connstr}};
	}

	my $sql;
	if (defined($params{sql}))
	{
		$sql = $params{sql};
	}
	else
	{
		$sql = "SELECT \"connected with @connstr\"";
	}

	my (@log_like, @log_unlike);
	if (defined($params{log_like}))
	{
		@log_like = @{ $params{log_like} };
	}
	if (defined($params{log_unlike}))
	{
		@log_unlike = @{ $params{log_unlike} };
	}

	my $log_location = -s $node->logfile();

	# Never prompt for a password, any callers of this routine should
	# have set up things properly, and this should not block.
	my ($ret, $stdout, $stderr) = $self->tsql(
		'master',
		$sql,
		connstr       => \@connstr,
		on_error_stop => 0);

	isnt($ret, 0, $test_name);

	if (defined($params{expected_stdout}))
	{
		like($stdout, $params{expected_stdout}, "$test_name: matches");
	}
	if (@log_like or @log_unlike)
	{
		my $log_contents = slurp_file($node->logfile(), $log_location);

		while (my $regex = shift @log_like)
		{
			like($log_contents, $regex, "$test_name: log matches");
		}
		while (my $regex = shift @log_unlike)
		{
			unlike($log_contents, $regex, "$test_name: log does not match");
		}
	}
}

1;
