#!/usr/bin/perl
#----------------------------------------------------------------------
#
# gen_pltsql_node_support.pl
#    Generate PLtsql serialization/deserialization code for the extension.
#
# Stripped-down version of PostgreSQL's gen_node_support.pl.
# Only generates outfuncs and readfuncs for PLtsql node types.
# Does NOT generate nodetags.h, copyfuncs, equalfuncs, or queryjumblefuncs
# (the engine handles those).
#
# Input:  pltsql_serializable_1.h, pltsql_serializable_2.h
# Output: pltsql_outfuncs_gen.c, pltsql_readfuncs_gen.c
#
# Invoked by the extension Makefile during build.
#
#
# src/backend/nodes/gen_pltsql_node_support.pl
#
#----------------------------------------------------------------------

# Changes to gen_pltsql_node_support.pl (from the engine original):

# - Replaced use FindBin / use Catalog with inline RenameTempFile sub
# - @all_input_files — only pltsql_serializable_1.h and pltsql_serializable_2.h
# - @nodetag_only_files — empty (none of our files are nodetag-only)
# - $last_nodetag / $last_nodetag_no — set to undef (engine handles ABI check)
# - @extra_tags — empty (PG-specific)
# - $infile path stripping — uses basename() instead of s!.*src/include/!!
# - Added skips for #include, extern, // lines during parsing (serializable headers have these)
# - PLtsql enum types moved from @scalar_types to @enum_types (outfuncs needs WRITE_ENUM_FIELD)
# - Added PG enums FetchDirection, LockClauseStrength to @enum_types
# - Removed nodetags.h generation section
# - $node_includes — hardcoded to pltsql.h and pltsql-2.h
# - Removed copyfuncs/equalfuncs generation section
# - Renamed output files: outfuncs.funcs.c → pltsql_outfuncs_gen.c, etc.
# - Added fallback for unknown Capitalized* pointer types → WRITE_NODE_FIELD/READ_NODE_FIELD (handles PG node types like TypeName* without pre-seeding)
# - Removed queryjumblefuncs generation section
# - Catalog::RenameTempFile → RenameTempFile (our inline version)
# - Header comment references gen_pltsql_node_support.pl
# - All original arrays (@custom_copy_equal, @custom_query_jumble, %manual_nodetag_number, etc.) and their elsif branches kept intact


use strict;
use warnings FATAL => 'all';

use File::Basename;
use Getopt::Long;

# Inline replacement for Catalog::RenameTempFile (avoids engine dependency)
sub RenameTempFile
{
	my ($path, $tmpext) = @_;
	my $tmpfile = "$path$tmpext";
	rename($tmpfile, $path) or die "could not rename $tmpfile to $path: $!";
}

my $output_path = '.';

GetOptions('outdir:s' => \$output_path)
  or die "$0: wrong arguments";


# Test whether first argument is element of the list in the second
# argument
sub elem
{
	my $x = shift;
	return grep { $_ eq $x } @_;
}

# This list defines the canonical set of header files to be read by this
# script, and the order they are to be processed in.  We must have a stable
# processing order, else the NodeTag enum's order will vary, with catastrophic
# consequences for ABI stability across different builds.
#
# Currently, the various build systems also have copies of this list,
# so that they can do dependency checking properly.  In future we may be
# able to make this list the only copy.  For now, we just check that
# it matches the list of files passed on the command line.
#
# The two PLtsql serializable headers — order matters for struct processing.
my @all_input_files = qw(
  pltsql_serializable_1.h
  pltsql_serializable_2.h
);

# Nodes from these input files are automatically treated as nodetag_only.
# (empty for PLtsql — none of our files are nodetag-only-by-file, unlike in engine)
my @nodetag_only_files;

# ABI STABILITY CHECK:
#
# In stable branches, set $last_nodetag to the name of the last PLtsql node type
# that should receive an auto-generated nodetag number, and $last_nodetag_no
# to its number.  (Find these values in the last line of the current
# pltsql_nodetags.h file.)  The script will then complain if those values don't
# match reality, providing a cross-check that we haven't broken ABI by
# adding or removing nodetags.
# In HEAD, these variables should be left undef, since we don't promise
# ABI stability during development.

my $last_nodetag = 'PLtsql_stmt_restore_ctx_partial';
my $last_nodetag_no = 10079;

# output file names
my @output_files;

# collect node names
my @node_types = qw(Node);
# collect info for each node type
my %node_type_info;

# node types we don't want copy support for
my @no_copy;
# node types we don't want equal support for
my @no_equal;
# node types we don't want query jumble support for
my @no_query_jumble;
# node types we don't want read support for
my @no_read;
# node types we don't want read/write support for
my @no_read_write;
# node types that have handmade read/write support
my @special_read_write;
# node types we don't want any support functions for, just node tags
my @nodetag_only;

# types that are copied by straight assignment
my @scalar_types = qw(
  bits32 bool char double int int8 int16 int32 int64 long uint8 uint16 uint32 uint64
  AclMode AttrNumber Cardinality Cost Index Oid RelFileNumber Selectivity Size StrategyNumber SubTransactionId TimeLineID XLogRecPtr
);

# collect enum types
my @enum_types;

# collect types that are abstract (hence no node tag, no support functions)
my @abstract_types = qw(Node);

# Special cases that either don't have their own struct or the struct
# is not in a header file.  We generate node tags for them, but
# they otherwise don't participate in node support.
# (empty for PLtsql — these are PG-specific)

my @extra_tags;

# This is a regular node, but we skip parsing it from its header file
# since we won't use its internal structure here anyway.
push @node_types, qw(List);
# Lists are specially treated in all five support files, too.
# (Ideally we'd mark List as "special copy/equal" not "no copy/equal".
# But until there's other use-cases for that, just hot-wire the tests
# that would need to distinguish.)
push @no_copy, qw(List);
push @no_equal, qw(List);
push @no_query_jumble, qw(List);
push @special_read_write, qw(List);

# Nodes with custom copy/equal implementations are skipped from
# .funcs.c but need case statements in .switch.c.
my @custom_copy_equal;

# node types with custom read/write implementations
# (in pltsql_outfuncs_stubs.c / pltsql_readfuncs_stubs.c)
my @custom_read_write;

# Similarly for custom query jumble implementation.
my @custom_query_jumble;

# Track node types with manually assigned NodeTag numbers.
my %manual_nodetag_number;

# This is a struct, so we can copy it by assignment.  Equal support is
# currently not required.
push @scalar_types, qw(QualCost);

# PLtsql-specific enum types (defined in pltsql.h/pltsql-2.h).
# The engine discovers these by parsing typedef enum lines in headers;
# we must pre-declare them since we only parse PLtsql serializable headers.
push @enum_types, qw(
  PLtsql_stmt_type PLtsql_datum_type PLtsql_nsitem_type
  PLtsql_promise_type PLtsql_type_type PLtsql_dbcc_stmt_type
  PLtsql_exec_sp_type_code PLtsql_sp_type_code TransactionStmtKind
);

# PLtsql extension: PG enum types referenced by PLtsql struct fields.
push @enum_types, qw(FetchDirection LockClauseStrength);


## check that we have the expected number of files on the command line
die "wrong number of input files, expected:\n@all_input_files\ngot:\n@ARGV\n"
  if ($#ARGV != $#all_input_files);

## read input

my $next_input_file = 0;
foreach my $infile (@ARGV)
{
	my $in_struct;
	my $subline;
	my $is_node_struct;
	my $supertype;
	my $supertype_field;

	my $node_attrs = '';
	my $node_attrs_lineno;
	my @my_fields;
	my %my_field_types;
	my %my_field_attrs;

	# open file with name from command line, which may have a path prefix
	open my $ifh, '<', $infile or die "could not open \"$infile\": $!";

	# now shorten filename for use below
  # $infile =~ s!.*src/include/!!;
	# PLtsql extension: files aren't under src/include/, use basename
	$infile = basename($infile);

	# check it against next member of @all_input_files
	die "wrong input file ordering, expected @all_input_files\n"
	  if ($infile ne $all_input_files[$next_input_file]);
	$next_input_file++;

	my $raw_file_content = do { local $/; <$ifh> };

	# strip C comments, preserving newlines so we can count lines correctly
	my $file_content = '';
	while ($raw_file_content =~ m{^(.*?)(/\*.*?\*/)(.*)$}s)
	{
		$file_content .= $1;
		my $comment = $2;
		$raw_file_content = $3;
		$comment =~ tr/\n//cd;
		$file_content .= $comment;
	}
	$file_content .= $raw_file_content;

	my $lineno = 0;
	my $prevline = '';
	foreach my $line (split /\n/, $file_content)
	{
		# per-physical-line processing
		$lineno++;
		chomp $line;
		$line =~ s/\s*$//;
		next if $line eq '';
		next if $line =~ /^#(define|ifdef|endif)/;
		# PLtsql extension: serializable headers have #include, extern, and
		# C++ comment lines that PG node headers don't — skip them.
		next if $line =~ /^#include\b/;
		next if $line =~ /^extern\b/;
		next if $line =~ /^\/\//;

		# within a struct, don't process until we have whole logical line
		if ($in_struct && $subline > 0)
		{
			if ($line =~ /;$/)
			{
				# found the end, re-attach any previous line(s)
				$line = $prevline . $line;
				$prevline = '';
			}
			elsif ($prevline eq ''
				&& $line =~ /^\s*pg_node_attr\(([\w(), ]*)\)$/)
			{
				# special case: node-attributes line doesn't end with semi
			}
			else
			{
				# set it aside for a moment
				$prevline .= $line . ' ';
				next;
			}
		}

		# we are analyzing a struct definition
		if ($in_struct)
		{
			$subline++;

			# first line should have opening brace
			if ($subline == 1)
			{
				$is_node_struct = 0;
				$supertype = undef;
				next if $line eq '{';
				die "$infile:$lineno: expected opening brace\n";
			}
			# second line could be node attributes
			elsif ($subline == 2
				&& $line =~ /^\s*pg_node_attr\(([\w(), ]*)\)$/)
			{
				$node_attrs = $1;
				$node_attrs_lineno = $lineno;
				# hack: don't count the line
				$subline--;
				next;
			}
			# next line should have node tag or supertype
			elsif ($subline == 2)
			{
				if ($line =~ /^\s*NodeTag\s+type;/)
				{
					$is_node_struct = 1;
					next;
				}
				elsif ($line =~ /\s*(\w+)\s+(\w+);/ and elem $1, @node_types)
				{
					$is_node_struct = 1;
					$supertype = $1;
					$supertype_field = $2;
					next;
				}
			}

			# end of struct
			if ($line =~ /^\}\s*(?:\Q$in_struct\E\s*)?;$/)
			{
				if ($is_node_struct)
				{
					# This is the end of a node struct definition.
					# Save everything we have collected.

					foreach my $attr (split /,\s*/, $node_attrs)
					{
						if ($attr eq 'abstract')
						{
							push @abstract_types, $in_struct;
						}
						elsif ($attr eq 'custom_copy_equal')
						{
							push @custom_copy_equal, $in_struct;
						}
						elsif ($attr eq 'custom_read_write')
						{
							push @custom_read_write, $in_struct;
						}
						elsif ($attr eq 'custom_query_jumble')
						{
							push @custom_query_jumble, $in_struct;
						}
						elsif ($attr eq 'no_copy')
						{
							push @no_copy, $in_struct;
						}
						elsif ($attr eq 'no_equal')
						{
							push @no_equal, $in_struct;
						}
						elsif ($attr eq 'no_copy_equal')
						{
							push @no_copy, $in_struct;
							push @no_equal, $in_struct;
						}
						elsif ($attr eq 'no_query_jumble')
						{
							push @no_query_jumble, $in_struct;
						}
						elsif ($attr eq 'no_read')
						{
							push @no_read, $in_struct;
						}
						elsif ($attr eq 'nodetag_only')
						{
							push @nodetag_only, $in_struct;
						}
						elsif ($attr eq 'special_read_write')
						{
							push @special_read_write, $in_struct;
						}
						elsif ($attr =~ /^nodetag_number\((\d+)\)$/)
						{
							$manual_nodetag_number{$in_struct} = $1;
						}
						else
						{
							die
							  "$infile:$node_attrs_lineno: unrecognized attribute \"$attr\"\n";
						}
					}

					# node name
					push @node_types, $in_struct;

					# field names, types, attributes
					my @f = @my_fields;
					my %ft = %my_field_types;
					my %fa = %my_field_attrs;

					# If there is a supertype, add those fields, too.
					if ($supertype)
					{
						my @superfields;
						foreach
						  my $sf (@{ $node_type_info{$supertype}->{fields} })
						{
							my $fn = "${supertype_field}.$sf";
							push @superfields, $fn;
							$ft{$fn} =
							  $node_type_info{$supertype}->{field_types}{$sf};
							if ($node_type_info{$supertype}
								->{field_attrs}{$sf})
							{
								# Copy any attributes, adjusting array_size field references
								my @newa = @{ $node_type_info{$supertype}
									  ->{field_attrs}{$sf} };
								foreach my $a (@newa)
								{
									$a =~
									  s/array_size\((\w+)\)/array_size(${supertype_field}.$1)/;
								}
								$fa{$fn} = \@newa;
							}
						}
						unshift @f, @superfields;
					}
					# save in global info structure
					$node_type_info{$in_struct}->{fields} = \@f;
					$node_type_info{$in_struct}->{field_types} = \%ft;
					$node_type_info{$in_struct}->{field_attrs} = \%fa;

					# Propagate nodetag_only marking from files to nodes
					push @nodetag_only, $in_struct
					  if (elem $infile, @nodetag_only_files);

					# Propagate some node attributes from supertypes
					if ($supertype)
					{
						push @no_copy, $in_struct
						  if elem $supertype, @no_copy;
						push @no_equal, $in_struct
						  if elem $supertype, @no_equal;
						push @no_read, $in_struct
						  if elem $supertype, @no_read;
						push @no_query_jumble, $in_struct
						  if elem $supertype, @no_query_jumble;
					}
				}

				# start new cycle
				$in_struct = undef;
				$node_attrs = '';
				@my_fields = ();
				%my_field_types = ();
				%my_field_attrs = ();
			}
			# normal struct field
			elsif ($line =~
				/^\s*(.+)\s*\b(\w+)(\[[\w\s+]+\])?\s*(?:pg_node_attr\(([\w(), ]*)\))?;/
			  )
			{
				if ($is_node_struct)
				{
					my $type = $1;
					my $name = $2;
					my $array_size = $3;
					my $attrs = $4;

					# strip "const"
					$type =~ s/^const\s*//;
					# strip trailing space
					$type =~ s/\s*$//;
					# strip space between type and "*" (pointer) */
					$type =~ s/\s+\*$/*/;
					# strip space between type and "**" (array of pointers) */
					$type =~ s/\s+\*\*$/**/;

					die
					  "$infile:$lineno: cannot parse data type in \"$line\"\n"
					  if $type eq '';

					my @attrs;
					if ($attrs)
					{
						@attrs = split /,\s*/, $attrs;
						foreach my $attr (@attrs)
						{
							if (   $attr !~ /^array_size\(\w+\)$/
								&& $attr !~ /^copy_as\(\w+\)$/
								&& $attr !~ /^read_as\(\w+\)$/
								&& !elem $attr,
								qw(copy_as_scalar
								equal_as_scalar
								equal_ignore
								equal_ignore_if_zero
								query_jumble_ignore
								query_jumble_location
								read_write_ignore
								write_only_relids
								write_only_nondefault_pathtarget
								write_only_req_outer))
							{
								die
								  "$infile:$lineno: unrecognized attribute \"$attr\"\n";
							}
						}
					}

					$type = $type . $array_size if $array_size;
					push @my_fields, $name;
					$my_field_types{$name} = $type;
					$my_field_attrs{$name} = \@attrs;
				}
			}
			# function pointer field
			elsif ($line =~
				/^\s*([\w\s*]+)\s*\(\*(\w+)\)\s*\((.*)\)\s*(?:pg_node_attr\(([\w(), ]*)\))?;/
			  )
			{
				if ($is_node_struct)
				{
					my $type = $1;
					my $name = $2;
					my $args = $3;
					my $attrs = $4;

					my @attrs;
					if ($attrs)
					{
						@attrs = split /,\s*/, $attrs;
						foreach my $attr (@attrs)
						{
							if (   $attr !~ /^copy_as\(\w+\)$/
								&& $attr !~ /^read_as\(\w+\)$/
								&& !elem $attr,
								qw(equal_ignore read_write_ignore))
							{
								die
								  "$infile:$lineno: unrecognized attribute \"$attr\"\n";
							}
						}
					}

					push @my_fields, $name;
					$my_field_types{$name} = 'function pointer';
					$my_field_attrs{$name} = \@attrs;
				}
			}
			else
			{
				# We're not too picky about what's outside structs,
				# but we'd better understand everything inside.
				die "$infile:$lineno: could not parse \"$line\"\n";
			}
		}
		# not in a struct
		else
		{
			# start of a struct?
			if ($line =~ /^(?:typedef )?struct (\w+)$/ && $1 ne 'Node')
			{
				$in_struct = $1;
				$subline = 0;
			}
			# one node type typedef'ed directly from another
			elsif ($line =~ /^typedef (\w+) (\w+);$/ and elem $1, @node_types)
			{
				my $alias_of = $1;
				my $n = $2;

				# copy everything over
				push @node_types, $n;
				my @f = @{ $node_type_info{$alias_of}->{fields} };
				my %ft = %{ $node_type_info{$alias_of}->{field_types} };
				my %fa = %{ $node_type_info{$alias_of}->{field_attrs} };
				$node_type_info{$n}->{fields} = \@f;
				$node_type_info{$n}->{field_types} = \%ft;
				$node_type_info{$n}->{field_attrs} = \%fa;
			}
			# collect enum names
			elsif ($line =~ /^typedef enum (\w+)(\s*\/\*.*)?$/)
			{
				push @enum_types, $1;
			}
		}
	}

	if ($in_struct)
	{
		die "runaway \"$in_struct\" in file \"$infile\"\n";
	}

	close $ifh;
}    # for each file


## write output

my $tmpext = ".tmp$$";

# opening boilerplate for output files
my $header_comment =
  '/*-------------------------------------------------------------------------
 *
 * %s
 *    Generated node infrastructure code
 *
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * NOTES
 *  ******************************
 *  *** DO NOT EDIT THIS FILE! ***
 *  ******************************
 *
 *  It has been GENERATED by gen_pltsql_node_support.pl
 *
 *-------------------------------------------------------------------------
 */
';


# PLtsql extension: generate pltsql_nodetags.h with T_PLtsql_* defines.
# These are defined as macros (not enum members) starting at offset 1000
# to avoid collision with the engine's NodeTag enum (which ends at ~475).
# This allows the extension to define its own NodeTags without any engine changes.

my $pltsql_nodetag_start = 10000;

push @output_files, 'pltsql_nodetags.h';
open my $nth, '>', "$output_path/pltsql_nodetags.h$tmpext" or die $!;

printf $nth $header_comment, 'pltsql_nodetags.h';
print $nth "#ifndef PLTSQL_NODETAGS_H\n#define PLTSQL_NODETAGS_H\n\n";
print $nth "/* PLtsql NodeTag start offset — used by is_pltsql_node() checks */\n";
print $nth "#define PLTSQL_NODETAG_START $pltsql_nodetag_start\n\n";
print $nth "/*\n";
print $nth " * PLtsql NodeTag values, auto-generated by gen_pltsql_node_support.pl.\n";
print $nth " * Offset from $pltsql_nodetag_start to avoid collision with engine NodeTags.\n";
print $nth " */\n\n";

my $tagno = 0;
my $last_tag = undef;
foreach my $n (@node_types)
{
	next if $n eq 'Node';
	next if $n eq 'List';
	next if elem $n, @abstract_types;
	print $nth "#define T_${n} ((NodeTag) (PLTSQL_NODETAG_START + $tagno))\n";
	$last_tag = $n;
	$tagno++;
}

# ABI stability cross-check
if (defined $last_nodetag)
{
	my $expected_no = $pltsql_nodetag_start + $tagno - 1;  # last assigned absolute number
	if ($last_tag ne $last_nodetag)
	{
		die "ABI stability check failed: last PLtsql nodetag is T_${last_tag}, expected T_${last_nodetag}\n"
		  . "If you added or removed a node type, update \$last_nodetag and \$last_nodetag_no.\n";
	}
	if ($expected_no != $last_nodetag_no)
	{
		die "ABI stability check failed: T_${last_tag} = ${expected_no}, expected ${last_nodetag_no}\n"
		  . "If you added or removed a node type, update \$last_nodetag and \$last_nodetag_no.\n";
	}
}

print $nth "\n#endif /* PLTSQL_NODETAGS_H */\n";
close $nth;

# make #include lines necessary to pull in all the struct definitions
# PLtsql extension: hardcode includes for extension headers instead of
# auto-generating from input file paths.
# my $node_includes = qq{#include "src/pltsql.h"\n#include "src/pltsql-2.h"\n};
my $node_includes = qq{#include "pltsql_serialize_macros.h"\n};


# equalfuncs.c
# PLtsql extension: generate equalfuncs for parse tree validation 
# (comparing ANTLR-compiled tree vs deserialized tree when 
# `babelfish_tsql.validate_parse_cache` debug GUC is ON).
# No copyfuncs needed — serialize/deserialize serves as deep copy.

push @output_files, 'pltsql_equalfuncs_gen.c';
open my $eff, '>', "$output_path/pltsql_equalfuncs_gen.c$tmpext" or die $!;
push @output_files, 'pltsql_equalfuncs_switch.c';
open my $efs, '>', "$output_path/pltsql_equalfuncs_switch.c$tmpext" or die $!;

printf $eff $header_comment, 'pltsql_equalfuncs_gen.c';
printf $efs $header_comment, 'pltsql_equalfuncs_switch.c';

print $eff $node_includes;

foreach my $n (@node_types)
{
	next if elem $n, @abstract_types;
	next if elem $n, @nodetag_only;
	next if elem $n, @no_equal;

	print $efs "\t\tcase T_${n}:\n"
	  . "\t\t\tretval = _equal${n}(a, b);\n"
	  . "\t\t\tif (!retval)\n"
	  . "\t\t\t\telog(WARNING, \"pltsql_equal_node: mismatch in ${n}\");\n"
	  . "\t\t\tbreak;\n";

	next if elem $n, @custom_copy_equal;
	next if elem $n, @custom_read_write;
	next if elem $n, @special_read_write;

	print $eff "
static bool
_equal${n}(const $n *a, const $n *b)
{
";

	my %previous_fields;

	foreach my $f (@{ $node_type_info{$n}->{fields} })
	{
		my $t = $node_type_info{$n}->{field_types}{$f};
		my @a = @{ $node_type_info{$n}->{field_attrs}{$f} };
		my $equal_ignore = 0;

		my $array_size_field;
		my $equal_as_scalar = 0;
		foreach my $a (@a)
		{
			if ($a =~ /^array_size\(([\w.]+)\)$/)
			{
				$array_size_field = $1;
			}
			elsif ($a eq 'equal_as_scalar')
			{
				$equal_as_scalar = 1;
			}
			elsif ($a eq 'equal_ignore' || $a eq 'read_write_ignore')
			{
				$equal_ignore = 1;
			}
		}

		next if $equal_ignore;

		# Skip lineno — line numbers differ between cached (CREATE-time)
		# and ANTLR (EXEC-time) compilation due to source offset differences.
		next if $f eq 'lineno';

		# Skip varno/dno/itemno and named dno-reference fields — datum
		# numbering differs between validator (CREATE) and runtime (EXEC)
		# compilation contexts. Fields like curvar, cursor_handleno,
		# prepared_handleno, and return_code_dno store datum numbers under
		# different names but have the same dno-offset issue.
		next if $f eq 'dno';
		next if $f eq 'varno';
		next if $f eq 'itemno';
		next if $f eq 'retvarno';
		next if $f eq 'curvar';
		next if $f eq 'cursor_handleno';
		next if $f eq 'prepared_handleno';
		next if $f eq 'return_code_dno';

		if ($equal_as_scalar)
		{
			print $eff "\tCOMPARE_SCALAR_FIELD_LOG($f, \"$n\");\n";
			$previous_fields{$f} = 1;
			next;
		}

		if ($t eq 'char*')
		{
			print $eff "\tCOMPARE_STRING_FIELD_LOG($f, \"$n\");\n";
		}
		elsif ($t eq 'Bitmapset*' || $t eq 'Relids')
		{
			print $eff "\tCOMPARE_BITMAPSET_FIELD($f);\n";
		}
		elsif ($t eq 'ParseLoc')
		{
			print $eff "\tCOMPARE_LOCATION_FIELD($f);\n";
		}
		elsif (elem $t, @scalar_types or elem $t, @enum_types)
		{
			print $eff "\tCOMPARE_SCALAR_FIELD_LOG($f, \"$n\");\n";
		}
		elsif ($t =~ /^(\w+)\*$/ and elem $1, @scalar_types)
		{
			my $tt = $1;
			if (!defined $array_size_field)
			{
				die "no array size defined for $n.$f of type $t\n";
			}
			if ($node_type_info{$n}->{field_types}{$array_size_field} eq
				'List*')
			{
				print $eff
				  "\tCOMPARE_POINTER_FIELD($f, list_length(a->$array_size_field) * sizeof($tt));\n";
			}
			else
			{
				print $eff
				  "\tCOMPARE_POINTER_FIELD($f, a->$array_size_field * sizeof($tt));\n";
			}
		}
		elsif ($t eq 'function pointer')
		{
			print $eff "\tCOMPARE_SCALAR_FIELD_LOG($f, \"$n\");\n";
		}
		elsif (($t =~ /^(\w+)\*$/ or $t =~ /^struct\s+(\w+)\*$/)
			and elem $1, @node_types)
		{
			print $eff "\tCOMPARE_NODE_FIELD_LOG($f, \"$n\");\n";
		}
		elsif ($t =~ /^([A-Z]\w+)\*$/)
		{
			print $eff "\tCOMPARE_NODE_FIELD_LOG($f, \"$n\");\n";
		}
		elsif ($t =~ /^\w+\[\w+\]$/)
		{
			print $eff "\tCOMPARE_ARRAY_FIELD($f);\n";
		}
		elsif (($t =~ /^(\w+)\*\*$/ or $t =~ /^struct\s+(\w+)\*\*$/)
			and elem($1, @node_types))
		{
			print $eff "\t/* skip node array field $f */\n";
		}
		elsif ($t eq 'void*')
		{
			print $eff "\tCOMPARE_SCALAR_FIELD_LOG($f, \"$n\");\n";
		}
		else
		{
			die
			  "could not handle type \"$t\" in struct \"$n\" field \"$f\"\n";
		}

		$previous_fields{$f} = 1;
	}

	print $eff "
\treturn true;
}
";
}

close $eff;
close $efs;


# outfuncs.c, readfuncs.c
# PLtsql extension: rename output files to pltsql_* names

push @output_files, 'pltsql_outfuncs_gen.c';
open my $off, '>', "$output_path/pltsql_outfuncs_gen.c$tmpext" or die $!;
push @output_files, 'pltsql_readfuncs_gen.c';
open my $rff, '>', "$output_path/pltsql_readfuncs_gen.c$tmpext" or die $!;
push @output_files, 'pltsql_outfuncs_switch.c';
open my $ofs, '>', "$output_path/pltsql_outfuncs_switch.c$tmpext" or die $!;
push @output_files, 'pltsql_readfuncs_switch.c';
open my $rfs, '>', "$output_path/pltsql_readfuncs_switch.c$tmpext" or die $!;

printf $off $header_comment, 'pltsql_outfuncs_gen.c';
printf $rff $header_comment, 'pltsql_readfuncs_gen.c';
printf $ofs $header_comment, 'pltsql_outfuncs_switch.c';
printf $rfs $header_comment, 'pltsql_readfuncs_switch.c';

print $off $node_includes;
print $rff $node_includes;

foreach my $n (@node_types)
{
	next if elem $n, @abstract_types;
	next if elem $n, @nodetag_only;
	next if elem $n, @no_read_write;
	next if elem $n, @special_read_write;

	my $no_read = (elem $n, @no_read);

	# output format starts with upper case node type name
	my $N = uc $n;

	print $ofs "\t\t\tcase T_${n}:\n"
	  . "\t\t\t\t_out${n}(str, obj);\n"
	  . "\t\t\t\tbreak;\n";

	print $rfs "\tif (MATCH(\"$N\", "
	  . length($N) . "))\n"
	  . "\t\treturn (Node *) _read${n}();\n"
	  unless $no_read;

	next if elem $n, @custom_read_write;

	print $off "
static void
_out${n}(StringInfo str, const $n *node)
{
\tWRITE_NODE_TYPE(\"$N\");

";

	if (!$no_read)
	{
		my $macro =
		  (@{ $node_type_info{$n}->{fields} } > 0)
		  ? 'READ_LOCALS'
		  : 'READ_LOCALS_NO_FIELDS';
		print $rff "
static $n *
_read${n}(void)
{
\t$macro($n);

";
	}

	# track already-processed fields to support field order checks
	# (this isn't quite redundant with the previous loop, since
	# we may be considering structs that lack copy/equal support)
	my %previous_fields;

	# print instructions for each field
	foreach my $f (@{ $node_type_info{$n}->{fields} })
	{
		my $t = $node_type_info{$n}->{field_types}{$f};
		my @a = @{ $node_type_info{$n}->{field_attrs}{$f} };

		# extract per-field attributes
		my $array_size_field;
		my $read_as_field;
		my $read_write_ignore = 0;
		foreach my $a (@a)
		{
			if ($a =~ /^array_size\(([\w.]+)\)$/)
			{
				$array_size_field = $1;
				# insist that we read the array size first!
				die
				  "array size field $array_size_field for field $n.$f must precede $f\n"
				  if (!$previous_fields{$array_size_field} && !$no_read);
			}
			elsif ($a =~ /^read_as\(([\w.]+)\)$/)
			{
				$read_as_field = $1;
			}
			elsif ($a eq 'read_write_ignore')
			{
				$read_write_ignore = 1;
			}
		}

		if ($read_write_ignore)
		{
			# nothing to do if no_read
			next if $no_read;
			# for read_write_ignore with read_as(), emit the appropriate
			# assignment on the read side and move on.
			if (defined $read_as_field)
			{
				print $rff "\tlocal_node->$f = $read_as_field;\n";
				next;
			}
			# else, bad specification
			die "$n.$f must not be marked read_write_ignore\n";
		}

		# select instructions by field type
		if ($t eq 'bool')
		{
			print $off "\tWRITE_BOOL_FIELD($f);\n";
			print $rff "\tREAD_BOOL_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'ParseLoc')
		{
			print $off "\tWRITE_LOCATION_FIELD($f);\n";
			print $rff "\tREAD_LOCATION_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'int'
			|| $t eq 'int16'
			|| $t eq 'int32'
			|| $t eq 'AttrNumber'
			|| $t eq 'StrategyNumber')
		{
			print $off "\tWRITE_INT_FIELD($f);\n";
			print $rff "\tREAD_INT_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'uint32'
			|| $t eq 'bits32'
			|| $t eq 'BlockNumber'
			|| $t eq 'Index'
			|| $t eq 'SubTransactionId')
		{
			print $off "\tWRITE_UINT_FIELD($f);\n";
			print $rff "\tREAD_UINT_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'uint64'
			|| $t eq 'AclMode')
		{
			print $off "\tWRITE_UINT64_FIELD($f);\n";
			print $rff "\tREAD_UINT64_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'Oid' || $t eq 'RelFileNumber')
		{
			print $off "\tWRITE_OID_FIELD($f);\n";
			print $rff "\tREAD_OID_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'long')
		{
			print $off "\tWRITE_LONG_FIELD($f);\n";
			print $rff "\tREAD_LONG_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'char')
		{
			print $off "\tWRITE_CHAR_FIELD($f);\n";
			print $rff "\tREAD_CHAR_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'double')
		{
			print $off "\tWRITE_FLOAT_FIELD($f);\n";
			print $rff "\tREAD_FLOAT_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'Cardinality')
		{
			print $off "\tWRITE_FLOAT_FIELD($f);\n";
			print $rff "\tREAD_FLOAT_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'Cost')
		{
			print $off "\tWRITE_FLOAT_FIELD($f);\n";
			print $rff "\tREAD_FLOAT_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'QualCost')
		{
			print $off "\tWRITE_FLOAT_FIELD($f.startup);\n";
			print $off "\tWRITE_FLOAT_FIELD($f.per_tuple);\n";
			print $rff "\tREAD_FLOAT_FIELD($f.startup);\n" unless $no_read;
			print $rff "\tREAD_FLOAT_FIELD($f.per_tuple);\n" unless $no_read;
		}
		elsif ($t eq 'Selectivity')
		{
			print $off "\tWRITE_FLOAT_FIELD($f);\n";
			print $rff "\tREAD_FLOAT_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'char*')
		{
			print $off "\tWRITE_STRING_FIELD($f);\n";
			print $rff "\tREAD_STRING_FIELD($f);\n" unless $no_read;
		}
		elsif ($t eq 'Bitmapset*' || $t eq 'Relids')
		{
			print $off "\tWRITE_BITMAPSET_FIELD($f);\n";
			print $rff "\tREAD_BITMAPSET_FIELD($f);\n" unless $no_read;
		}
		elsif (elem $t, @enum_types)
		{
			print $off "\tWRITE_ENUM_FIELD($f, $t);\n";
			print $rff "\tREAD_ENUM_FIELD($f, $t);\n" unless $no_read;
		}
		# arrays of scalar types
		elsif ($t =~ /^(\w+)(\*|\[\w+\])$/ and elem $1, @scalar_types)
		{
			my $tt = uc $1;
			if (!defined $array_size_field)
			{
				die "no array size defined for $n.$f of type $t\n";
			}
			if ($node_type_info{$n}->{field_types}{$array_size_field} eq
				'List*')
			{
				print $off
				  "\tWRITE_${tt}_ARRAY($f, list_length(node->$array_size_field));\n";
				print $rff
				  "\tREAD_${tt}_ARRAY($f, list_length(local_node->$array_size_field));\n"
				  unless $no_read;
			}
			else
			{
				print $off
				  "\tWRITE_${tt}_ARRAY($f, node->$array_size_field);\n";
				print $rff
				  "\tREAD_${tt}_ARRAY($f, local_node->$array_size_field);\n"
				  unless $no_read;
			}
		}
		elsif ($t eq 'function pointer')
		{
			# We don't print these, and we can't read them either
			die "cannot read function pointer in struct \"$n\" field \"$f\"\n"
			  unless $no_read;
		}
		# Special treatments of several Path node fields
		elsif ($t eq 'RelOptInfo*' && elem 'write_only_relids', @a)
		{
			print $off
			  "\tappendStringInfoString(str, \" :parent_relids \");\n"
			  . "\toutBitmapset(str, node->$f->relids);\n";
		}
		elsif ($t eq 'PathTarget*' && elem 'write_only_nondefault_pathtarget',
			@a)
		{
			(my $f2 = $f) =~ s/pathtarget/parent/;
			print $off "\tif (node->$f != node->$f2->reltarget)\n"
			  . "\t\tWRITE_NODE_FIELD($f);\n";
		}
		elsif ($t eq 'ParamPathInfo*' && elem 'write_only_req_outer', @a)
		{
			print $off
			  "\tappendStringInfoString(str, \" :required_outer \");\n"
			  . "\tif (node->$f)\n"
			  . "\t\toutBitmapset(str, node->$f->ppi_req_outer);\n"
			  . "\telse\n"
			  . "\t\toutBitmapset(str, NULL);\n";
		}
		# node type
		elsif (($t =~ /^(\w+)\*$/ or $t =~ /^struct\s+(\w+)\*$/)
			and elem $1, @node_types)
		{
			die
			  "node type \"$1\" lacks write support, which is required for struct \"$n\" field \"$f\"\n"
			  if (elem $1, @no_read_write or elem $1, @nodetag_only);
			die
			  "node type \"$1\" lacks read support, which is required for struct \"$n\" field \"$f\"\n"
			  if (elem $1, @no_read or elem $1, @nodetag_only)
			  and !$no_read;

			print $off "\tWRITE_NODE_FIELD($f);\n";
			print $rff "\tREAD_NODE_FIELD($f);\n" unless $no_read;
		}
		# arrays of node pointers (currently supported for write only)
		elsif (($t =~ /^(\w+)\*\*$/ or $t =~ /^struct\s+(\w+)\*\*$/)
			and elem($1, @node_types))
		{
			if (!defined $array_size_field)
			{
				die "no array size defined for $n.$f of type $t\n";
			}
			if ($node_type_info{$n}->{field_types}{$array_size_field} eq
				'List*')
			{
				print $off
				  "\tWRITE_NODE_ARRAY($f, list_length(node->$array_size_field));\n";
				print $rff
				  "\tREAD_NODE_ARRAY($f, list_length(local_node->$array_size_field));\n"
				  unless $no_read;
			}
			else
			{
				print $off
				  "\tWRITE_NODE_ARRAY($f, node->$array_size_field);\n";
				print $rff
				  "\tREAD_NODE_ARRAY($f, local_node->$array_size_field);\n"
				  unless $no_read;
			}
		}
		elsif ($t eq 'struct CustomPathMethods*'
			|| $t eq 'struct CustomScanMethods*')
		{
			print $off q{
	/* CustomName is a key to lookup CustomScanMethods */
	appendStringInfoString(str, " :methods ");
	outToken(str, node->methods->CustomName);
};
			print $rff q!
	{
		/* Lookup CustomScanMethods by CustomName */
		char	   *custom_name;
		const CustomScanMethods *methods;
		token = pg_strtok(&length); /* skip methods: */
		token = pg_strtok(&length); /* CustomName */
		custom_name = nullable_string(token, length);
		methods = GetCustomScanMethods(custom_name, false);
		local_node->methods = methods;
	}
! unless $no_read;
		}
		elsif ($t eq 'void*' && ($f eq 'retdesc' || $f eq 'dest') && $n eq 'CallStmt')
		{
			# Babelfish-specific type override
			# do nothing
		}
		# PLtsql extension: pointer to a PG node type not in our input files
		# (e.g. TypeName*, Query*). Assume any Capitalized* pointer is a PG
		# node and emit WRITE_NODE_FIELD / READ_NODE_FIELD — the engine's
		# nodeToString/stringToNode already knows how to handle them.
		elsif ($t =~ /^([A-Z]\w+)\*$/)
		{
			print $off "\tWRITE_NODE_FIELD($f);\n";
			print $rff "\tREAD_NODE_FIELD($f);\n" unless $no_read;
		}
		else
		{
			die
			  "could not handle type \"$t\" in struct \"$n\" field \"$f\"\n";
		}

		# for read_as() without read_write_ignore, we have to read the value
		# that outfuncs.c wrote and then overwrite it.
		if (defined $read_as_field)
		{
			print $rff "\tlocal_node->$f = $read_as_field;\n" unless $no_read;
		}

		$previous_fields{$f} = 1;
	}

	print $off "}
";
	print $rff "
\tREAD_DONE();
}
" unless $no_read;
}

close $off;
close $rff;
close $ofs;
close $rfs;


# queryjumblefuncs.c
# PLtsql extension: we don't generate queryjumblefuncs
# (engine handles query jumble for PLtsql nodes via no_query_jumble attribute).


# now rename the temporary files to their final names
foreach my $file (@output_files)
{
	RenameTempFile("$output_path/$file", $tmpext);
}


# Automatically clean up any temp files if the script fails.
END
{
	# take care not to change the script's exit value
	my $exit_code = $?;

	if ($exit_code != 0)
	{
		foreach my $file (@output_files)
		{
			unlink("$output_path/$file$tmpext");
		}
	}

	$? = $exit_code;
}
