package Local::JSONParser;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw( parse_json );
our @EXPORT = qw( parse_json );

sub parse_json {
	my $source = shift;
	
	$source =~ s/^\s*([\"\[\{]?)(.*?)([\"\]\}]?)\s*$/$2/s;
	my $type = $1;
	my $err = $3;
	if ($type eq '"') {if ($err ne '"') {die "Bad quotes"} return parse_str($source)}
	elsif ($type eq '{') {if ($err ne '}') {die "Bad figure brackets"} $source =~ s/^\s*//; $source =~ s/\s*$//; return parse_obj($source)}
	elsif ($type eq '[') {if ($err ne ']') {die "Bad square brackets"} $source =~ s/^\s*//; $source =~ s/\s*$//; return parse_arr($source)}
	elsif ($type eq '') {$source =~ s/^\s*//; $source =~ s/\s*$//; return parse_num($source)}
}

sub parse_str {
	my $source = shift;
	if ($source =~ /^([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*$/) {
		$source =~ s/\\\\/\\/g;
		$source =~ s/\\"/"/g;
		$source =~ s/\\b/\b/g;
		$source =~ s/\\f/\f/g;
		$source =~ s/\\n/\n/g;
		$source =~ s/\\r/\r/g;
		$source =~ s/\\t/\t/g;
		$source =~ s/\\\//\//g;
		while ($source =~ /\\u([\da-f]{4})/) {
			my $tmp = hex($1+0);
			$tmp = chr($tmp);
			substr $source, index($source, '\u'), 6, $tmp;
		}
		return $source;
	}
	else {die "Bad string"}
}

sub parse_arr {
	my $source = shift;
	my @res;
	my $err;

	while ($source) {
		$err = $source;
		$source =~ s/^
		(
			\s*"([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*"\s* |
			\s*\[\s*(\s*(?1)\s*,\s*)*(?1)?\s*\]\s* |
			\s*\{(\s*"([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*"\s*\:\s*(?1)\s*,\s*)*
				(\s*"([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*"\s*\:\s*(?1)\s*)?\}\s* |
			\s*-?(0|[1-9]\d*)(\.\d+)?([eE][\+-]?\d+)?\s*
		)
		\s*,?\s*//x;
	my $tmp = $1;
	if ($source eq $err) {die "Bad array"}
		push @res, parse_json($tmp);
	}
	return [@res];
}

sub parse_obj {
	my $source = shift;
	my %res;
	my $err;

	while ($source) {
		$err = $source;
		$source =~ s/^ 
			\s*"(([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*)"\s*:\s*
		(
			\s*"([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*"\s* |
			\s*\[\s*(\s*(?3)\s*,\s*)*(?3)?\s*\]\s* |
			\s*\{(\s*"([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*"\s*\:\s*(?3)\s*,\s*)*
				(\s*"([^"\\]|\\["\\\/bfnrt]|\\u[\da-f]{4})*"\s*\:\s*(?3)\s*)?\}\s* |
			\s*-?(0|[1-9]\d*)(\.\d+)?([eE][\+-]?\d+)?\s*
		)
		\s*,?\s*//x;

	my $tmp = $3;
	my $key = parse_str($1);
	if ($source eq $err) {die "Bad hash"}
		$res{$key}=parse_json($tmp);
	}
	return {%res};
	
}

sub parse_num {
	my $source = shift;
	if ($source =~ /^-?(0|[1-9]\d*)(\.\d+)?([eE][\+-]?\d+)?$/) {return $source}
	else {die "Bad number"}
}

1;
