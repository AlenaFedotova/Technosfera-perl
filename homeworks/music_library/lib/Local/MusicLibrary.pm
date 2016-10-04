package Local::MusicLibrary;

use strict;
use warnings;
use Getopt::Long;
use DDP;

=encoding utf8

=head1 NAME

Local::MusicLibrary - core music library module

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub TakeArray ($$) {
	my $str = shift;
	my $ref = shift;
	substr $str, 0, 2, "";
	($ref->{band}, $str) = split (/\//, $str, 2);
	($ref->{year}, $str) = split (' - ', $str, 2);
	($ref->{album}, $str) = split (/\//, $str, 2);
	($ref->{track}, $str) = split (/\./, $str, 2);
	chop $str;
	$ref->{format} = $str; 
}

sub GetOpting ($$) {
	my $opt = shift;
	my $col = shift;
	$opt->{band} = "";
	$opt->{year} = "";
	$opt->{album} = "";
	$opt->{track} = "";
	$opt->{format} = "";
	$opt->{sort} = "";
	$opt->{columns} = -1;
	my $c = 0;

	Getopt::Long::GetOptions ($opt, "band=s", "year=i", "album=s", "track=s", "format=s", "sort=s", "columns:s");
	if ($opt->{columns} eq -1) {@$col = ('band', 'year', 'album', 'track', 'format')}
	elsif (!$opt->{columns}) {$col->[0] = -1}
	else {
		@$col = split ',', $opt->{columns};
		for (@$col) {if (!($_ =~ "(band|year|album|track|format)")) {die "Bad columns"}}
	}
}

sub GrepArray ($$) {
	my $ref = shift;
	my $opt = shift;

	if ($opt->{band}) {@$ref = grep {$_->{band} eq $opt->{band}} @$ref}
	if ($opt->{year} ne "") {@$ref = grep {$_->{year} == $opt->{year}} @$ref}
	if ($opt->{album}) {@$ref = grep {$_->{album} eq $opt->{album}} @$ref}
	if ($opt->{track}) {@$ref = grep {$_->{track} eq $opt->{track}} @$ref}
	if ($opt->{format}) {@$ref = grep {$_->{format} eq $opt->{format}} @$ref}
}

sub SortArray ($$) {
	my $ref = shift;
	my $sort = shift;

	if ($sort eq 'band' || $sort eq 'album' || $sort eq 'track') {@$ref = sort {$a->{$sort} cmp $b->{$sort}} @$ref}
	elsif ($sort eq 'year') {@$ref = sort {$a->{year}+0 <=> $b->{year}+0} @$ref}
	elsif ($sort eq 'format') {@$ref = sort {$a->{format} cmp $b->{format}} @$ref}
	elsif (!$sort) {}
	else {die "Bad sorting"}
}

sub Print ($$) {
	my $ref = shift;
	my $col = shift;

	if ($col->[0] ne -1 && $#$ref != -1) {
		my @col0 = ('band', 'year', 'album', 'track', 'format');
		my %max;
		my $sum = 0;
		my $sum0 = -1;
		
		for (@col0) {$max{$_} = 0}
		for (@$ref) {
			my $x = $_;
			for (@col0) {
				my $l = length $x->{$_};
				if ($l > $max{$_}) {$max{$_} = $l}
			}	
		}
	

		for (@$col) {$sum += $max{$_};$sum0 += 3}

		print '/', '-'x($sum + $sum0), "\\\n";
		for (my $i = 0; $i < $#$ref+1; $i++) {
			my $x = $ref->[$i];
			for (@$col) {
				print "|", " "x($max{$_} + 1 - length($x->{$_})), $x->{$_}, " ";
			}
			print "|\n";
			if ($i != $#$ref) {
				for (my $k=0; $k < $#$col+1; $k++) {
					if ($k == 0) {print "|", "-"x($max{$col->[$k]} + 2)}
					else {print "+", "-"x($max{$col->[$k]} + 2)}
					}
				print "|\n";
			}
		}
		print "\\", "-"x($sum + $sum0), "/\n";
	}
}

1;
