#!/usr/bin/perl
#
# Generate the error_mapping.h header from error_mapping.txt

use warnings;
use strict;

print "/* autogenerated from error_mapping.txt, do not edit */\n";

open my $error_map_details, '<', $ARGV[0] or die;

while (<$error_map_details>)
{
	chomp;

	# Skip comments
	next if /^#/;
	next if /^\s*$/;

	die unless /^([^\s]{5})\s+([^\s]+)\s(.*)(\sSQL_ERROR_)(\d{1,5})\s(\d{2})\s?(.*)?\s?/;

	(my $sqlstate, my $errcode_macro, my $error_msg, my $tsql_error_code, my $tsql_error_sev, my $error_msg_keywords) =
	  ($1, $2, $3, $5, $6, $7);

	next unless defined($error_msg);

	if ($error_msg_keywords eq "")
	{
		$error_msg_keywords="\"\"";
	}

	print "{\n\t\"$sqlstate\",$error_msg, $tsql_error_code, $tsql_error_sev, $error_msg_keywords\n},\n\n";
}

close $error_map_details;
