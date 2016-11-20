#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Local::MusicLibrary::Processing;
use Local::MusicLibrary::Printing;

my @col0 = ("band", "year", "album", "track", "format");
my @sep = ("\/", ' - ', "\/", '\.', "\n");
my %is_num;
for (@col0) {$is_num{$_} = 0} $is_num{"year"} = 1;
my %opt;
my @col;
TakeOptions();

my @data;
while (<>) {
	my %h;
	Local::MusicLibrary::Processing::TakeArray $_, \%h, \@col0, \@sep;
	push @data, {%h};
}
Local::MusicLibrary::Processing::Process \&sort_compare, \&grep_compare, \@data, \%opt, \@col0, \@col, \%is_num;
Local::MusicLibrary::Printing::Print \@data, \@col;

sub TakeOptions {
	for (@col0) {$opt{$_} = ""}
	$opt{sort} = "";
	$opt{columns} = -1;

	Getopt::Long::GetOptions (\%opt, "$col0[0]=s", "$col0[1]=s", "$col0[2]=s", "$col0[3]=s", "$col0[4]=s", "sort=s", "columns:s");
}

sub sort_compare {
	my $a = shift;
	my $b = shift;
	my $sort = shift;
	if ($is_num{$sort}) {return $a->{$sort} <=> $b->{$sort}}
	else {return $a->{$sort} cmp $b->{$sort}}
}

sub grep_compare {
	my $x = shift;
	my $col = shift;
	if ($is_num{$col}) {return $x->{$col} == $opt{$col}}
	else {return $x->{$col} eq $opt{$col}}
}
