package Local::MusicLibrary::Taking;

use strict;
use warnings;
use Getopt::Long;


=encoding utf8

=head1 NAME

Local::MusicLibrary - core music library module

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

my @col0 = ("band", "year", "album", "track", "format");

sub TakeArray {
	my $str = shift;
	my $ref = shift;
	substr $str, 0, 2, "";
	my @s = ("\/", ' - ', "\/", '\.', "\n");
	for (my $i = 0; $i <= $#s; $i++) {($ref->{$col0[$i]}, $str) = split ($s[$i], $str, 2)}
}

sub TakeOptions {
	my $opt = shift;
	my $col = shift;
	for (@col0) {$opt->{$_} = ""}
	$opt->{sort} = "";
	$opt->{columns} = -1;

	Getopt::Long::GetOptions ($opt, "$col0[0]=s", "$col0[1]=s", "$col0[2]=s", "$col0[3]=s", "$col0[4]=s", "sort=s", "columns:s");
}

1;
