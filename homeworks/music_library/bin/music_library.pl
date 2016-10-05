#!/usr/bin/env perl

use strict;
use warnings;
use Local::MusicLibrary::Taking;
use Local::MusicLibrary::Processing;
use Local::MusicLibrary::Printing;

my @col;
$#col = -1;
my %opt;
Local::MusicLibrary::Taking::TakeOptions(\%opt);

my @arr;
$#arr = -1;
while (<>) {
	my %h;
	Local::MusicLibrary::Taking::TakeArray $_, \%h;
	push @arr, {%h};
}
Local::MusicLibrary::Processing::Process \@arr, \%opt;
Local::MusicLibrary::Printing::Print \@arr, $opt{columns};
